"""Check package structure, launcher metadata and signature without installing it."""
import argparse
import hashlib
import json
import os
import re
from pathlib import Path
import subprocess
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument('apk', type=Path)
parser.add_argument('--sdk', type=Path, default=Path(os.environ.get('ANDROID_SDK_ROOT', str(Path.home() / 'Library/Android/sdk'))))
parser.add_argument('--java', default='java')
args = parser.parse_args()
build_tools = sorted((args.sdk / 'build-tools').iterdir(), key=lambda p: tuple(int(x) for x in p.name.split('.') if x.isdigit()))[-1]
metadata = subprocess.check_output([str(build_tools / 'aapt'), 'dump', 'badging', str(args.apk)], text=True)
manifest = subprocess.check_output([str(build_tools / 'aapt'), 'dump', 'xmltree', str(args.apk), 'AndroidManifest.xml'], text=True)
# Godot uses an activity-alias, which aapt badging omits from launchable-activity.
components = re.split(r'(?m)(?=^      E: )', manifest)
launchers = [block for block in components if re.match(r'      E: activity(?:-alias)? ', block)
            and '"android.intent.action.MAIN"' in block
            and '"android.intent.category.LAUNCHER"' in block]
assert any(re.search(r'android:exported[^\n]*0xffffffff', block) for block in launchers), 'Missing exported launcher component'
assert "versionName='0.21.0'" in metadata, 'Wrong version'
assert "versionCode='28'" in metadata, 'Wrong Android version code'
assert "native-code: 'arm64-v8a'" in metadata, 'Unexpected native ABI'
assert 'uses-permission:' not in metadata, 'Unexpected Android permission'
with zipfile.ZipFile(args.apk) as archive:
    assert archive.testzip() is None, 'Corrupt APK archive'
    entries = archive.namelist()
    assert 'assets/data/planets.json' in entries, 'Offline data missing'
    assert len(json.loads(archive.read('assets/data/planets.json'))['planets']) == 8
    assert len(json.loads(archive.read('assets/data/knowledge.json'))['planets']) == 8, 'Offline knowledge cards missing'
    assert not any(n.startswith(('assets/work/', 'assets/tests/', 'assets/tools/', 'assets/docs/')) for n in entries), 'Development files included'
    maps = ['earth.png', 'moon.jpg', 'clouds.jpg', 'mercury.jpg', 'venus_atmosphere.jpg', 'mars.jpg', 'jupiter.jpg', 'saturn.jpg', 'uranus.jpg', 'neptune.jpg']
    thumbnails = ['mercury', 'venus', 'earth', 'mars', 'jupiter', 'saturn', 'uranus', 'neptune']
    for resource in [f'textures/{name}' for name in maps] + [f'thumbnails/{name}.png' for name in thumbnails] + ['art/home-saturn-v2.png', 'ui/saturn-icon.png']:
        import_path = f'assets/assets/{resource}.import'
        assert import_path in entries, f'Missing texture import: {resource}'
        references = re.findall(r'"res://([^"\n]+\.ctex)"', archive.read(import_path).decode())
        assert references and all('assets/' + ref in entries for ref in references), f'Missing compiled texture: {resource}'
    audio_imports = [n for n in entries if n.startswith('assets/assets/audio/') and n.endswith('.wav.import')]
    assert len(audio_imports) == 13, 'Expected exactly 13 production sound assets'
    for import_path in audio_imports:
        references = re.findall(r'"res://([^"\n]+\.sample)"', archive.read(import_path).decode())
        assert references and all('assets/' + ref in entries for ref in references), f'Missing compiled audio: {import_path}'
    music_import = 'assets/assets/music/starlight-voyage-loop.wav.import'
    assert music_import in entries, 'Background music missing'
    references = re.findall(r'"res://([^"\n]+\.sample)"', archive.read(music_import).decode())
    assert references and all('assets/' + ref in entries for ref in references), 'Compiled background music missing'
    # Export strips import settings. Compare the packaged stream with the local
    # PCM resource exercised by the native playback/loop tests instead.
    compiled_music = Path(__file__).resolve().parents[1] / references[0]
    assert compiled_music.is_file(), 'Verified local music import missing'
    assert archive.read('assets/' + references[0]) == compiled_music.read_bytes(), 'Packaged music differs from verified PCM resource'
    assert compiled_music.stat().st_size >= 48000 * 60 * 2 * 2, 'Unexpected compressed music resource'
    assert not any('audition.wav' in n or 'starlight-voyage-preview' in n for n in entries), 'Audition material included in APK'
    for shader in ['seasons_earth.gdshader', 'seasons_sun.gdshader', 'year_sun.gdshader', 'home_planet.gdshader']:
        assert any(shader in name for name in entries), f'Missing seasons shader: {shader}'
    assert not any('approved-exploration'  in n for n in entries), 'Design reference included in APK'
subprocess.run([args.java, '-jar', str(build_tools / 'lib/apksigner.jar'), 'verify', str(args.apk)], check=True)
print(json.dumps({'status': 'PASS', 'apk': str(args.apk), 'bytes': args.apk.stat().st_size, 'sha256': hashlib.sha256(args.apk.read_bytes()).hexdigest(), 'checks': ['launcher', 'version', 'arm64', 'no permissions', 'offline catalog and eight knowledge cards', '10 surface maps and 8 thumbnails with compiled textures', 'excluded development files and concept art', 'seasons, year and home shaders', 'home hero compiled texture', 'ZIP integrity', 'signature', '13 compiled UI sounds and no audition reel', 'lossless background music loop']}, ensure_ascii=False, indent=2))
