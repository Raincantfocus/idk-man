extends Resource
@export var values: Dictionary={}
func json_export() -> String:return JSON.stringify(values,"  ")
