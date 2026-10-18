"""Private supplied-head region authoring; Blender 4.3+ headless.
blender -b --disable-autoexec --python-exit-code 1 SOURCE.blend -P THIS -- PRIVATE_OUT
Game-plausible engineering review, never clinical anatomy or automatic approval.
"""
import bpy, bmesh, json, math, sys, hashlib
from pathlib import Path
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
repo=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path(__file__).parent))
from inset_neck_ring import inset
cfg=json.loads((repo/'data/characters/head_neck_authoring.json').read_text())
out=Path(sys.argv[sys.argv.index('--')+1]).resolve()
assert not out.is_relative_to(repo)
out.mkdir(parents=True,exist_ok=True)
source=bpy.data.objects[cfg['source_object']]
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
rig.pose.bones['Neck'].rotation_mode='XYZ'
rig.pose.bones['Head'].rotation_mode='XYZ'
base=rig.data.bones['Neck'].head_local.copy();head=rig.data.bones['Head'].head_local.copy()
axis=(head-base).normalized();length=(head-base).length
plane=base+(head-base)*cfg['cut_fraction_neck_to_head_joint']
u=Vector((1,0,0));v=axis.cross(u).normalized()
report={'schema':1,'region':'head_neck','production_ready':False,'source':'Soup fitted head on shared 72-bone rig','anatomy_note':cfg['anatomy_note'],'attempts':[], 'meshes':[], 'failures':[],'screenshots':[]}
report['landmarks']={'neck_joint':list(base),'head_joint':list(head),'neck_joint_distance_m':length,'head_bone_length_m':rig.data.bones['Head'].length}

def rings(edges):
    remaining=set(edges);result=[]
    while remaining:
        e=next(iter(remaining));start=e.verts[0];current=start;ring=[]
        while True:
            ring.append(current)
            choices=[x for x in current.link_edges if x in remaining]
            if not choices:raise RuntimeError('Open/branching boundary')
            edge=choices[0];remaining.remove(edge);current=edge.other_vert(current)
            if current==start:break
        result.append(ring)
    return result

def weights_average(bm, dest, vertices):
    layer=bm.verts.layers.deform.active
    values={}
    for vert in vertices:
        for key,weight in vert[layer].items():values[key]=values.get(key,0)+weight/len(vertices)
    values=sorted(values.items(),key=lambda item:-item[1])[:4];total=sum(w for _,w in values)
    for key,weight in values:dest[layer][key]=weight/total

def repair(bm):
    closure=bm.faces.layers.int.get('source_closure') or bm.faces.layers.int.new('source_closure')
    before=sum(not e.is_manifold for e in bm.edges)
    made=bmesh.ops.holes_fill(bm,edges=[e for e in bm.edges if e.is_boundary],sides=0)['faces']
    for face in made:face[closure]=1;face.material_index=1
    report['attempts'].append({'operation':'source closure','attempt':1,'method':'boundary polygon fill','before':before,'after':sum(not e.is_manifold for e in bm.edges),'new_faces':len(made)})
    if any(e.is_boundary for e in bm.edges):
        # The source has a tiny non-planar 22-edge face hole that holes_fill refuses.
        # A local center fan repairs that loop, retaining the original boundary.
        for ring in rings([e for e in bm.edges if e.is_boundary]):
            center=bm.verts.new(sum((p.co for p in ring),Vector())/len(ring));weights_average(bm,center,ring)
            for i,a in enumerate(ring):
                f=bm.faces.new((a,ring[(i+1)%len(ring)],center));f[closure]=1;f.material_index=1
                for uv in bm.loops.layers.uv.values():
                    for loop in f.loops:
                        donors=[l[uv].uv.copy() for face in loop.vert.link_faces if face!=f for l in face.loops if l.vert==loop.vert]
                        loop[uv].uv=sum(donors,Vector((0,0)))/len(donors) if donors else Vector((.5,.5))
        report['attempts'].append({'operation':'source closure','attempt':2,'method':'local non-planar loop center fan','after':sum(not e.is_manifold for e in bm.edges)})
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    return sum(not e.is_manifold for e in bm.edges)

