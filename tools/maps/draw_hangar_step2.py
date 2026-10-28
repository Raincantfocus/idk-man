"""Actual triangle projections for Step 2 proposals; no runtime scene generation.
Usage: script INTAKE STEP1 REPORT_DIRECTORY
"""
from pathlib import Path
import json,sys,numpy as np,matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from matplotlib.patches import Rectangle
root,step,out=map(Path,sys.argv[1:]);kh=np.load(root.parent/'map-step2'/'proposed_coordinates.npz');wh=np.load(root/'warehouse.npz')
report=json.loads((out/'placement_validation.json').read_text())
fig,axs=plt.subplots(1,2,figsize=(13,15))
for ax,plan in zip(axs,report['plans']):
 dx,_,dz=plan['translation_m'];polys=[];heights=[]
 ax.add_patch(Rectangle((0,-46.150013),16,46.150013,facecolor='#edf0f0',edgecolor='#202a35',linewidth=2))
 for x in [0,13.752089]:ax.add_patch(Rectangle((x,-46.15),2.247911,46.15,facecolor='#cce8ef'))
 for key in kh.files:
  if not key.endswith('_v'):continue
  name=key[:-2];v=kh[key].copy();f=kh[name+'_f']
  for move in report['proposed_prop_moves']:
   if move['mesh']==name:v=v@np.array(move['rotation_rows']).T+move['translation_before_layout_placement_m']
  t=v[f]
  # Plan shows source horizontal surfaces and top edges. Vertical sheets remain
  # explicitly outlined by footprint; they are pending Step 3 removal.
  cross=np.cross(t[:,1]-t[:,0],t[:,2]-t[:,0]);keep=(np.abs(cross[:,1])>1e-8)&(t[:,:,1].max(1)>.05)
  t=t[keep];t[:,:,[0,2]] += [dx,dz]
  polys.extend(t[:,:,[0,2]]);heights.extend(t[:,:,1].mean(1))
 order=np.argsort(heights);ax.add_collection(PolyCollection(np.array(polys)[order],array=np.array(heights)[order],cmap='cividis',clim=(0,4.7),edgecolors='none',rasterized=True))
 ax.add_patch(Rectangle((2.247911,dz-11.316073),11.504178,22.632147,fill=False,edgecolor='#cc6600',linestyle='--',linewidth=1.5))
 ax.annotate('ENTRY / door currently closed',xy=(8,0),xytext=(8,2),ha='center',arrowprops={'arrowstyle':'->'},fontsize=10)
 ax.text(8,dz+11.316073+plan['entry_staging_m']/2,f"Entry staging\n{plan['entry_staging_m']:.2f} m",ha='center',va='center')
 ax.text(8,-46.15+plan['rear_staging_m']/2,f"Rear staging\n{plan['rear_staging_m']:.2f} m",ha='center',va='center')
 for x in [1.035,14.965]:ax.text(x,-23,'2.05 m clear past ribs',rotation=90,ha='center',va='center',fontsize=9)
 ax.plot(8,dz,'r+',markersize=10);ax.annotate('Layout origin',(8,dz),xytext=(15,12),textcoords='offset points',fontsize=8,color='red')
 p=min((r for r in plan['proposed_after'] if not r['pending_shell_removal']),key=lambda r:r['min_clearance_m'])['critical_point']
 ax.plot(p[0],p[2],'ro',markersize=5);ax.annotate('Tower clearance limit',(p[0],p[2]),xytext=(-90,-30),textcoords='offset points',arrowprops={'arrowstyle':'->'},fontsize=8,color='red')
 ax.set_xlim(-.6,16.6);ax.set_ylim(-47,3.5);ax.set_aspect('equal');ax.set_xlabel('Warehouse X (m)');ax.set_ylabel('Warehouse Z (m)');ax.grid(alpha=.15)
 low=min(r['min_clearance_m'] for r in plan['proposed_after'] if not r['pending_shell_removal'])
 ax.set_title(('A — centered (recommended)' if plan['id']=='centered' else 'B — 3 m toward rear')+f"\nTower proposed top {3+(4.688005*.97-3)*plan['tower_upper_factor']:.3f} m; gap ≥{low:.3f} m",fontsize=11)
fig.suptitle('STEP 2 • placement proposals, not a playable scene\nSource-mesh plan; dashed bounds include outer sheets pending removal\nS=2.91 proposed; tower lowering labeled; upright pallets restacked onto existing pile',fontsize=13)
fig.tight_layout(rect=(0,0,1,.94));fig.savefig(out/'placement_options.png',dpi=145);plt.close(fig)
# Longitudinal critical-point sections through actual metal triangles.
fig,axes=plt.subplots(2,1,figsize=(13,8))
t=wh['mesh0_v'][wh['mesh0_f']]
for ax,p in zip(axes,report['plans']):
 critical=min((r for r in p['proposed_after'] if not r['pending_shell_removal']),key=lambda r:r['min_clearance_m']);x,y,z=critical['critical_point']
 segments=[]
 for tri in t:
  points=[]
  for a,b in [(tri[0],tri[1]),(tri[1],tri[2]),(tri[2],tri[0])]:
   if (a[0]-x)*(b[0]-x)<=0 and abs(b[0]-a[0])>1e-9:points.append(a+(b-a)*(x-a[0])/(b[0]-a[0]))
  if len(points)>=2:ax.plot([points[0][2],points[1][2]],[points[0][1],points[1][1]],color='#556677',linewidth=.6)
 gap=critical['min_clearance_m'];ax.plot(z,y,'ro');ax.annotate('',xy=(z,y),xytext=(z,y+gap),arrowprops={'arrowstyle':'<->','color':'red'});ax.text(z+.8,y,f'{gap:.3f} m minimum\nX={x:.3f} m',color='red')
 ax.axhline(2.716,color='green',linestyle='--',label='2.716 m partitions');ax.set_xlim(z-5,z+5);ax.set_ylim(2.5,5.2);ax.set_xlabel('Warehouse Z (m)');ax.set_ylabel('Y (m)');ax.set_title(p['id']+' — actual Metal slice through clearance limit');ax.grid(alpha=.2)
fig.tight_layout();fig.savefig(out/'roof_clearance_sections.png',dpi=150)
