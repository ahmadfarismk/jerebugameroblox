"""Copy original assets and assemble a self-contained browser design handoff."""
from pathlib import Path
import hashlib, json, shutil, struct, zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'browser-handoff'
ASSETS = OUT / 'assets'
SOURCE = ROOT / 'assets' / 'bahaya-jerebu'
WORLD = ROOT / 'assets' / 'world' / 'kem-bomba-rimba'

def copy(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)

for src in sorted(SOURCE.rglob('*.png')):
    copy(src, ASSETS / 'images' / src.relative_to(SOURCE))
for src in sorted((WORLD / 'exports').glob('*.glb')):
    copy(src, ASSETS / 'models' / src.name)
for src, name in [(SOURCE/'prompts.json', 'original-image-prompts.json'),
                  (SOURCE/'health'/'prompts.json', 'health-image-prompts.json'),
                  (WORLD/'manifest.json', 'camp-model-source-manifest.json'),
                  (WORLD/'kit-preview.png', 'camp-kit-preview.png')]:
    copy(src, ASSETS / 'reference' / name)

runtime = {
    'boss.rajaJerebu': 'assets/new/raja-jerebu.png',
    'hud.integrity': 'assets/images/health/60-health-heart.png',
    'hud.water': 'assets/images/hud/32-water-droplet.png',
    'hud.coins': 'assets/images/hud/31-currency-coin.png',
    'board.fire': 'assets/images/hud/33-fire-marker.png',
    'board.peat': 'assets/images/hud/34-peat-marker.png',
    'board.hydrant': 'assets/images/hud/35-hydrant-marker.png',
    'intent.wind': 'assets/images/hud/38-wind-arrow.png',
    'card.spray': 'assets/images/hoses/07-starter-hose.png',
    'card.burstJet': 'assets/images/hoses/08-brass-jet.png',
    'card.foamLine': 'assets/images/hoses/10-foam-cannon.png',
    'card.soak': 'assets/images/hud/34-peat-marker.png',
    'card.windTurn': 'assets/images/hud/38-wind-arrow.png',
    'card.rescue': 'assets/images/health/60-health-heart.png',
    'camp.waterTower': 'assets/images/upgrades/03-water-tank.png',
    'camp.fieldKitchen': 'assets/images/health/60-health-heart.png',
    'camp.rescueShelter': 'assets/images/gear/17-fire-helmet.png',
    'api.good': 'assets/images/api-faces/39-good.png',
    'api.moderate': 'assets/images/api-faces/40-moderate.png',
    'api.unhealthy': 'assets/images/api-faces/41-unhealthy.png',
    'api.veryUnhealthy': 'assets/images/api-faces/42-very-unhealthy.png',
    'api.hazardous': 'assets/images/api-faces/43-hazardous.png',
    'title.optionalBackground': 'assets/images/marketing/54-menu-background.png'
}
for path in runtime.values():
    assert (OUT/path).is_file(), path
(ASSETS/'runtime-map.json').write_text(json.dumps(runtime, indent=2), encoding='utf-8')
records = []
for path in sorted(ASSETS.rglob('*')):
    if not path.is_file() or path.name == 'asset-manifest.json':
        continue
    data = path.read_bytes()
    item = {'path': path.relative_to(OUT).as_posix(), 'bytes': len(data),
            'sha256': hashlib.sha256(data).hexdigest()}
    if path.suffix == '.png':
        assert data[:8] == b'\x89PNG\r\n\x1a\n', path
        item['width'], item['height'] = struct.unpack('>II', data[16:24])
        item['pngColorType'] = data[25]
        item['hasAlphaChannel'] = data[25] in (4, 6)
    if path.suffix == '.glb':
        magic, version, size = struct.unpack('<4sII', data[:12])
        assert magic == b'glTF' and version == 2 and size == len(data), path
    records.append(item)
manifest = {'title':'Bahaya Jerebu browser authoring handoff', 'date':'2026-10-19',
            'runtimeMap':'assets/runtime-map.json', 'files':records}
(ASSETS/'asset-manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')

# A compact local gallery; source files are untouched.
cards=[]
for item in records:
    if item['path'].endswith('.png'):
        p=item['path']
        cards.append(f'<figure><img loading="lazy" src="{p}" alt="{p}"><figcaption>{p}</figcaption></figure>')
(OUT/'asset-gallery.html').write_text('''<!doctype html><meta charset="utf-8"><title>Bahaya Jerebu assets</title>
<style>body{font:15px system-ui;background:#20152f;color:#fff;margin:24px}main{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:16px}figure{margin:0;background:#392849;border-radius:16px;padding:12px}img{width:100%;height:180px;object-fit:contain;background:#eee;border-radius:10px}figcaption{overflow-wrap:anywhere;padding-top:8px}</style>
<h1>Bahaya Jerebu — browser asset handoff</h1><p>Original authoring images. See ASSET-NOTES.txt before implementation.</p><main>'''+''.join(cards)+'</main>', encoding='utf-8')
archive=ROOT/'Bahaya-Jerebu-Browser-Handoff.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for p in sorted(OUT.rglob('*')):
        if p.is_file(): z.write(p, p.relative_to(ROOT).as_posix())
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
print(json.dumps({'archive':str(archive),'bytes':archive.stat().st_size,
                  'pngs':sum(x['path'].endswith('.png') for x in records),
                  'glbs':sum(x['path'].endswith('.glb') for x in records),
                  'runtimePathsVerified':len(runtime),'zipIntegrity':'pass'}))
