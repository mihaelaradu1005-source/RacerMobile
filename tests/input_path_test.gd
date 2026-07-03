extends Node

# Headless test of the FULL input path that mobile uses:
#   touch joystick -> car.gd reads joystick.output -> engine force -> motion.
# The earlier vehicle_test set engine_force directly and so never exercised the
# car <-> joystick wiring. This reproduces the "car doesn't move on phone" bug:
# it holds the joystick fully forward and checks the car actually accelerates.
# Run: godot --headless --quit-after 9000 --path . tests/input_path_test.tscn

var _car: VehicleBody3D
var _joy: Node
var _frames: int = 0


func _ready() -> void:
	_joy = get_tree().get_first_node_in_group("joystick")
	_car = _find_vehicle(get_tree().root)


func _find_vehicle(n: Node) -> VehicleBody3D:
	if n is VehicleBody3D:
		return n
	for c in n.get_children():
		var found := _find_vehicle(c)
		if found != null:
			return found
	return null


func _physics_process(_delta: float) -> void:
	_frames += 1

	# Simulate a thumb holding the stick fully "up" = forward.
	if _joy != null:
		_joy.output = Vector2(0.0, -1.0)

	if _frames % 30 == 0:
		var spd := 0.0
		var zz := 0.0
		if _car != null:
			spd = _car.linear_velocity.length()
			zz = _car.global_position.z
		print("frame=%d  joy_found=%s  car_found=%s  z=%.2f  speed=%.2f" % [
			_frames, str(_joy != null), str(_car != null), zz, spd])

	if _frames >= 150:
		print("INPUTTEST DONE")
		get_tree().quit()