bm=bmesh.new();bm.from_mesh(source.data)
report['source_non_manifold_edges']=sum(not e.is_manifold for e in bm.edges)
assert repair(bm)==0,'Source repair failed after two methods'
# Two measured conservative topology attempts. Do not remesh the face or discard UVs.
for attempt,angle in [(1,30),(2,80)]:
    faces=[f for f in bm.faces if len(f.verts)==3 and all(abs((x.co-plane).dot(axis))<.055 for x in f.verts)]
    before=len(faces)
    bmesh.ops.join_triangles(bm,faces=faces,angle_face_threshold=math.radians(angle),angle_shape_threshold=math.radians(angle),cmp_uvs=True,cmp_materials=True)
    after=sum(len(f.verts)==3 and all(abs((x.co-plane).dot(axis))<.055 for x in f.verts) for f in bm.faces)
    report['attempts'].append({'operation':'neck joint quad recovery','attempt':attempt,'method':f'UV-preserving adjacent triangle join, {angle} degree limit','triangles_before':before,'triangles_after':after})
report['remaining_neck_deformation_triangles']=after
if after:report['failures'].append(f'Neck deformation zone retains {after} triangles after two UV-preserving join passes; no all-quad claim')
bm.to_mesh(source.data);bm.free();source.data.update()
source.name='HN_intact'
source.data.uv_layers.new(name='WoundUV')
source['review_only']=True
# Wound mask coordinates are local to the cut; source atlas UV0 remains intact.
for poly in source.data.polygons:
 for li in poly.loop_indices:
    p=source.data.vertices[source.data.loops[li].vertex_index].co-plane
    source.data.uv_layers['WoundUV'].data[li].uv=(.5+math.atan2(p.dot(v),p.dot(u))/(2*math.pi),.5+p.dot(axis)/.11)

wound=bpy.data.materials.new('HN_tissue_vertex_atlas');wound.use_nodes=True
bsdf=wound.node_tree.nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=.38;bsdf.inputs['Metallic'].default_value=0
colors=wound.node_tree.nodes.new('ShaderNodeVertexColor');colors.layer_name='TissueColor'
wound.node_tree.links.new(colors.outputs['Color'],bsdf.inputs['Base Color'])
source.data.materials.append(wound)
source_colors=source.data.color_attributes.new(name='TissueColor',type='FLOAT_COLOR',domain='CORNER')
for poly in source.data.polygons:
    for li in poly.loop_indices:source_colors.data[li].color=(.03,.018,.02,1) if poly.material_index==1 else (1,1,1,1)
report['source_closure_material']='New internal repair faces use the shared vertex-colored tissue material; they do not sample or overwrite the supplied exterior atlas.'
# Ordered loop IDs are shared by both sides of every cut, including torn variants.
bm=bmesh.new();bm.from_mesh(source.data)
seams=bm.verts.layers.int.new('wound_seam_vertex_id')
r=bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=plane,plane_no=axis,dist=1e-7)
cut_edges=[e for e in r['geom_cut'] if isinstance(e,bmesh.types.BMEdge)]
loops=rings(cut_edges);assert len(loops)==1
ring=loops[0]
# Orient ring consistently in the cut basis.
area=sum((a.co-plane).dot(u)*(ring[(i+1)%len(ring)].co-plane).dot(v)-(ring[(i+1)%len(ring)].co-plane).dot(u)*(a.co-plane).dot(v) for i,a in enumerate(ring))
if area<0:ring.reverse()
for i,vert in enumerate(ring):vert[seams]=i+1
boundary=[vert.co.copy() for vert in ring]
cut_mesh=bpy.data.meshes.new('HN_inserted_cut_loop');bm.to_mesh(cut_mesh);bm.free()
for mat in source.data.materials:cut_mesh.materials.append(mat)
center=sum(boundary,Vector())/len(boundary)
# Planar offset rings. Radial thickness is measured explicitly, not claimed as
# the normal thickness of the complete body shell.
radii=[(p-center-axis*(p-center).dot(axis)).length for p in boundary]
assert min(radii)>cfg['skin_thickness_m']+cfg['fat_thickness_m']+.01
palette=[(.60,.28,.22,1),(.75,.52,.20,1),(.25,.018,.026,1),(.80,.73,.54,1),(.20,.015,.022,1),(.18,.012,.018,1),(.70,.62,.47,1)]
parts=[];seam_manifest=[]

