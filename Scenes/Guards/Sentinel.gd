extends "res://Scenes/Guards/GuardBase.gd"
## Sentinel — stationary guard with wider hearing radius.


func _ready() -> void:
	hearing_range = Constants.SENTINEL_HEARING_RANGE
	super._ready()


## Sentinels don't patrol — they stand still.
func _do_patrol() -> void:
	pass
