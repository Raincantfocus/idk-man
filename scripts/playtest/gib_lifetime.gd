extends RigidBody3D
## Ledger ownership outlives the corpse that produced this cosmetic fragment.
var ledger: RefCounted
var lease: int=-1
func _exit_tree() -> void:
 if ledger!=null and lease>=0:ledger.forget(lease)