def capped_half(name,sign,variant):
    obj=source.copy();obj.data=cut_mesh.copy();obj.name=name;bpy.context.collection.objects.link(obj)
    # Mesh datablock replacement clears group names even when deform weights survive.
    if not obj.vertex_groups:
        for group in source.vertex_groups:obj.vertex_groups.new(name=group.name)
    assert [g.name for g in obj.vertex_groups]==[g.name for g in source.vertex_groups]
    b=bmesh.new();b.from_mesh(obj.data)
    to_delete=[x for x in b.verts if (x.co-plane).dot(axis)*sign < -1e-6]
    bmesh.ops.delete(b,geom=to_delete,context='VERTS')
    sid=b.verts.layers.int['wound_seam_vertex_id']
    ring=sorted((x for x in b.verts if x[sid]>0),key=lambda x:x[sid])
    assert len(ring)==len(boundary)
    # Both sides use the same seeded scalar field. Displacement follows the
    # cut normal so the corresponding border stays coincident at rest.
    for i,x in enumerate(ring):
        t=2*math.pi*i/len(ring)
        x.co+=axis*(cfg['tear_amplitude_m']*math.sin(t*5+variant*1.7)*math.sin(t*3+.4))
    layers=[ring];positions=[]
    external=[((old.co-center).dot(u),(old.co-center).dot(v)) for old in ring]
    for depth in [cfg['skin_thickness_m'],cfg['fat_thickness_m']]:
        coordinates=inset(external,depth);new=[]
        for old,point in zip(ring,coordinates):
            vert=b.verts.new(center+u*point[0]+v*point[1]+axis*(old.co-center).dot(axis))
            weights_average(b,vert,[old]);new.append(vert)
        layers.append(new);external=coordinates
    # Bone end with marrow cavity: ring dimensions follow neck joint span.
    bone_radius=length*cfg['bone_radius_to_neck_joint_length']
    for radius in [bone_radius,bone_radius*cfg['marrow_radius_to_bone_radius']]:
        new=[]
        for old,point in zip(ring,external):
            radial=(u*point[0]+v*point[1]).normalized()
            vert=b.verts.new(center+radial*radius+axis*(old.co-center).dot(axis));weights_average(b,vert,[old]);new.append(vert)
        layers.append(new)
    color=b.loops.layers.float_color.get('TissueColor') or b.loops.layers.float_color.new('TissueColor')
    for face in b.faces:
        if face.material_index==0:
            for loop in face.loops:loop[color]=(1,1,1,1)
    uv0=b.loops.layers.uv[0];uv2=b.loops.layers.uv['WoundUV']
    layer_id=b.faces.layers.int.new('wound_layer_id')
    def cap_face(vertices,layer):
        face=b.faces.new(vertices);face.material_index=1;face[layer_id]=layer+1
        for loop in face.loops:
            loop[color]=palette[layer]
            p=loop.vert.co-center;xy=Vector((.5+p.dot(u)/.22,.5+p.dot(v)/.22))
            loop[uv0].uv=xy;loop[uv2].uv=xy
    for j in range(len(layers)-1):
        for i in range(len(ring)):
            k=(i+1)%len(ring);cap_face([layers[j][i],layers[j][k],layers[j+1][k],layers[j+1][i]],j)
    middle=b.verts.new(center);weights_average(b,middle,ring)
    for i in range(len(ring)):cap_face([layers[-1][i],layers[-1][(i+1)%len(ring)],middle],4)
    # Four closed low-poly stubs per cut half, joined into the same draw surface.
    # Roots intentionally overlap the cap by 1 mm to avoid a floating attachment.
    outward=-axis*sign
    for offset,radius,length_m,layer in [(u*.018,.0015,.007,5),(-u*.018,.0015,.007,5),(u*.010+v*.009,.001,.005,6),(-u*.010+v*.009,.001,.005,6)]:
        root=center+offset-outward*.001;end=root+outward*length_m
        rows=[]
        for point in [root,end]:
            row=[]
            for i in range(8):
                angle=2*math.pi*i/8
                vert=b.verts.new(point+(u*math.cos(angle)+v*math.sin(angle))*radius);weights_average(b,vert,ring);row.append(vert)
            rows.append(row)
        for i in range(8):
            k=(i+1)%8;cap_face([rows[0][i],rows[0][k],rows[1][k],rows[1][i]],layer)
        for row,point in zip(rows,[root,end]):
            middle_stub=b.verts.new(point);weights_average(b,middle_stub,ring)
            for i in range(8):cap_face([row[i],row[(i+1)%8],middle_stub],layer)
    bmesh.ops.recalc_face_normals(b,faces=list(b.faces))
    nonmanifold=sum(not e.is_manifold for e in b.edges)
    assert nonmanifold==0,(name,nonmanifold)
    b.verts.index_update()
    indices=[x.index for x in ring];positions=[list(x.co) for x in ring]
    b.faces.index_update()
    layer_manifest={str(j+1):{'name':['skin','fat','muscle','bone','marrow'][j],'faces':[f.index for f in b.faces if f[layer_id]==j+1],'inner_ring_positions':[list(x.co) for x in layers[min(j+1,4)]]} for j in range(5)}
    b.to_mesh(obj.data);b.free();obj.data.update()
    obj['variant']=variant;obj['half']='head' if sign>0 else 'stump'
    parts.append(obj)
    seam_manifest.append({'object':name,'variant':variant,'half':obj['half'],'boundary_indices':indices,'boundary_positions':positions,'non_manifold_edges':nonmanifold,'layers':layer_manifest})
    return obj

