extends Node

# Headless self-test for the Phase 2 vehicle under the project's physics engine.
# Applies steady engine force, then reports position, forward speed and how many
# wheels touch the ground. Used to confirm VehicleBody3D actually drives with
# Jolt Physics before building the rest of Phase 2. Run headless:
#   godot --headless --quit-after 200 --path . tests/vehicle_test.tscn

@export var car_path: NodePath

var _car: VehicleBody3D
var _frames: int = 0


func _ready() -> void:
	_car = get_node(car_path)


func _physics_process(_delta: float) -> void:
	_car.engine_force = 260.0     # full throttle
	_frames += 1

	# After a short run-up, steer with a POSITIVE steering value so we can read
	# which way positive steering actually turns the car (driver's right = +X).
	if _frames > 60:
		_car.steering = 0.3

	if _frames % 30 == 0:
		var in_contact := 0
		for child in _car.get_children():
			if child is VehicleWheel3D and child.is_in_contact():
				in_contact += 1
		var fwd_speed := _car.global_transform.basis.z.dot(_car.linear_velocity)
		var yaw_deg := rad_to_deg(_car.rotation.y)
		print("frame=%d  x=%.2f  z=%.2f  fwd_speed=%.2f  yaw=%.1f  wheels=%d" % [
			_frames, _car.global_position.x, _car.global_position.z, fwd_speed, yaw_deg, in_contact
		])

	if _frames >= 240:
		print("SELFTEST DONE")
		get_tree().quit()
