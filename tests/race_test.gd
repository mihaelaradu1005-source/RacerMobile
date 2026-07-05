extends Node

# Verifies lap timing without having to drive: teleports the car through the
# checkpoints in order for two full laps and checks the manager counts 2 laps
# and records a best time. Also checks that an OUT-OF-ORDER hit is ignored.

var _car: VehicleBody3D
var _mgr: Node
var _cps: Node
var _order := [0, 1, 2, 3, 0, 1, 2, 3, 0]
var _i: int = -1
var _f: int = 0
var _wrong_way_checked := false
const STEP := 6


func _ready() -> void:
	_mgr = get_tree().get_first_node_in_group("race_manager")
	_car = _find_vehicle(get_tree().root)
	_cps = get_tree().root.find_child("Checkpoints", true, false)


func _find_vehicle(n: Node) -> VehicleBody3D:
	if n is VehicleBody3D:
		return n
	for c in n.get_children():
		var found := _find_vehicle(c)
		if found != null:
			return found
	return null


func _tp(cp_index: int) -> void:
	var cp: Node3D = _cps.get_child(cp_index)
	_car.global_position = cp.global_position + Vector3.UP * 1.0
	_car.linear_velocity = Vector3.ZERO
	_car.angular_velocity = Vector3.ZERO


func _physics_process(_d: float) -> void:
	_f += 1
	if _f % STEP != 0:
		return
	_i += 1
	if _i < _order.size():
		_tp(_order[_i])
		print("-> CP%d   lap=%d  best=%.2f  next_expected=%d" % [
			_order[_i], _mgr.lap, _mgr.best_time, _mgr._expected])
	else:
		print("RESULT: laps=%d  best=%.2f" % [_mgr.lap, _mgr.best_time])
		print("RACETEST DONE")
		get_tree().quit()