for variant in range(cfg['torn_variants']):
    capped_half(f'HN_head_v{variant}',1,variant)
    capped_half(f'HN_stump_v{variant}',-1,variant)
for variant in range(cfg['torn_variants']):
    a,b=seam_manifest[variant*2:variant*2+2]
    assert a['boundary_positions']==b['boundary_positions']
report['seam_vertex_count']=len(boundary);report['seam_match_max_error_m']=0
report['skin_thickness_target_mm']=cfg['skin_thickness_m']*1000
report['fat_thickness_target_mm']=cfg['fat_thickness_m']*1000
report['thickness_method']='Distance-field insets after radial/miter attempts; inner vertices solve the requested minimum cut-plane edge distance; full-volume thickness remains unverified'

# Fit interior forms to the repaired head envelope. Proxy dimensions come from
# this rig, with explicitly art-directed width ratios, not medical data.
# The supplied head has separate head skin, lower cloth and eye components.
# Test containment in their closed union; a nearest eye surface is not the
# outer head envelope and must not classify an otherwise internal vertex.
component_bm=bmesh.new();component_bm.from_mesh(source.data)
remaining=set(component_bm.verts);envelopes=[]
while remaining:
    stack=[remaining.pop()];component=[]
    while stack:
        vert=stack.pop();component.append(vert)
        for edge in vert.link_edges:
            other=edge.other_vert(vert)
            if other in remaining:remaining.remove(other);stack.append(other)
    if len(component)<900:continue
    lookup={vert:i for i,vert in enumerate(component)}
    faces={face for vert in component for face in vert.link_faces}
    envelopes.append(BVHTree.FromPolygons([vert.co for vert in component],[[lookup[vert] for vert in face.verts] for face in faces]))
component_bm.free()
report['containment_method']='Ray parity inside the union of major repaired source components plus 1 mm nearest-surface clearance; vertex and triangle-center samples only, not full-volume certification'
report['source_closed_components']=len(envelopes)
def inside_envelope(point):
    direction=Vector((.813,.317,.492)).normalized()
    for envelope in envelopes:
        near,normal,index,distance=envelope.find_nearest(point)
        if distance<.001:continue
        origin=point.copy();hits=0
        for _ in range(32):
            position,normal,index,distance=envelope.ray_cast(origin,direction)
            if position is None:break
            hits+=1;origin=position+direction*.00001
        if hits%2==1:return True
    return False
