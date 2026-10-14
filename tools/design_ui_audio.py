"""Original procedural UI sound audition; design assets only, not wired into the app."""
import math, random, wave, json, array
from pathlib import Path
RATE = 48000
OUT = Path(__file__).resolve().parents[1] / 'docs/design/audio-v1'
OUT.mkdir(parents=True, exist_ok=True)

def tone(buf, start, dur, f0, f1=None, gain=.16, bright=.12):
    n = max(1, round(dur*RATE)); offset = round(start*RATE)
    for i in range(n):
        if offset+i >= len(buf): break
        t = i/RATE; u = i/n
        attack = min(1, t/.006)
        decay = math.exp(-5*u) * (1-u)**.55
        phase = 2*math.pi*(f0*t+((f1 if f1 else f0)-f0)*t*t/(2*dur))
        buf[offset+i] += gain*attack*decay*(math.sin(phase)+bright*math.sin(phase*2))

def air(buf, start, dur, gain=.01):
    rng=random.Random(184); previous=0
    for i in range(round(dur*RATE)):
        k=round(start*RATE)+i
        if k>=len(buf): break
        raw=rng.uniform(-1,1); previous=.82*previous+.18*raw
        env=math.sin(math.pi*i/(dur*RATE))**2
        buf[k]+=gain*previous*env

def make(duration, notes, texture=False):
    b=[0.0]*round(duration*RATE)
    for note in notes: tone(b,*note)
    if texture: air(b,0,min(duration,.14))
    # Rounded end and a strict ceiling prevent clicks/clipping in audition files.
    for i in range(min(240,len(b))): b[-i-1]*=i/240
    peak=max(abs(x) for x in b) or 1
    if peak>.28: b=[x*.28/peak for x in b]
    return b

specs=[
 ('01_tap','轻触',.08,[(0,.075,740,620,.11)],False),
 ('02_navigate','进入页面',.19,[(0,.14,520,680,.13),(.045,.14,880,1040,.065)],True),
 ('03_back','返回关闭',.16,[(0,.15,720,460,.12)],True),
 ('04_select','选择',.10,[(0,.09,880,920,.13)],False),
 ('05_toggle_on','开启或展开',.15,[(0,.08,590,None,.10),(.046,.09,790,None,.11)],False),
 ('06_toggle_off','关闭或收起',.15,[(0,.08,790,None,.10),(.046,.09,590,None,.10)],False),
 ('07_focus','进入近景',.21,[(0,.20,300,580,.12),(.06,.12,900,1050,.05)],True),
 ('08_swap','交换对象',.19,[(0,.10,620,830,.10),(.065,.12,830,620,.10)],False),
 ('09_adjust','缩放或时间刻度',.055,[(0,.045,1040,950,.075)],False),
 ('10_correct','回答正确',.36,[(0,.18,659,None,.12),(.075,.19,831,None,.11),(.15,.20,988,None,.095)],False),
 ('11_retry','温和重试',.23,[(0,.14,440,400,.10),(.075,.15,349,None,.08)],False),
 ('12_complete','首次完成',.57,[(0,.22,523,None,.10),(.10,.23,659,None,.10),(.20,.27,784,None,.10),(.30,.25,1047,None,.07)],False),
 ('13_reset','确认重置',.21,[(0,.12,620,520,.09),(.075,.12,415,None,.085)],False),
]
def write(path, audio):
    pcm=array.array('h',(int(max(-1,min(1,x))*32767) for x in audio))
    import sys
    if sys.byteorder!='little': pcm.byteswap()
    with wave.open(str(path),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(pcm.tobytes())

reel=[0.0]*round(.5*RATE); manifest=[]
for name,label,duration,notes,texture in specs:
    b=make(duration,notes,texture);write(OUT/(name+'.wav'),b)
    manifest.append({'id':name,'label':label,'file':name+'.wav','duration_ms':round(duration*1000),'audition_start_s':round(len(reel)/RATE,2),'peak_dbfs':round(20*math.log10(max(abs(x) for x in b)),1)})
    reel+=b+[0.0]*round(.7*RATE)+b+[0.0]*round(1.05*RATE)
write(OUT/'audition.wav',reel)
(OUT/'manifest.json').write_text(json.dumps({'sample_rate':RATE,'format':'PCM16 mono','status':'design audition; not integrated','cues':manifest},ensure_ascii=False,indent=2))
print(json.dumps({'files':len(specs),'audition_seconds':round(len(reel)/RATE,2),'max_peak_dbfs':max(x['peak_dbfs'] for x in manifest)},ensure_ascii=False))
