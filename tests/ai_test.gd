extends Node

# Checks the AI opponent: it should advance along the racing line, complete a
# lap, and the race manager should compute a position (P1/P2). The player car is
# left parked at the start, so the moving AI should pull ahead (player -> P2).

var _ai: Node
var _mgr: Node
var _f: int = 0
var _last_ratio: float = 0.0
var _min_step: float = 999.0
var _max_step: float = 0.0


func _ready() -> void:
	_ai = get_tree().get_first_node_in_group("ai")
	_mgr = get_tree().get_first_node_in_group("race_manager")


func _physics_process(d: float) -> void:
	_f += 1
	# Track how much path-progress the AI makes per frame (proxy for speed):
	# smaller on corners, larger on straights.
	if _ai != null:
		var step: float = _ai.progress_ratio - _last_ratio
		if step >= 0.0:
			_min_step = minf(_min_step, step)
			_max_step = maxf(_max_step, step)
		_last_ratio = _ai.progress_ratio

	if _f % 150 == 0 and _ai != null:
		var pos: Vector3 = (_ai as Node3D).global_position
		print("f=%d ratio=%.2f laps=%d aipos=(%.0f,%.0f) player_pos=P%d" % [
			_f, _ai.progress_ratio, _ai.laps, pos.x, pos.z, _mgr.position])

	if (_ai != null and _ai.laps >= 1) or _f >= 4000:
		print("AI lap done: laps=%d  corner/straight speed ratio=%.2f" % [
			_ai.laps, (_min_step / _max_step) if _max_step > 0.0 else 0.0])
		print("AITEST DONE")
		get_tree().quit()
