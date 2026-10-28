"""Draw built platforms and planned staging props; script EXPORTED_NPZ ROWS CONFIG PNG."""
import json,sys,numpy as np,matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from matplotlib.patches import Rectangle
from matplotlib.transforms import Affine2D
a=np.load(sys.argv[1]);rows=json.load(open(sys.argv[2]));cfg=json.load(open(sys.argv[3]));fig,ax=plt.subplots(figsize=(9,16))
ax.add_patch(Rectangle((0,-46.150013),16,46.150013,facecolor='#eff2f2',edgecolor='black'))
for x in [.2,13.8]:ax.add_patch(Rectangle((x,-46.15),2,46.15,facecolor='#c6e6ed'))
for r in rows:
 if r['name']!='Killhouse_Object_16':continue
 t=a[r['key']+'_v'][a[r['key']+'_f']];normal=np.cross(t[:,1]-t[:,0],t[:,2]-t[:,0]);t=t[(np.abs(normal[:,1])>1e-9)&(t[:,:,1].max(1)>.1)]
 ax.add_collection(PolyCollection(t[:,:,[0,2]],facecolor='#78848e',edgecolors='none'))
for p in cfg['platforms']:
 x0,x1=p['x_bounds'];z0,z1=p['z_bounds'];ax.add_patch(Rectangle((x0,z0),x1-x0,z1-z0,facecolor='#af8555',edgecolor='#55402a'));ax.text((x0+x1)/2,(z0+z1)/2,f"{p['id'].title()} platform\nDeck 1.8 m\nBUILT",ha='center',va='center',fontsize=9,color='white')
 base=p['stairs_base'][2];top=p['stairs_top'][2];ax.add_patch(Rectangle((3.15,min(base,top)),1.2,abs(top-base),facecolor='#d1ac7b',edgecolor='#55402a'));ax.text(3.75,(base+top)/2,'32°',ha='center',va='center',fontsize=8)
for p in cfg['staging_props']:
 if 'x_bounds' in p:
  x0,x1=p['x_bounds'];z0,z1=p['z_bounds'];x,z=(x0+x1)/2,(z0+z1)/2;w,d=x1-x0,z1-z0
 else:
  x,_,z=p['position'];w,_,d=p.get('size',[1.4,1,1]);
  if p['id']=='SedanWreck':w,d=4,1.8
 patch=Rectangle((x-w/2,z-d/2),w,d,fill=False,edgecolor='#ab4435',linestyle='--',linewidth=1.5)
 patch.set_transform(Affine2D().rotate_deg_around(x,z,p.get('yaw_degrees',0))+ax.transData);ax.add_patch(patch);ax.text(x,z,p['id'].replace('Container','\nContainer').replace('And','\n+'),ha='center',va='center',fontsize=7,color='#8a2e25')
for e in cfg['egress']:
 x,_,z=e['position'];ax.plot([x-.6,x+.6],[z,z],color='#28a746',linewidth=3);ax.text(x+.9,z,e['id']+' 1.2 × 2.2 m',fontsize=8,va='center',color='#158432')
ax.set_xlim(-.5,16.5);ax.set_ylim(-47,1);ax.set_aspect('equal');ax.set_xlabel('Warehouse X (m)');ax.set_ylabel('Warehouse Z (m)');ax.grid(alpha=.2)
ax.set_title('Option A + staging additions\nSolid = built geometry; red dashed = planned props, NOT present\nBlue = reserved 2 m alleys beyond warehouse ribs',fontsize=11)
fig.tight_layout();fig.savefig(sys.argv[4],dpi=150)
