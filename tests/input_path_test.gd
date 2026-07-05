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

	# Simulate a thumb on the stick: first straight up (forward) to build speed,
	# then up-and-right (forward + steer) to check turning is controlled.
	var phase := "FORWARD"
	if _joy != null:
		if _frames <= 120:
			_joy.output = Vector2(0.0, -1.0)
		else:
			_joy.output = Vector2(0.7, -0.7)
			phase = "FWD+RIGHT"

	if _frames % 30 == 0:
		var kmh := 0.0
		var xx := 0.0
		var zz := 0.0
		var yaw := 0.0
		if _car != null:
			kmh = _car.linear_velocity.length() * 3.6
			xx = _car.global_position.x
			zz = _car.global_position.z
			yaw = rad_to_deg(_car.rotation.y)
		print("frame=%d  %s  speed=%.1f km/h  x=%.1f  z=%.1f  yaw=%.0f" % [
			_frames, phase, kmh, xx, zz, yaw])

	if _frames >= 300:
		print("INPUTTEST DONE")
		get_tree().quit()
