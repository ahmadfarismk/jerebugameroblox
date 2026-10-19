import bpy, json, hashlib
from pathlib import Path
from mathutils import Matrix
root=Path(__file__).resolve().parent
validation=json.loads((root/'validation.json').read_text())
for row in validation['results']:
    p=root/'exports'/row['file']
    assert hashlib.sha256(p.read_bytes()).hexdigest()==row['sha256'], p
bpy.ops.wm.open_mainfile(filepath=str(root/'Kem_Bomba_Rimba.blend'))
manifest=json.loads((root/'manifest.json').read_text())
export=[]
placements={}
for entry in manifest['assets']:
    obj=bpy.data.objects[entry['name']]
    origin=obj.location.copy()
    placements[obj.name]=list(origin)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.separate(type='MATERIAL')
    bpy.ops.object.mode_set(mode='OBJECT')
    pieces=list(bpy.context.selected_objects)
    for piece in pieces:
        mat=piece.data.materials[0].name
        piece.name=entry['name']+'__'+mat
        export.append(piece)
bpy.ops.object.select_all(action='DESELECT')
for obj in export: obj.select_set(True)
bpy.context.view_layer.objects.active=export[0]
bpy.ops.export_scene.fbx(filepath=str(root/'Kem_Bomba_Rimba_Roblox.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=False,global_scale=0.01)
(root/'roblox-export.json').write_text(json.dumps({'parts':len(export),'placements_blender':placements,'source_hashes_verified':True},indent=2))
print('ROBLOX EXPORT',len(export))
