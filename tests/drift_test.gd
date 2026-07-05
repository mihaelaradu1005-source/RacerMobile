extends Node

# Verifies the handbrake/drift button: while held, the rear wheels drop to the
# low drift grip and the car rotates more (slides) through a turn, but stays
# upright and keeps moving (a controllable drift, not a spin-out or flip).

var _car: VehicleBody3D
var _joy: Node
var _hb: Node
var _f: int = 0
var _yaw_at_brake: float = 0.0


func _ready() -> void:
	_joy = get_tree().get_first_node_in_group("joystick")
	_hb = get_tree().get_first_node_in_group("handbrake")
	_car = _find_vehicle(get_tree().root)


func _find_vehicle(n: Node) -> VehicleBody3D:
	if n is VehicleBody3D:
		return n
	for c in n.get_children():
		var found := _find_vehicle(c)
		if found != null:
			return found
	return null


func _rear_grip() -> float:
	for w in _car.get_children():
		if w is VehicleWheel3D and not w.use_as_steering:
			return w.wheel_friction_slip
	return -1.0


func _physics_process(_d: float) -> void:
	_f += 1
	if _joy != null:
		if _f <= 40:
			_joy.output = Vector2(0.0, -1.0)            # build speed, straight
		else:
			_joy.output = Vector2(0.8, -0.5)            # turn right + gas
	# Engage the handbrake from frame 60 on.
	if _hb != null:
		_hb.pressed = _f >= 60

	if _f % 20 == 0:
		var kmh := _car.linear_velocity.length() * 3.6
		var up_y := _car.global_transform.basis.y.y
		var yaw := rad_to_deg(_car.rotation.y)
		var hb: bool = _hb != null and _hb.pressed
		print("f=%d handbrake=%s rear_grip=%.1f speed=%.1f yaw=%.0f up_y=%.2f (%s)" % [
			_f, str(hb), _rear_grip(), kmh, yaw, up_y, ("upright" if up_y > 0.5 else "TIPPED")])

	if _f >= 160:
		print("DRIFTTEST DONE")
		get_tree().quit()
