"""Private Makarov helmet conversion/baking, Blender 4.3+.
blender --background --disable-autoexec INPUT.blend --python THIS -- PRIVATE_OUTPUT
No input file is saved. Authored UVs drive baking into a separate review atlas.
"""
import bpy,sys,math,json,hashlib
from pathlib import Path
from mathutils import Matrix,Vector
repo=Path(__file__).resolve().parents[2]
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
assert not out.is_relative_to(repo), 'Purchased geometry must stay outside public checkout'
out.mkdir(parents=True,exist_ok=True)
source=Path(bpy.data.filepath);assert source.name=='Makarov (shaded soldier).blend'
cfg=json.loads((repo/'data/characters/helmet_conversion.json').read_text())
obj=bpy.data.objects['Helmet'];bpy.context.view_layer.update()
original=obj.data.copy();world=obj.evaluated_get(bpy.context.evaluated_depsgraph_get()).matrix_world.copy()
# Retain exactly the authored helmet geometry, applying only source unit/orientation conversion.
verts=[world@v.co for v in original.vertices]
center=Vector(tuple((min(v[i] for v in verts)+max(v[i] for v in verts))/2 for i in range(3)))
rotation=Matrix.Rotation(-math.pi/2,4,'Z')
for v,p in zip(original.vertices,verts):v.co=rotation@((p-center)*cfg['source_meters_per_unit'])
for other in list(bpy.data.objects):bpy.data.objects.remove(other,do_unlink=True)
obj=bpy.data.objects.new('MakarovHelmet',original);bpy.context.scene.collection.objects.link(obj)
bpy.context.view_layer.objects.active=obj;obj.select_set(True)
source_uv=obj.data.uv_layers.active;source_uv.name='SourceUV'
# Weld exact split render vertices on this rigid prop only; preserve per-loop source UVs.
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.remove_doubles(threshold=0.000001);bpy.ops.object.mode_set(mode='OBJECT')
obj.data.uv_layers.new(name='ReviewAtlasUV');obj.data.uv_layers.active_index=1
obj.data.uv_layers['ReviewAtlasUV'].active_render=True
# Original texture lookup is explicit so rebaking cannot accidentally sample new UVs.
materials=[]
for slot in obj.material_slots:
 mat=slot.material.copy();slot.material=mat;materials.append(mat)
 nodes=mat.node_tree.nodes;links=mat.node_tree.links
 uv=nodes.new('ShaderNodeUVMap');uv.uv_map='SourceUV'
 for node in list(nodes):
  if node.type=='TEX_IMAGE' and not node.inputs['Vector'].is_linked:links.new(uv.outputs['UV'],node.inputs['Vector'])
  if node.type=='NORMAL_MAP':node.uv_map='SourceUV'
 assert sum(n.type=='BSDF_PRINCIPLED' for n in nodes)==1
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=0.003,area_weight=0.5,correct_aspect=True,scale_to_bounds=True)
bpy.ops.object.mode_set(mode='OBJECT')
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=8
scene.render.bake.use_selected_to_active=False;scene.render.bake.margin=cfg['bake_margin_px']
scene.render.bake.normal_space='TANGENT';scene.render.bake.normal_r='POS_X';scene.render.bake.normal_g='POS_Y';scene.render.bake.normal_b='POS_Z'
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_depth='8'
size=cfg['atlas_size'];images={}
for channel in ['albedo','orm','normal']:
 image=bpy.data.images.new('helmet_'+channel,width=size,height=size,alpha=False)
 image.colorspace_settings.name='sRGB' if channel=='albedo' else 'Non-Color';images[channel]=image
 image.filepath_raw=str(out/('helmet_'+channel+'.png'));image.file_format='PNG'
 for mat in materials:
  nodes=mat.node_tree.nodes;links=mat.node_tree.links
  target=nodes.new('ShaderNodeTexImage');target.name='BakeTarget';target.image=image
  for n in nodes:n.select=False
  target.select=True;nodes.active=target
  output=next(n for n in nodes if n.type=='OUTPUT_MATERIAL' and n.is_active_output)
  bsdf=next(n for n in nodes if n.type=='BSDF_PRINCIPLED')
  if channel=='normal':links.new(bsdf.outputs['BSDF'],output.inputs['Surface'])
  else:
   emission=nodes.new('ShaderNodeEmission');links.new(emission.outputs[0],output.inputs['Surface'])
   if channel=='albedo':
    # Primary color texture, excluding the source's AO multiplication.
    color=nodes.get('Image Texture');assert color and color.type=='TEX_IMAGE' and color.image
    links.new(color.outputs['Color'],emission.inputs['Color'])
   else:
    pack=nodes.new('ShaderNodeCombineXYZ')
    ao=nodes.get('Color Ramp.001');assert ao
    links.new(ao.outputs['Color'],pack.inputs['X'])
    for socket,name in [('Y','Roughness'),('Z','Metallic')]:
     value=bsdf.inputs[name]
     if value.is_linked:links.new(value.links[0].from_socket,pack.inputs[socket])
     else:pack.inputs[socket].default_value=value.default_value
    links.new(pack.outputs[0],emission.inputs['Color'])
 bpy.ops.object.bake(type='NORMAL' if channel=='normal' else 'EMIT',uv_layer='ReviewAtlasUV')
 image.save();print('BAKED',channel,flush=True)
 # Remove bake targets after each channel to make active-image selection unambiguous.
 for mat in materials:
  mat.node_tree.nodes.remove(mat.node_tree.nodes['BakeTarget'])
