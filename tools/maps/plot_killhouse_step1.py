from pathlib import Path
import numpy as np,json,sys,matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
root=Path(sys.argv[1]);out=Path(sys.argv[2]);out.mkdir(exist_ok=True,parents=True)
data=np.load(root/'killhouse_step1.npz');report=json.loads((root/'step1_geometry.json').read_text());doors=json.loads((root/'opening_validation.json').read_text());cfg=report['config'];center=np.array(report['original_bounds_center_raw'])
def world(raw):
 p=(np.array(raw)-[center[0],cfg['floor_raw_y'],center[2]])*cfg['layout_scale'];return p[[2,1,0]]*[1,1,-1]
fig,ax=plt.subplots(figsize=(8,14));polys=[];heights=[]
for row in report['meshes']:
 t=data[row['name']+'_v'][data[row['name']+'_f']];polys.extend(t[:,:,[0,2]]);heights.extend(t[:,:,1].mean(1))
order=np.argsort(heights);collection=PolyCollection(np.array(polys)[order],array=np.array(heights)[order],cmap='viridis',clim=(0,4.7),edgecolors='none');ax.add_collection(collection)
for i,d in enumerate(doors):
 raw=np.zeros(3);raw[1]=cfg['floor_raw_y'];raw[d['raw_plane_axis']]=d['raw_plane'];raw[2 if d['raw_plane_axis']==0 else 0]=d['raw_lateral_center'];p=world(raw);ax.plot(p[0],p[2],'ro',markersize=4);ax.annotate(chr(65+i),(p[0],p[2]),xytext=(6,6),textcoords='offset points',color='red',weight='bold')
ax.autoscale();ax.set_aspect('equal');ax.set_xlabel('review x (m)');ax.set_ylabel('review z (m)');ax.set_title('Step 1: S=3, yaw +90° — not placed in warehouse\nFootprint 11.860 × 23.332 m; selected walls remodeled')
fig.colorbar(collection,ax=ax,label='height above original main floor (m)',shrink=.5)
fig.savefig(out/'step1_height_plan.png',dpi=150);plt.close(fig)
tri=data['Object_16_v'][data['Object_16_f']]
fig,axes=plt.subplots(2,4,figsize=(16,8))
for i,(d,ax) in enumerate(zip(doors,axes.flat)):
 raw=np.zeros(3);raw[1]=cfg['floor_raw_y'];raw[d['raw_plane_axis']]=d['raw_plane'];raw[2 if d['raw_plane_axis']==0 else 0]=d['raw_lateral_center'];p=world(raw)
 normal_axis=2 if d['raw_plane_axis']==0 else 0;lateral=0 if normal_axis==2 else 2
 near=np.max(np.abs(tri[:,:,normal_axis]-p[normal_axis]),axis=1)<.32
 t=tri[near];poly=t[:,:,[lateral,1]].copy();poly[:,:,0]-=p[lateral]
 ax.add_collection(PolyCollection(poly,facecolor='#697f86',edgecolor='#30464a',linewidth=.2))
 lo,hi=d['sampled_height_range_m'];ax.add_patch(plt.Rectangle((-.515,lo),1.03,hi-lo,fill=False,edgecolor='#21bf44',linewidth=2))
 ax.set_xlim(-1.2,1.2);ax.set_ylim(-.1,3.1);ax.set_aspect('equal');ax.set_title(chr(65+i)+': '+d['name'],fontsize=9);ax.set_xlabel('lateral m');ax.set_ylabel('height m');ax.grid(alpha=.2)
fig.suptitle('Actual modified triangles near each opening; green = sampled clear rectangle\n805 triangle-ray samples per opening, 0 blocked; not a Godot capsule sweep')
fig.tight_layout();fig.savefig(out/'opening_elevations.png',dpi=150);plt.close(fig)
