"""Shared Blender 4.x baking for the inspected Makarov/Soup source material graphs.
Rejects unsupported graph layouts instead of silently inventing channels.
"""
import bpy, math
from mathutils import Vector

def bake(obj, out, cfg, prefix):
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
 # Keep authored garment island shapes instead of making hundreds of normal-angle
 # islands. Offset source-material domains to separate shared UV coordinates,
 # equalize physical density, then pack without overlapping islands.
 bpy.ops.object.mode_set(mode='OBJECT')
 source_layer=obj.data.uv_layers['SourceUV'];atlas_layer=obj.data.uv_layers['ReviewAtlasUV']
 for poly in obj.data.polygons:
  for loop in poly.loop_indices:atlas_layer.data[loop].uv=source_layer.data[loop].uv+Vector((poly.material_index*2.0,0))
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.select_all(action='SELECT')
 bpy.ops.uv.average_islands_scale()
 bpy.ops.uv.pack_islands(rotate=True,margin=cfg.get('uv_padding_px',16)/cfg['atlas_size'],margin_method='FRACTION')
 bpy.ops.object.mode_set(mode='OBJECT')
 scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=8
 scene.render.bake.use_selected_to_active=False;scene.render.bake.margin=cfg['bake_margin_px']
 scene.render.bake.normal_space='TANGENT';scene.render.bake.normal_r='POS_X';scene.render.bake.normal_g='POS_Y';scene.render.bake.normal_b='POS_Z'
 scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_depth='8'
 size=cfg['atlas_size'];images={}
 for channel in ['albedo','orm','normal']:
  image=bpy.data.images.new(prefix+'_'+channel,width=size,height=size,alpha=False)
  image.colorspace_settings.name='sRGB' if channel=='albedo' else 'Non-Color';images[channel]=image
  image.filepath_raw=str(out/(prefix+'_'+channel+'.png'));image.file_format='PNG'
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
      if name=='Metallic' and cfg.get('force_metallic_zero',False):
       pack.inputs[socket].default_value=0.0
       continue
      if value.is_linked:links.new(value.links[0].from_socket,pack.inputs[socket])
      else:pack.inputs[socket].default_value=value.default_value
     links.new(pack.outputs[0],emission.inputs['Color'])
  bpy.ops.object.bake(type='NORMAL' if channel=='normal' else 'EMIT',uv_layer='ReviewAtlasUV')
  image.save();print('BAKED',channel,flush=True)
  # Remove bake targets after each channel to make active-image selection unambiguous.
  for mat in materials:
   mat.node_tree.nodes.remove(mat.node_tree.nodes['BakeTarget'])
 # Replace source shaders with one standard PBR atlas shader.
 mat=bpy.data.materials.new(prefix+'_ReviewAtlas');mat.use_nodes=True
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
 return mat
