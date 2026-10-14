"""Original ambient music study for Solar System Explorer; not runtime assets.
Requires numpy. All instruments are synthesized; no samples or external recordings.
Circular overlap-add and circular delay preserve the 60-second loop seam.
"""
from pathlib import Path
import json, wave
import numpy as np

RATE = 48000
SECONDS = 60
N = RATE * SECONDS
OUT = Path(__file__).resolve().parents[1] / 'docs/design/music-v1'
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(14026)
mix = np.zeros((N, 2), dtype=np.float64)
BEAT = 60 / 64

def hz(midi): return 440 * 2 ** ((midi - 69) / 12)

def add(audio, start):
    index = int(round(start * RATE)) % N
    length = len(audio)
    first = min(length, N - index)
    mix[index:index + first] += audio[:first]
    if first < length: mix[:length-first] += audio[first:]

def pad(start, midi, pan, gain=0.033, duration=21):
    t = np.arange(round(duration * RATE)) / RATE
    # Complementary three-second transitions between harmonic regions.
    env = np.ones_like(t)
    edge = 3.0
    a = t < edge
    z = t > duration-edge
    env[a] = np.sin(np.pi * t[a] / (2*edge)) ** 2
    env[z] = np.sin(np.pi * (duration-t[z]) / (2*edge)) ** 2
    env *= 0.9 + 0.1 * np.cos(2*np.pi*t/duration)
    f = hz(midi)
    phase = rng.uniform(0, 2*np.pi)
    left = np.zeros_like(t)
    right = np.zeros_like(t)
    for harmonic, weight in [(1,1), (2,.15), (3,.042), (4,.012)]:
        left += weight*np.sin(2*np.pi*f*harmonic*.9991*t+phase+0.1*np.sin(2*np.pi*.13*t))
        right += weight*np.sin(2*np.pi*f*harmonic*1.0009*t+phase+0.1*np.sin(2*np.pi*.11*t+.7))
    balance = (pan+1)*np.pi/4
    add(np.column_stack((left*np.cos(balance), right*np.sin(balance)))*env[:,None]*gain,start)

def glass(start, midi, pan, gain=.018, length=6.2):
    t = np.arange(round(length * RATE)) / RATE
    f = hz(midi)
    # Soft attack and restrained overtones, deliberately below UI-cue prominence.
    env = (1-np.exp(-t/.11))**2*np.exp(-t/1.35)
    env *= np.minimum(1, (length-t)/.8)**2
    voice = np.sin(2*np.pi*f*t) + .12*np.sin(2*np.pi*2*f*t)*np.exp(-t/.6)
    voice += .025*np.sin(2*np.pi*3*f*t)*np.exp(-t/.25)
    balance = (pan+1)*np.pi/4
    add(np.column_stack((voice*np.cos(balance),voice*np.sin(balance)))*env[:,None]*gain,start)

# Four spacious four-bar phrases: Cmaj9 / Am9 / Fmaj9 / Gsus2(add6).
# Each chord overlaps the next by six seconds; the final tail wraps to the beginning.
chords = [[48,55,59,62,64],[45,52,55,59,60],[41,53,57,60,64],[43,50,55,57,62]]
for i, chord in enumerate(chords):
    for j, midi in enumerate(chord):
        pad(i*15-3,midi,[-.35,.3,-.16,.45,-.45][j],.034 if j<2 else .022)

# An unhurried, pentatonic motif with deliberate gaps for reading and interaction.
phrases = [
    [(2,72),(6.5,79),(10,76),(13,74)],
    [(3,72),(7.5,76),(11.5,69)],
    [(2.5,72),(6,76),(10.5,79),(14,76)],
    [(3,74),(8,69),(12,67)],
]
for phrase, notes in enumerate(phrases):
    for k,(beat,midi) in enumerate(notes):
        glass(phrase*15+beat*BEAT,midi,(-.42 if k%2==0 else .42),.019 if k==0 else .014)

# Very sparse upper shimmer, without a persistent rhythmic click or bright hiss.
glass(9.3,84,.55,.004,8)
glass(39.4,83,-.55,.0035,8)

# Diffuse stereo echoes. Circular processing carries the reverb tail across the seam.
dry = mix.copy()
for seconds, gain, swap in [(.37,.12,True),(.79,.10,False),(1.31,.075,True),(2.07,.055,False),(3.11,.035,True)]:
    echo = np.roll(dry,round(seconds*RATE),axis=0)
    mix += gain*(echo[:,::-1] if swap else echo)
# Gentle crossfeed keeps a stable center on tablet speakers and in mono.
mix = .78*mix + .22*mix[:,::-1]
mix -= mix.mean(axis=0)
# Quiet listening master: target RMS -30 dBFS, peak ceiling -15 dBFS.
rms = float(np.sqrt(np.mean(mix**2)))
gain = min(10**(-30/20)/rms, 10**(-15/20)/float(np.max(np.abs(mix))))
mix *= gain

def write(path, samples):
    pcm = np.rint(np.clip(samples,-1,1)*32767).astype('<i2')
    with wave.open(str(path),'wb') as stream:
        stream.setnchannels(2); stream.setsampwidth(2); stream.setframerate(RATE)
        stream.writeframes(pcm.tobytes())
    return pcm

pcm = write(OUT/'starlight-voyage-loop.wav',mix)
preview = mix.copy()
fadein = round(.7*RATE); fadeout = round(1.5*RATE)
preview[:fadein] *= np.sin(np.linspace(0,np.pi/2,fadein))[:,None]**2
preview[-fadeout:] *= np.cos(np.linspace(0,np.pi/2,fadeout))[:,None]**2
write(OUT/'starlight-voyage-preview.wav',preview)

step = np.diff(pcm.astype(np.int32),axis=0)
seam = np.abs(pcm[0].astype(np.int32)-pcm[-1].astype(np.int32))
report = {
    'title':'星海慢航 / Starlight Voyage', 'status':'design audition; not integrated',
    'original_procedural_synthesis':True, 'seconds':SECONDS, 'sample_rate':RATE,
    'channels':2, 'format':'PCM16', 'tempo_reference_bpm':64,
    'peak_dbfs':round(20*np.log10(np.max(np.abs(mix))),2),
    'rms_dbfs':round(20*np.log10(np.sqrt(np.mean(mix**2))),2),
    'clipped_samples':int(np.count_nonzero(np.abs(pcm.astype(np.int32))>=32767)),
    'loop_seam_step_pcm16':seam.tolist(),
    'max_adjacent_step_pcm16':np.max(np.abs(step),axis=0).tolist(),
    'stereo_correlation':round(float(np.corrcoef(mix.T)[0,1]),3),
    'mono_rms_change_db':round(float(20*np.log10(np.sqrt(np.mean(mix.mean(axis=1)**2))/np.sqrt(np.mean(mix**2)))),2),
    'files':{'loop':'starlight-voyage-loop.wav','audition':'starlight-voyage-preview.wav'},
    'device_audition':'pending; sample metrics do not measure perceived loudness or device output',
}
assert np.isfinite(mix).all()
assert report['clipped_samples']==0
assert max(report['loop_seam_step_pcm16']) < 20
assert max(report['loop_seam_step_pcm16']) <= max(report['max_adjacent_step_pcm16'])
(OUT/'VALIDATION.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report,ensure_ascii=False,indent=2))
