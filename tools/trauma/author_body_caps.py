"""Blender 4.3.2: source-boundary rest-pose caps; not animated soldier integration.
blender -b -P tools/trauma/author_body_caps.py -- OUTPUT NECK_ATLAS_DIRECTORY
"""
import bpy,bmesh,json,sys,math,shutil
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent))
import tissue_geometry as geo
root=Path(__file__).resolve().parents[2];out=Path(sys.argv[sys.argv.index('--')+1]).resolve();atlas=Path(sys.argv[sys.argv.index('--')+2]).resolve()
assert not out.is_relative_to(root);out.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root/'assets/characters/generated/standard_lod0.glb'))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');body=next(o for o in bpy.context.scene.objects if o.type=='MESH')
# Bone head landmarks span the twist-bone chain, rather than shortened parent tails.
profile_data=json.loads((root/'data/trauma/body_cut_profiles.json').read_text());profiles=profile_data['profiles']
mat=bpy.data.materials.new('Shared_Tissue_2K');mat.use_nodes=True
for name in ['tissue_albedo.png','tissue_normal.png','tissue_orm.png','tissue_flow.png']:shutil.copy(atlas/name,out/name)
im=bpy.data.images.load(str(out/'tissue_albedo.png'));tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=im;bs=mat.node_tree.nodes.get('Principled BSDF');mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);bs.inputs['Roughness'].default_value=.36
manifest={'schema':2,'variants':[],'sockets':[],'scope':'Nine cut families, canonical left rest-pose source boundaries; no live adapter','source':'MakeHuman standard_lod0.glb','regions':{}}
report={'meshes':[],'production_approved':False,'limits':['Canonical left contours only; right-side and body-shape fitting pending','No cloth/gear cuts or posed exterior joins','LOD2 reduction is not yet a single baked cap','Tier C cavity art pending','Shoulder/hip review planes are distal to joint centers to isolate limbs; glenoid/clavicle and pelvic-rim cuts are not delivered']}
for family,(start,end,fraction,muscles,bones) in profiles.items():
 a=rig.data.bones[start].head_local.copy();b=rig.data.bones.get(end)
 endpos=b.head_local.copy() if b else rig.data.bones[start].tail_local.copy()
 axis=(endpos-a).normalized();center=a.lerp(endpos,fraction)
 v=Vector((0,1,0));v=(v-axis*v.dot(axis)).normalized();u=v.cross(axis).normalized()
 bm=bmesh.new();bm.from_mesh(body.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=1e-6)
 bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=center,plane_no=axis,dist=1e-6,clear_outer=True)
 edges=[e for e in bm.edges if e.is_boundary and all(abs((p.co-center).dot(axis))<2e-5 for p in e.verts)]
 adjacency={}
 for e in edges:
  x,y=e.verts;adjacency.setdefault(x,[]).append(y);adjacency.setdefault(y,[]).append(x)
 loops=[];seen=set()
 for first in adjacency:
  if first in seen:continue
  ring=[];current=first;previous=None
  while current not in seen:
   seen.add(current);ring.append(current.co.copy());neighbors=[x for x in adjacency[current] if x!=previous]
   if not neighbors:break
   previous,current=current,neighbors[0]
  if len(ring)>=8:loops.append(ring)
 assert loops,f'No cut boundary for {family}'
 loops=[ring for ring in loops if max((p-q).length for p in ring for q in ring)>.025]
 assert loops,f'No substantial boundary for {family}'
 ring=min(loops,key=lambda ring:(sum(ring,Vector())/len(ring)-center).length)
 center=sum(ring,Vector())/len(ring);outline=[Vector(((p-center).dot(u),(p-center).dot(v))) for p in ring];bm.free()
 # Explicit orientation for CDT.
 area=sum(p.x*outline[(i+1)%len(outline)].y-outline[(i+1)%len(outline)].x*p.y for i,p in enumerate(outline))
 if area<0:outline.reverse()
 rx=max(abs(p.x) for p in outline);ry=max(abs(p.y) for p in outline)
 print('CUT_SIZE',family,rx,ry,flush=True)
 manifest['regions'][family]={'center_blender':list(center),'basis_blender':[list(u),list(v),list(axis)],'boundary_local':[list(p) for p in outline],'source_boundary_vertices':len(outline)}
 weapons=['melee','rifle','shotgun','explosive'] if family in ['upper_arm','thigh'] else ['shared']
 for weapon in weapons:
  for variant in range(3):
   seed=profile_data['seed']+list(profiles).index(family)*100+weapons.index(weapon)*9+variant
   relief=.6 if weapon=='melee' else 1.0;tear=.5 if weapon=='melee' else (1.3 if weapon in ['shotgun','explosive'] else 1)
   geo.configure(seed=seed,tear=tear,outline=outline,seam_z=[0]*len(outline),rx=rx,ry=ry,mat=mat)
   builder=geo.Builder();builder.patch(outline,-.009,.004,7,'connective_bed',spacing=max(rx,ry)*.30,rough=.001);builder.border()
   for x,y,sx,sy,label in muscles:
    builder.ellipse(x*rx,y*ry,sx*rx,sy*ry,(.008+.002*math.sin(seed+x))*relief,2,label,n=12,spacing=max(rx,ry)*.22,rough=.0015*tear,depth=.020)
   for x,y,sx,sy,label in bones:
    width=max(.001,min(rx*sx,ry*sy)*.25)
    builder.tube(x*rx,y*ry,rx*sx,ry*sy,.015*relief,width,4,label+'_cortex',n=14)
    builder.ellipse(x*rx,y*ry,rx*sx-width,ry*sy-width,.005,7,label+'_marrow',n=10,spacing=.008,rough=.0004,depth=.015)
   for x,y in [(.36,-.20),(.52,-.12)]:builder.tube(x*rx,y*ry,.003,.0035,.018*relief,.0008,2,'vascular_stub',n=10)
   if family in ['hand','foot','forearm']:
    for i in range(3):builder.ellipse((i-1)*rx*.30,-ry*.48,.002,ry*.16,.013,3,'tendon',n=8,spacing=.009,rough=.0003,depth=.02)
   if family=='waist':
    for i in range(3):builder.ellipse((i-1)*rx*.28,-ry*.12,rx*.17,ry*.24,-.003,2,'bounded_cavity_proxy',n=12,spacing=.02,rough=.001,depth=.012)
   ident=f'{family}_{weapon}_{variant}';obj=builder.mesh(ident+'_LOD0');st=geo.stats(obj)
   # Larger boundaries can exceed 4k before reduction. Preserve all source rim positions on LOD0.
   assert st['triangles']<=profile_data['lod_triangle_limits'][0],(ident,st)
   lods=[]
   for lod,target in enumerate(profile_data['lod_triangle_limits']):
    copy=obj if lod==0 else obj.copy()
    if lod:copy.data=obj.data.copy();bpy.context.collection.objects.link(copy);copy.name=ident+f'_LOD{lod}';mod=copy.modifiers.new('Reduction','DECIMATE');mod.ratio=target/st['triangles'];bpy.context.view_layer.objects.active=copy;bpy.ops.object.modifier_apply(modifier=mod.name)
    entry=geo.stats(copy)
    if lod==0:
     start_index=builder.parts[1]['first_vertex'];entry['boundary_match_error_m']=max((Vector(builder.v[start_index+i])-Vector((p.x,p.y,0))).length for i,p in enumerate(outline))
    entry.update(region=family,weapon=weapon,variant=variant,lod=lod);report['meshes'].append(entry)
    path=out/(copy.name+'.glb');geo.export(copy,path);lods.append(path.name);copy.hide_render=True
   manifest['variants'].append({'id':ident,'region':family,'weapon':weapon,'index':variant,'lods':lods,'parts':[p['name'] for p in builder.parts]})
 body.hide_render=True
 print('REGION_DONE',family,len(outline),flush=True)
report['unique_lod0']=len(manifest['variants']);report['checks']={'all_closed':all(m['non_manifold_edges']==0 for m in report['meshes']),'lod0_5000_budget':all(m['triangles']<=5000 for m in report['meshes'] if m['lod']==0),'lod1_800_budget':all(m['triangles']<=800 for m in report['meshes'] if m['lod']==1),'lod2_320_budget':all(m['triangles']<=320 for m in report['meshes'] if m['lod']==2)}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2));(out/'validation.json').write_text(json.dumps(report,indent=2))
(out/'authoring').mkdir(exist_ok=True);(out/'authoring/.gdignore').touch();bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(out/'authoring/body_caps.blend'),compress=True)
print('BODY_CAPS',json.dumps(report['checks']),flush=True)
