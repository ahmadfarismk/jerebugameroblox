"""Original Bahaya Jerebu modular environment kit; run with Blender --background --python."""
import bpy, math, json, os
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parent
OUT=ROOT/'exports'; OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
COLORS={'wood':'755343','dark':'343849','teal':'237B75','roof':'B84332','cream':'E9D6A3','yellow':'F4BA45','leaf':'37694D','lightleaf':'679454','water':'4BA6BA','stone':'707D80','mud':'554838'}
M={}
for name,h in COLORS.items():
 m=bpy.data.materials.new(name); m.diffuse_color=tuple(int(h[i:i+2],16)/255 for i in (0,2,4))+(1,); m.use_nodes=True; m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=m.diffuse_color; m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.8; M[name]=m
parts=[]; assets=[]
def finish(o,name,mat):
 o.name=name; o.data.materials.append(M[mat]); parts.append(o); return o
def box(name,loc,size,mat='wood',rot=(0,0,0)):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc,rotation=rot); o=bpy.context.object; o.scale=size; bpy.ops.object.transform_apply(location=False,rotation=False,scale=True); return finish(o,name,mat)
def cone(name,loc,r1,r2,depth,mat='wood',n=8):
 bpy.ops.mesh.primitive_cone_add(vertices=n,radius1=r1,radius2=r2,depth=depth,location=loc); return finish(bpy.context.object,name,mat)
def beam(a,b,width,mat='wood'):
 mid=(Vector(a)+Vector(b))/2; o=box('Brace',mid,(width,width,(Vector(b)-Vector(a)).length),mat); o.rotation_euler=(Vector(b)-Vector(a)).to_track_quat('Z','Y').to_euler(); return o
def roof(w,d,z):
 rise=d*.22; sl=math.sqrt((d/2)**2+rise**2); angle=math.atan2(rise,d/2)
 for s in [-1,1]: box('Roof',(0,s*d/4,z+rise/2),(w,sl,.35),'roof',(s*-angle,0,0))
 box('Ridge',(0,0,z+rise),(w+.2,.4,.45),'cream')
def platform(w,d,z):
 for x in [-w/2+.5,w/2-.5]:
  for y in [-d/2+.5,d/2-.5]: box('Post',(x,y,z/2),(.7,.7,z))
 box('Deck',(0,0,z),(w,d,.5),'wood')
def commit(name,xy):
 global parts
 bpy.ops.object.select_all(action='DESELECT')
 for o in parts:o.select_set(True)
 bpy.context.view_layer.objects.active=parts[0]; bpy.ops.object.join(); o=bpy.context.object; o.name=name
 bpy.context.scene.cursor.location=(0,0,0); bpy.ops.object.origin_set(type='ORIGIN_CURSOR'); o['units']='1 Blender unit = 1 intended Roblox stud; verify importer scale'; o['role']='decorative modular shell; add gameplay/collision in Studio'
 # Individual source exports retain ground-center origin.
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True)
 bpy.ops.export_scene.fbx(filepath=str(OUT/(name+'.fbx')),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=False,global_scale=1)
 tris=sum(len(p.vertices)-2 for p in o.data.polygons)
 assets.append({'name':name,'triangles':tris,'dimensions':[round(v,3) for v in o.dimensions],'materials':len(o.data.materials),'pivot':'ground center','files':[name+'.fbx',name+'.glb']})
 o.location=(xy[0],xy[1],0); parts=[]; return o
# 01: open command pavilion with elevated Malay-inspired gabled roof, generous entrances.
platform(24,18,1)
for x in [-10,10]:
 for y in [-7,7]:box('Column',(x,y,6),(.8,.8,10),'teal')
roof(27,21,11)
box('BriefingTable',(0,2,3.3),(9,4,.5),'teal')
for x in [-3,3]:box('TableLeg',(x,2,2.1),(.7,2.5,2))
box('MapPanel',(0,2,3.58),(7.7,3,.08),'cream')
for x in [-7,7]:box('Bench',(x,1,2),(2,8,.5),'yellow')
box('EntryStep',(0,-10,.35),(10,3,.7),'stone')
commit('01_CommandPavilion',(-30,10))
# 02: water supply landmark; roof deliberately unmistakable from observation tower.
for x in [-3.5,3.5]:
 for y in [-3.5,3.5]:box('TowerLeg',(x,y,7),(.7,.7,14),'teal')
for y in [-3.5,3.5]:beam((-3.5,y,2),(3.5,y,12),.45,'teal')
box('TankDeck',(0,0,14),(9,9,.7),'dark'); cone('WaterTank',(0,0,18),4,4,7,'water',12);cone('TankLid',(0,0,22),4.4,2.8,1,'cream',12)
box('Pipe',(4.5,0,8),(.6,.6,16),'yellow');box('Outlet',(5.5,0,1.8),(2,.7,.7),'yellow')
commit('02_WaterTower',(0,20))
# 03: reusable supply kiosk; UI signage belongs to Roblox SurfaceGui.
platform(12,9,.5)
for x in [-5,5]:
 for y in [-3.5,3.5]:box('Post',(x,y,4.5),(.6,.6,8),'teal')
roof(14,11,8.5);box('Counter',(0,-2,2.5),(10,2,4),'teal');box('CounterTop',(0,-2,4.65),(11,2.6,.35),'cream');box('SignBlank',(0,-3.8,7.1),(8,.3,1.8),'yellow')
for x in [-3,0,3]:box('SupplyCrate',(x,2,1.8),(2.4,2.4,2.5),'wood')
commit('03_SupplyKiosk',(22,14))
# 04: overnight rescue shelter.
platform(16,12,2)
for x in [-7,7]:
 for y in [-5,5]:box('Post',(x,y,5),(.7,.7,6),'wood')
