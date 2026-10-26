extends RefCounted
## Lease ledger shared by every effect instance, not a budget per corpse.
## Render objects belong to the caller; eviction invokes its reset/recycle callback.
var limits: Dictionary
var entries: Array[Dictionary]=[]
var sequence: int=0
var gore_mode: int=2
func configure(config: Dictionary) -> void:limits=config.budgets.duplicate(true)
func reserve(kind: StringName, owner_id: int, cost: int, reset: Callable, significance: float=1.0) -> int:
 if gore_mode==0 or cost<=0 or not limits.has(String(kind)):return -1
 if cost>int(limits[String(kind)]):return -1
 if kind==&"gibs" and owner_cost(kind,owner_id)+cost>int(limits.fragments_per_corpse):return -1
 while total(kind)+cost>int(limits[String(kind)]):
  var victim: int=-1
  for i: int in entries.size():
   if entries[i].kind!=kind:continue
   if victim<0 or float(entries[i].significance)<float(entries[victim].significance):victim=i
  if victim<0:return -1
  release(int(entries[victim].id))
 sequence+=1;entries.append({"id":sequence,"kind":kind,"owner":owner_id,"cost":cost,"reset":reset,"significance":significance})
 return sequence
func release(id: int) -> void:
 for i: int in entries.size():
  if entries[i].id!=id:continue
  var callback: Callable=entries[i].reset;entries.remove_at(i)
  if callback.is_valid():callback.call()
  return
func release_owner(owner_id: int) -> void:
 var ids: Array[int]=[]
 for entry: Dictionary in entries:
  if entry.owner==owner_id:ids.append(entry.id)
 for id: int in ids:release(id)
func total(kind: StringName) -> int:
 var count: int=0
 for entry: Dictionary in entries:
  if entry.kind==kind:count+=int(entry.cost)
 return count
func owner_cost(kind: StringName, owner_id: int) -> int:
 var count: int=0
 for entry: Dictionary in entries:
  if entry.kind==kind and entry.owner==owner_id:count+=int(entry.cost)
 return count
func set_gore_mode(mode: int) -> void:
 gore_mode=clampi(mode,0,2)
 if gore_mode==0:
  while not entries.is_empty():release(entries[0].id)
func forget(id: int) -> void:
 # Called when a render object is already leaving the tree; do not recycle it again.
 for i: int in entries.size():
  if entries[i].id==id:entries.remove_at(i);return
