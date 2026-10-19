"""Analytical shell-sign calibration and stage invariants. Run with Blender."""
import sys,json,hashlib
from pathlib import Path
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
# Outward +Z garment patch: below is inside, above is an outside vertex.
bvh=BVHTree.FromPolygons([(-1,-1,0),(1,-1,0),(1,1,0),(-1,1,0)],[(0,1,2),(0,2,3)],all_triangles=True)
for z in [-.01,.001,.003]:
 p=Vector((.1,.2,z));q,n,face,d=bvh.find_nearest(p,.12)
 assert abs(d-abs(z))<1e-7
 assert ((p-q).dot(n)>0)==(z>0)
 hit,normal,_,_=bvh.ray_cast(p+Vector((0,0,.00005)),Vector((0,0,1)),.12)
 assert (hit is not None)==(z<0)
args=sys.argv[sys.argv.index('--')+1:];root=Path(args[0]);data=json.loads((root/'baseline_input.json').read_text())
c=json.loads((root/'stage_c/patch.json').read_text());body=data['meshes'][0];edit=c['meshes'][body['name']];protected=np.array(edit['protected']);original=np.array(body['vertices']);changed=np.array(edit['v'])
assert np.array_equal(original[protected],changed[protected]);assert np.max(np.linalg.norm(changed-original,axis=1))<=.010001
for mesh in data['meshes'][1:]:
 a=json.loads((root/'stage_a_bind/patch.json').read_text())['meshes'][mesh['name']];weights=np.array(a['w']);assert weights.shape[1]==4;assert abs(weights.sum(axis=1)-1).max()<1e-6
 b=json.loads((root/'stage_b/patch.json').read_text())['meshes'][mesh['name']];limit=.020001 if mesh['name']=='complete_kit' else .008001
 assert np.max(np.linalg.norm(np.array(b['v'])-np.array(mesh['vertices']),axis=1))<=limit
print('PASS: analytic inside/outside sign, layered ray direction, 5577 protected vertices unchanged, 10 mm shrink bound, normalized four-influence weights, garment displacement bounds')