interiors=[]
def proxy(name,center,radii,bone,color,kind='ellipsoid'):
    verts=[];faces=[];segments=24;rings_count=12
    for j in range(1,rings_count):
        lat=math.pi*j/rings_count
        for i in range(segments):
            t=2*math.pi*i/segments
            verts.append(center+Vector((radii[0]*math.sin(lat)*math.cos(t),radii[1]*math.sin(lat)*math.sin(t),radii[2]*math.cos(lat))))
    top=len(verts);verts.append(center+Vector((0,0,radii[2])));bottom=len(verts);verts.append(center-Vector((0,0,radii[2])))
    for j in range(rings_count-2):
        for i in range(segments):
            k=(i+1)%segments;faces.append((j*segments+i,j*segments+k,(j+1)*segments+k,(j+1)*segments+i))
    for i in range(segments):
        k=(i+1)%segments;faces.append((top,k,i));faces.append((bottom,(rings_count-2)*segments+i,(rings_count-2)*segments+k))
    if kind=='mandibular arch':
        verts=[];faces=[];path=[];steps=25;tube=8
        for j in range(steps):
            angle=math.pi*j/(steps-1)
            path.append(center+Vector((head_length*.30*math.cos(angle),-head_length*.29*math.sin(angle),head_length*.20*math.cos(angle)**4)))
        for j,point in enumerate(path):
            tangent=(path[min(j+1,steps-1)]-path[max(j-1,0)]).normalized()
            side=tangent.cross(Vector((0,0,1))).normalized();up=side.cross(tangent).normalized()
            for i in range(tube):
                angle=2*math.pi*i/tube
                verts.append(point+(side*math.cos(angle)+up*math.sin(angle))*head_length*.032)
        for j in range(steps-1):
            for i in range(tube):faces.append((j*tube+i,j*tube+(i+1)%tube,(j+1)*tube+(i+1)%tube,(j+1)*tube+i))
        first=len(verts);verts.append(path[0]);last=len(verts);verts.append(path[-1])
        for i in range(tube):faces.append((first,(i+1)%tube,i));faces.append((last,(steps-1)*tube+i,(steps-1)*tube+(i+1)%tube))
    if kind=='cervical annular proxy':
        verts=[];faces=[];steps=24;tube=8
        for j in range(steps):
            angle=2*math.pi*j/steps;radial=u*math.cos(angle)+v*math.sin(angle)
            for i in range(tube):
                t=2*math.pi*i/tube
                verts.append(center+radial*(length*.068+length*.028*math.cos(t))+axis*length*.028*math.sin(t))
        for j in range(steps):
            for i in range(tube):faces.append((j*tube+i,j*tube+(i+1)%tube,((j+1)%steps)*tube+(i+1)%tube,((j+1)%steps)*tube+i))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    if name=='HN_skull':
        for vert in mesh.vertices:
            q=vert.co-center;front=max(0,-q.y/max(radii[1],1e-6))**2
            sockets=sum(.016*math.exp(-((q.x-offset)/.018)**2-((q.z+.022)/.022)**2) for offset in [-.025,.025])
            vert.co.y+=front*sockets
    for poly in mesh.polygons:poly.use_smooth=True
    obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj);obj.parent=rig
    vg=obj.vertex_groups.new(name=bone);vg.add(list(range(len(verts))),1,'REPLACE')
    mod=obj.modifiers.new('HumanoidSkin','ARMATURE');mod.object=rig
    mesh.materials.append(wound)
    color_attr=mesh.color_attributes.new(name='TissueColor',type='FLOAT_COLOR',domain='CORNER')
    fiber=mesh.color_attributes.new(name='FiberDirection',type='FLOAT_COLOR',domain='POINT')
    for c in color_attr.data:c.color=color
    for c in fiber.data:c.color=(.5,.5,1,1)
    uv=mesh.uv_layers.new(name='InteriorUV');flow=mesh.uv_layers.new(name='WoundUV')
    for p in mesh.polygons:
        for li in p.loop_indices:
            co=mesh.vertices[mesh.loops[li].vertex_index].co-center
            xy=(.5+math.atan2(co.y/radii[1],co.x/radii[0])/(2*math.pi),.5+co.z/(2*radii[2]))
            uv.data[li].uv=xy;flow.data[li].uv=xy
    attempts=[]
    for attempt in [1,2]:
        bad=[]
        for vert in mesh.vertices:
            if not inside_envelope(vert.co):bad.append(vert.index)
        attempts.append({'attempt':attempt,'vertices_outside_1mm_clearance':len(bad)})
        if not bad:break
        if attempt==1:
            # Move only offending vertices inside the nearest major source
            # envelope; global shrinking previously made cranial fit worse.
            for index in bad:
                vert=mesh.vertices[index]
                candidates=[envelope.find_nearest(vert.co) for envelope in envelopes]
                near,normal,face,distance=min(candidates,key=lambda item:item[3])
                candidate=near-normal*.002
                if (candidate-vert.co).length<=.005 and inside_envelope(candidate):vert.co=candidate
            mesh.update()
    if bad:report['failures'].append(name+': containment failed after landmark fit and local inward projection')
    bb=bmesh.new();bb.from_mesh(mesh);bmesh.ops.recalc_face_normals(bb,faces=list(bb.faces));nonmanifold=sum(not e.is_manifold for e in bb.edges);bb.to_mesh(mesh);bb.free()
    mesh.calc_loop_triangles()
    report['meshes'].append({'name':name,'triangles':sum(len(p.vertices)-2 for p in mesh.polygons),'non_manifold_edges':nonmanifold,'containment_attempts':attempts,'outside_triangle_centers':sum(not inside_envelope(sum((mesh.vertices[i].co for i in tri.vertices),Vector())/3) for tri in mesh.loop_triangles),'kind':kind})
    if report['meshes'][-1]['outside_triangle_centers']:report['failures'].append(name+': triangle-center containment check failed')
    interiors.append(obj);return obj
