import numpy as np,json,matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.collections import PolyCollection
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import connected_components
from pathlib import Path
root=Path('/workspace/map-intake');rows=json.load(open(root/'killhouse.json'));data=np.load(root/'killhouse.npz')
for only in [False,True]:
 fig,ax=plt.subplots(figsize=(15,8));polys=[];colors=[]
 for row in rows:
  if only and row['name'] not in ['Object_16','Object_9']:continue
  v=data[row['key']+'_v'];f=data[row['key']+'_f'];tri=v[f];height=tri[:,:,1].mean(1)
  polys.extend(tri[:,:,[0,2]]);colors.extend(height)
 order=np.argsort(colors);coll=PolyCollection(np.asarray(polys)[order],array=np.asarray(colors)[order],cmap='viridis',edgecolors='none',clim=(-.17,1.42));ax.add_collection(coll)
 ax.autoscale();ax.set_aspect('equal');ax.set_xlabel('raw x');ax.set_ylabel('raw z');ax.set_title('Killhouse: imported transforms, raw units; color = height y'+(' (structure only)' if only else ''))
 for row in rows:
  if row['name'] in ['Object_4','Object_16','Object_9','Object_26','Object_18']:
   mid=(np.array(row['min'])+row['max'])/2;ax.text(mid[0],mid[2],row['name'],fontsize=8,color='red')
 fig.colorbar(coll,ax=ax,label='raw height y');fig.savefig(root/('structure.png' if only else 'height_plan.png'),dpi=140);plt.close(fig)
for row in rows:
 if row['name'] not in ['Object_16','Object_9']:continue
 v=data[row['key']+'_v'];f=data[row['key']+'_f'];uv,inv=np.unique(np.round(v,5),axis=0,return_inverse=True);fi=inv[f]
 edges=np.concatenate([fi[:,[0,1]],fi[:,[1,2]],fi[:,[2,0]]]);graph=coo_matrix((np.ones(len(edges)),(edges[:,0],edges[:,1])),shape=(len(uv),len(uv)));n,labels=connected_components(graph,directed=False)
 components=[]
 for k in range(n):
  verts=uv[labels==k];cnt=int(np.sum(labels[fi[:,0]]==k));components.append({'component':k,'triangles':cnt,'min':verts.min(0).tolist(),'max':verts.max(0).tolist()})
 (root/(row['name']+'_components.json')).write_text(json.dumps(components,indent=2));print(row['name'],components)