# Replace five source shaders with one standard PBR atlas shader.
mat=bpy.data.materials.new('MakarovHelmet_ReviewAtlas');mat.use_nodes=True
nodes=mat.node_tree.nodes;links=mat.node_tree.links;bsdf=nodes.get('Principled BSDF')
for channel in ['albedo','orm','normal']:
 tex=nodes.new('ShaderNodeTexImage');tex.image=images[channel]
 if channel=='albedo':links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
 elif channel=='normal':
  normal=nodes.new('ShaderNodeNormalMap');normal.uv_map='ReviewAtlasUV';links.new(tex.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],bsdf.inputs['Normal'])
 else:
  separate=nodes.new('ShaderNodeSeparateColor');links.new(tex.outputs['Color'],separate.inputs[0]);links.new(separate.outputs['Green'],bsdf.inputs['Roughness']);links.new(separate.outputs['Blue'],bsdf.inputs['Metallic'])
  # Blender glTF exporter recognizes the named occlusion group socket.
  group=bpy.data.node_groups.new('glTF Material Output','ShaderNodeTree');group.interface.new_socket(name='Occlusion',in_out='INPUT',socket_type='NodeSocketFloat')
  node=nodes.new('ShaderNodeGroup');node.node_tree=group;links.new(separate.outputs['Red'],node.inputs['Occlusion'])
for attribute in list(obj.data.color_attributes): obj.data.color_attributes.remove(attribute)
obj.data.materials.clear();obj.data.materials.append(mat)
for poly in obj.data.polygons:poly.material_index=0
obj.data.uv_layers.remove(obj.data.uv_layers['SourceUV']);obj.data.uv_layers.active_index=0
base=obj.data.copy();lods=[]
for index,target in enumerate(cfg['lod_triangle_targets']):
 obj.data=base.copy();triangles=sum(len(p.vertices)-2 for p in obj.data.polygons)
 if target<triangles:
  mod=obj.modifiers.new('ReviewLOD','DECIMATE');mod.ratio=target/triangles;mod.use_collapse_triangulate=True
  bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=mod.name)
 triangles=sum(len(p.vertices)-2 for p in obj.data.polygons)
 path=out/f'helmet_lod{index}.glb'
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False,export_materials='EXPORT',export_normals=True,export_tangents=True)
 lods.append({'lod':index,'triangles':triangles,'materials':1,'bones':0,'path':path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
obj.data=base.copy()
# Drop unrelated packed source data and embedded scripts from the derived authoring file.
scene.world=bpy.data.worlds.new('ReviewWorld')
if scene.node_tree: scene.node_tree.nodes.clear()
for block in list(bpy.data.texts): bpy.data.texts.remove(block)
for collection in [bpy.data.images,bpy.data.materials,bpy.data.meshes,bpy.data.armatures,bpy.data.node_groups,bpy.data.actions]:
 for block in collection: block.use_fake_user=False
bpy.data.orphans_purge(do_recursive=True)
bpy.context.preferences.filepaths.save_version=0
authoring=out/'authoring';authoring.mkdir(exist_ok=True)
(authoring/'.gdignore').touch()
bpy.ops.wm.save_as_mainfile(filepath=str(authoring/'helmet_review.blend'))
report={'source':source.name,'source_object':'Helmet','source_materials':5,'source_triangles':9071,'unit_scale':cfg['source_meters_per_unit'],'orientation':'source +X faces glTF +Z, matching the shared review body','origin':'geometric bounds center; socket fitting is a separate review step','dimensions_blender_m':[max(v.co[i] for v in obj.data.vertices)-min(v.co[i] for v in obj.data.vertices) for i in range(3)],'atlas_size':size,'atlas_scope':'Helmet review only, not final all-role shared atlas','maps':{'albedo':'AO multiplication excluded','orm':'AO/Roughness/Metallic RGB from source node graph; source metallic not physically revalidated','normal':'OpenGL +Y tangent normal rebake'},'lods':lods,'production_ready':False,'blockers':['head socket fit and clearance review','final role atlas integration','LOD appearance review','provenance redistribution terms unverified']}
(out/'conversion.json').write_text(json.dumps(report,indent=2));print('CONVERSION_COMPLETE',json.dumps(lods),flush=True)
