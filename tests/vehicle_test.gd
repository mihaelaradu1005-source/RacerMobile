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
	_frames += 1

	# Full throttle throughout, using the car's own tuned peak force.
	_car.engine_force = _car.max_engine_force

	# Phase A (straight) then Phase B: full steer, to check it makes a controlled
	# arc rather than an instant spin-out ("donut").
	var phase := "STRAIGHT"
	if _frames > 180:
		_car.steering = _car.max_steer_angle
		phase = "TURNING"

	if _frames % 30 == 0:
		var speed_kmh := _car.linear_velocity.length() * 3.6
		var yaw_deg := rad_to_deg(_car.rotation.y)
		print("frame=%d  %s  speed=%.1f km/h  x=%.1f  z=%.1f  yaw=%.0f" % [
			_frames, phase, speed_kmh, _car.global_position.x, _car.global_position.z, yaw_deg
		])

	if _frames >= 330:
		print("SELFTEST DONE")
		get_tree().quit()
