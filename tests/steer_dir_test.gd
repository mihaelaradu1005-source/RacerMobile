extends Node

# Definitive check that "stick right = car goes right ON SCREEN", accounting for
# where the chase camera looks. We capture the camera's screen-right vector while
# driving straight, then push the stick right and measure whether the car's net
# displacement is toward that screen-right (correct) or opposite (inverted).

var _car: VehicleBody3D
var _cam: Camera3D
var _joy: Node
var _f: int = 0
var _cam_right0: Vector3
var _pos0: Vector3


func _ready() -> void:
	_joy = get_tree().get_first_node_in_group("joystick")
	_car = _find_vehicle(get_tree().root)
	_cam = get_tree().root.find_child("Camera3D", true, false)


func _find_vehicle(n: Node) -> VehicleBody3D:
	if n is VehicleBody3D:
		return n
	for c in n.get_children():
		var found := _find_vehicle(c)
		if found != null:
			return found
	return null


func _physics_process(_d: float) -> void:
	_f += 1
	if _joy != null:
		if _f <= 40:
			_joy.output = Vector2(0.0, -1.0)          # straight, build speed
		else:
			_joy.output = Vector2(1.0, -0.4)          # push RIGHT (+ a little gas)

	if _f == 40:
		_cam_right0 = _cam.global_transform.basis.x   # screen-right while straight
		_pos0 = _car.global_position

	if _f == 140:
		var d := _car.global_position - _pos0
		var lateral := d.dot(_cam_right0)
		print("lateral_on_screen = %.2f  ->  %s" % [
			lateral, ("RIGHT (correct)" if lateral > 0.0 else "LEFT (inverted)")])
		print("STEERDIR DONE")
		get_tree().quit()
