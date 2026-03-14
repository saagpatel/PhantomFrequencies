extends "res://Scenes/Guards/GuardBase.gd"
## Patroller — walks a loop of waypoints, one tile per beat.


func _do_patrol() -> void:
	if _patrol_waypoints.is_empty():
		return

	# Advance to next waypoint
	_patrol_index = (_patrol_index + 1) % _patrol_waypoints.size()
	var target: Vector2i = _patrol_waypoints[_patrol_index]

	# Move one step toward waypoint
	_move_toward_tile(target)