head_length=rig.data.bones['Head'].length
# A joint-bounded clearance search replaces the rejected landmark ellipsoid.
# The inscribed volume is deliberately conservative; it is a hidden game proxy.
best_center=None;best_clearance=0.0
for ix in range(-2,3):
 for iy in range(13):
  for iz in range(9):
   candidate=head+Vector((ix*head_length*.08,-head_length*.65+iy*head_length*.055,head_length*(.4+iz*.065)))
   if not inside_envelope(candidate):continue
   distances=[envelope.find_nearest(candidate)[3] for envelope in envelopes]
   clearance=min(distances)
   if clearance>best_clearance:best_center=candidate;best_clearance=clearance
assert best_center is not None and best_clearance>.01,'No usable cranial interior volume found'
skull_radius=min(head_length*.43,best_clearance*.90)
report['cranial_fit']={'method':'585 joint-bounded samples, conservative maximum-clearance inscribed proxy','clearance_m':best_clearance,'radius_m':skull_radius,'not_a_medical_skull':True}
proxy('HN_skull',best_center,(skull_radius*.96,skull_radius,skull_radius),'Head',(.78,.72,.53,1),'conservative cranial solid proxy with frontal recesses; not hollow skull')
# Mandible approximation uses paired ramus and body masses. Recorded as a proxy,
# not a claim of a finished U-shaped mandibular bone.
proxy('HN_mandible',head+Vector((0,-.020,.012)),(.05,.05,.04),'Head',(.78,.72,.53,1),'mandibular arch')
for i in range(7):
    center_v=base+(head-base)*((i+.5)/7)
    proxy(f'HN_cervical_{i+1}',center_v,(length*.085,length*.10,length/7*.42),'Neck',(.78,.72,.53,1),'cervical annular proxy')
