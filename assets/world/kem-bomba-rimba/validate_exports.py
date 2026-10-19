import bpy,json,hashlib
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parent
manifest=json.loads((root/'manifest.json').read_text())
rows=[]
for item in manifest['assets']:
 for filename in item['files']:
  path=root/'exports'/filename
  bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
  if path.suffix=='.glb':bpy.ops.import_scene.gltf(filepath=str(path))
  else:bpy.ops.import_scene.fbx(filepath=str(path))
  objs=[o for o in bpy.context.scene.objects if o.type=='MESH']
  coords=[o.matrix_world@Vector(c) for o in objs for c in o.bound_box]
  dims=[max(p[i] for p in coords)-min(p[i] for p in coords) for i in range(3)]
  triangles=sum(len(p.vertices)-2 for o in objs for p in o.data.polygons)
  assert triangles==item['triangles'],(filename,triangles,item['triangles'])
  assert max(abs(a-b) for a,b in zip(dims,item['dimensions']))<.01,(filename,dims,item['dimensions'])
  assert all(all(v==v for v in c) for c in coords)
  rows.append({'file':filename,'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'triangles':triangles,'reimport_dimensions':dims,'mesh_count':len(objs),'passed':True})
(root/'validation.json').write_text(json.dumps({'method':'Blender 5.2 reimport of every FBX and GLB; exact source triangle count, finite bounds, dimension tolerance 0.01 units','roblox_import_tested':False,'results':rows},indent=2))
print('VERIFIED_EXPORTS',len(rows))