roof(19,15,8.5);box('BackWall',(0,5.5,5),(15,.4,5),'teal')
for x in [-5,5]:box('Cot',(x,1,3.1),(3,7,.5),'cream')
for i in range(3):box('Step',(0,-7-i,1.5-i*.5),(6,1.3,.5),'wood')
commit('04_RescueShelter',(23,-9))
# 05,06: boardwalk and edge rail; exact 12-stud snap length.
for y in [-4,4]:box('Beam',(0,y,.65),(12,.6,.8),'dark')
for i in range(8):box('Plank',(-5.25+i*1.5,0,1.2),(1.4,10,.35),'wood')
commit('05_Boardwalk_12x10',(-8,-10))
for x in [-6,0,6]:box('RailPost',(x,0,2),(.5,.5,4),'wood')
for z in [1.6,3.7]:box('Rail',(0,0,z),(12,.35,.45),'cream')
commit('06_Railing_12',(-8,-20))
# 07: remote lookout; staircase is switchback and walkable width 4 studs.
platform(12,12,14)
for x in [-5,5]:
 for y in [-5,5]:box('LookoutPost',(x,y,18),(.7,.7,8),'teal')
roof(15,15,22)
for y in [-5.5,5.5]:box('Rail',(0,y,16),(12,.4,.5),'cream')
for x in [-5.5,5.5]:box('Rail',(x,0,16),(.4,11,.5),'cream')
for y in [-5,5]:beam((-5,y,1),(5,y,13),.5)
for i in range(14):box('Stair',(-9,-5+i*.8,.5+i*.5),(4,1,.5),'wood')
box('Landing',(-9,7,7),(4,3,.5),'wood')
for i in range(14):box('Stair',(-5,6-i*.8,7.5+i*.5),(4,1,.5),'wood')
commit('07_LookoutTower',(-32,-24))
# 08: chunky navigational post. Distinct color bands supplement shapes.
cone('Post',(0,0,4),.45,.35,8,'wood')
for z,w,mat in [(7,6,'yellow'),(5.7,5,'water'),(4.4,4,'cream')]:box('SignBlank',(0,0,z),(w,.4,1),mat)
commit('08_TrailSign',(9,-8))
# 09: tropical broadleaf, visible buttress roots; entirely low poly.
cone('Trunk',(0,0,8),1.8,.8,16,'wood',7)
for i in range(5):
 a=i*math.tau/5;beam((math.cos(a)*3,math.sin(a)*3,.2),(0,0,5),.7,'wood')
for x,y,z,r,mat in [(0,0,19,7,'leaf'),(-5,0,17,5,'lightleaf'),(4,3,18,5.3,'leaf'),(1,-4,16,4.5,'lightleaf')]:
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=r,location=(x,y,z));finish(bpy.context.object,'Crown',mat)
commit('09_ButtressTree',(47,23))
# 10: palm with broad geometric fronds.
cone('Trunk',(0,0,8),.8,.5,16,'wood',8)
for i in range(7):
 a=i*math.tau/7;beam((0,0,16),(math.cos(a)*8,math.sin(a)*8,13),1.4,'lightleaf')
commit('10_Palm',(45,-3))
# 11: burnt peat marker uses angular dead wood and low silhouette.
cone('Stump',(0,0,2),1.5,.9,4,'dark',7)
for a in [0,2,4]:beam((0,0,2),(math.cos(a)*3,math.sin(a)*3,5),.55,'dark')
for x,y,s in [(-2,0,2),(1,2,2.5),(1,-2,1.8)]:
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=s,location=(x,y,.3));o=finish(bpy.context.object,'PeatMound','mud');o.scale.z=.25
commit('11_PeatStump',(10,-24))
# 12: riverbank silhouette cluster.
for x,y,z,s in [(0,0,2,3),(-3,0,1,2),(2,2,.8,1.8)]:
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=s,location=(x,y,z));finish(bpy.context.object,'Boulder','stone')
commit('12_RiverRocks',(24,-27))
# Presentation ground and camera are excluded from modular exports.
box('PresentationGround',(8,0,-.7),(112,92,1),'leaf');parts=[]
world=bpy.context.scene.world;world.color=(.25,.25,.25)
bpy.ops.object.light_add(type='AREA',location=(-25,-30,65));bpy.context.object.data.energy=65000;bpy.context.object.data.shape='DISK';bpy.context.object.data.size=55
bpy.ops.object.camera_add(location=(100,-145,115));cam=bpy.context.object;cam.rotation_euler=(Vector((5,0,8))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=128;bpy.context.scene.camera=cam
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.render.resolution_x=1600;scene.render.resolution_y=1200;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.filepath=str(ROOT/'kit-preview.png')
scene.unit_settings.system='NONE'
for area in bpy.context.screen.areas:
 if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA'
(ROOT/'manifest.json').write_text(json.dumps({'title':'Kem Bomba Rimba','authoring':'Original procedural geometry authored for Bahaya Jerebu; no third-party asset inputs','units':'Intended 1 unit = 1 stud; confirm 12-unit boardwalk in importer','assets':assets,'triangle_total':sum(x['triangles'] for x in assets)},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'Kem_Bomba_Rimba.blend'))
bpy.ops.render.render(write_still=True)
print('KIT_COMPLETE',len(assets),sum(x['triangles'] for x in assets))