for side in [-1,1]:
    proxy('HN_neck_muscle_'+('L' if side<0 else 'R'),base+(head-base)*.55+Vector((side*.020,-.007,0)),(.009,.010,length*.46),'Neck',(.28,.018,.026,1),'neck muscle envelope with longitudinal fiber data')

# Measured pose-space corrective: restore DQ-vs-LBS displacement at a captured
# neck extreme. Convert that displacement back through each vertex's blended
# skin matrix; Godot applies the exported shape, not a Blender driver.
corrective_defs=[]
poses=cfg['corrective_poses']
for obj in [source]+parts:
    if not obj.data.shape_keys:obj.shape_key_add(name='Basis')
    mod=next(m for m in obj.modifiers if m.type=='ARMATURE');mod.object=rig
    for key_name,pose_bone,rotation_axis,degrees in poses:
        rig.pose.bones['Neck'].rotation_euler=(0,0,0);rig.pose.bones['Head'].rotation_euler=(0,0,0);rig.pose.bones[pose_bone].rotation_euler[rotation_axis]=math.radians(degrees)
        bpy.context.view_layer.update()
        def posed(preserve):
            mod.use_deform_preserve_volume=preserve;bpy.context.view_layer.update()
            evaluated=obj.evaluated_get(bpy.context.evaluated_depsgraph_get());mesh=evaluated.to_mesh()
            coords=[p.co.copy() for p in mesh.vertices]
            b=bmesh.new();b.from_mesh(mesh);volume=abs(b.calc_volume());b.free();evaluated.to_mesh_clear();return coords,volume
        lbs,lv=posed(False);dq,dv=posed(True)
        matrices={g.index:rig.pose.bones[g.name].matrix@rig.data.bones[g.name].matrix_local.inverted() for g in obj.vertex_groups if g.name in rig.pose.bones}
        key=obj.shape_key_add(name=key_name)
        max_delta=0.0
        for vert in obj.data.vertices:
            blend=Matrix(((0,0,0),(0,0,0),(0,0,0)))
            for g in vert.groups:
                if g.group in matrices:blend+=matrices[g.group].to_3x3()*g.weight
            delta=blend.inverted_safe()@(dq[vert.index]-lbs[vert.index])
            key.data[vert.index].co=vert.co+delta;max_delta=max(max_delta,delta.length)
        mod.use_deform_preserve_volume=False;key.value=1
        _,cv=posed(False);key.value=0
        report.setdefault('correctives',[]).append({'mesh':obj.name,'key':key_name,'rotation_degrees':degrees,'lbs_volume_m3':lv,'dq_target_volume_m3':dv,'corrected_volume_m3':cv,'relative_error_to_dq':abs(cv-dv)/max(dv,1e-12),'max_rest_delta_m':max_delta})
    rig.pose.bones['Neck'].rotation_euler=(0,0,0);rig.pose.bones['Head'].rotation_euler=(0,0,0);bpy.context.view_layer.update()
    # Closed-fracture visual dent is separate from the angle-driven correction.
    key=obj.shape_key_add(name='fractured_closed')
    for vert in obj.data.vertices:
        d=(vert.co-plane).dot(axis);radial=vert.co-center-axis*(vert.co-center).dot(axis)
        key.data[vert.index].co=vert.co-radial*.035*math.exp(-(d/.014)**2)
for name,bone,a,deg in poses:corrective_defs.append({'shape':name,'bone':bone,'axis':[1 if i==a else 0 for i in range(3)],'angle_degrees':deg})

# Manifest transforms are Godot coordinates: Blender (x,y,z) -> (x,z,-y).
def godot(p):return [p.x,p.z,-p.y]
markers=[]
for name,p,direction in [('artery_L',plane+u*.018,-axis),('artery_R',plane-u*.018,-axis),('head_entry',head+Vector((0,-.10,.08)),Vector((0,-1,0))),('head_exit',head+Vector((0,.075,.08)),Vector((0,1,0)))]:
    empty=bpy.data.objects.new('HN_socket_'+name,None);bpy.context.collection.objects.link(empty);empty.location=p;empty.empty_display_type='ARROWS';empty.empty_display_size=.015
    markers.append({'name':empty.name,'position':godot(p),'outward':godot(direction),'bone':'Head' if name.startswith('head') else 'Neck'})

