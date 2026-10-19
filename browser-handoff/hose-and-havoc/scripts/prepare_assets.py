from pathlib import Path
from PIL import Image
import json
root=Path(__file__).resolve().parents[1]
mapping=json.loads((root.parent/'assets/runtime-map.json').read_text())
out=root/'public/assets'
out.mkdir(parents=True,exist_ok=True)
for key,source in mapping.items():
    if key.startswith('title.'): continue
    im=Image.open(root.parent/source).convert('RGBA')
    im.thumbnail((512,512) if key.startswith('boss.') else (160,160),Image.Resampling.LANCZOS)
    im.save(out/(key+'.webp'),'WEBP',quality=85,method=6)
print('Runtime art:',sum(p.stat().st_size for p in out.glob('*')),'bytes')