for obj in [source]+parts:
    obj.data.calc_loop_triangles()
    b=bmesh.new();b.from_mesh(obj.data)
    report['meshes'].append({'name':obj.name,'triangles':len(obj.data.loop_triangles),'non_manifold_edges':sum(not e.is_manifold for e in b.edges),'bones':len(rig.data.bones),'materials':len(obj.data.materials),'vertex_group_names':len(obj.vertex_groups),'bad_weight_vertices':sum(abs(sum(g.weight for g in vert.groups)-1)>1e-4 or len(vert.groups)>4 for vert in obj.data.vertices),'uv_channels':len(obj.data.uv_layers)})
    b.free()
    for poly in obj.data.polygons:poly.use_smooth=True

states={}
for state in ['intact','damaged','fractured_closed','fractured_open','detached']:
    # Same seam data drives both open and detached; preview assembly moves the
    # detached half. Cosmetic states do not emit damage, death, or rewards.
    objects=[source] if state in ['intact','damaged','fractured_closed'] else parts
    if state=='fractured_closed':source.data.shape_keys.key_blocks['fractured_closed'].value=1
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
    for obj in objects:obj.select_set(True)
    path=out/f'HN_{state}.glb'
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_vertex_colors=True,export_morph=True,export_morph_normal=True,export_yup=True,export_tangents=True,export_cameras=False,export_lights=False)
    states[state]={'path':path.name,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'meshes':[obj.name for obj in objects]}
    source.data.shape_keys.key_blocks['fractured_closed'].value=0
# Interior file is separate so loading intact presentation need not instantiate it.
bpy.ops.object.select_all(action='DESELECT');rig.select_set(True)
for obj in interiors:obj.select_set(True)
path=out/'HN_interiors.glb'
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_skins=True,export_all_vertex_colors=True,export_yup=True,export_tangents=True)
report['limitations']=['Full-volume skin/fat shell thickness and 3D surface intersections remain unverified; cut-plane checks are reported separately','UV overlap and local texel density not certified; procedural interior UV seams require review','No reduced LOD acceptance; region currently exports only LOD0','Mandible and cervical meshes are simplified arch/ring proxies; art-directed dimensions lack a verified published anthropometric reference','Four vessel/tendon stubs per half are generated; final garment-to-skin cut correspondence remains unfinished','Damaged mask appearance is implemented in review shader only; no gameplay activation']
manifest={'schema':1,'region':'head_neck','production_ready':False,'coordinate_system':'Godot meters, +Y up','source_reference':'Soup supplied head, fitted shared rig; neck stump is a head-source collar, not a completed torso','bone_names':[b.name for b in rig.data.bones],'cut':{'position':godot(plane),'normal':godot(axis),'basis_columns':[godot(u),godot(v),godot(axis)],'fraction_neck_to_head_joint':cfg['cut_fraction_neck_to_head_joint'],'boundary_space':'Blender local meters; convert (x,y,z) to (x,z,-y)','seams':seam_manifest},'skin_mm':2,'fat_mm':4,'sockets':markers,'states':states,'interiors':{'path':'HN_interiors.glb','visible_by_default':False},'correctives':corrective_defs,'material_slots':['supplied_head_atlas','vertex-colored_tissue'],'review_offsets':cfg['review_offsets'],'limits':{'corrective_distance_m':cfg['corrective_distance_m']},'report':'validation.json'}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
(out/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
for text in list(bpy.data.texts):bpy.data.texts.remove(text)
bpy.context.preferences.filepaths.save_version=0
authoring=out/'authoring';authoring.mkdir(exist_ok=True);(authoring/'.gdignore').touch()
bpy.ops.wm.save_as_mainfile(filepath=str(authoring/'head_neck_authoring.blend'))
print('HEAD_NECK_AUTHORED',json.dumps({'seam_vertices':len(boundary),'mesh_count':len(report['meshes']),'failures':report['failures']}),flush=True)
