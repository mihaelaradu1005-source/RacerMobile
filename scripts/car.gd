extends VehicleBody3D

# Phase 2 raycast vehicle.
# Godot's VehicleBody3D drives 4 VehicleWheel3D children that raycast against
# the ground and apply spring/damper suspension forces. This script only turns
# input into engine force / brake / steering; the physics is handled by the
# engine. Transmission and tire slip come in Phase 3.
#
# Input matches the rest of the game (keyboard + touch joystick):
#   stick up   = accelerate, stick down = reverse/brake
#   stick left/right = steer

## Peak drive force applied to the traction wheels (Newtons-ish).
@export var max_engine_force: float = 1400.0

## Top speed in m/s; above this the engine stops pushing (~18 m/s ≈ 65 km/h).
@export var max_speed: float = 18.0

## Brake force applied when reversing against forward motion.
@export var max_brake_force: float = 60.0

## Maximum steering angle in radians (~0.4 rad ≈ 23°).
@export var max_steer_angle: float = 0.4

## How fast the wheels turn toward the target steering angle (rad/s of input).
@export var steer_speed: float = 3.0

## Seconds spent upside-down before the car auto-rights itself.
@export var flip_recover_time: float = 2.0

# The on-screen touch joystick, if present (found by group at runtime).
var _joystick: Node = null

# How long we've been flipped over (for auto-recovery).
var _upside_time: float = 0.0


func _get_input() -> Vector2:
	# Combine keyboard and touch joystick, clamped so both together stay in range.
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# Look the joystick up lazily: at _ready() time it may not have registered in
	# its group yet (node ready-order), so we fetch it the first time we need it.
	if _joystick == null:
		_joystick = get_tree().get_first_node_in_group("joystick")

	if _joystick != null and _joystick.output != Vector2.ZERO:
		input = (input + _joystick.output).limit_length(1.0)
	return input


func _physics_process(delta: float) -> void:
	_handle_flip_recovery(delta)

	var input := _get_input()

	# Forward is "stick up", which is negative y in our convention.
	var throttle := -input.y

	# How fast are we already going along our own forward (+Z) axis?
	# (Positive engine_force drives the car toward +Z, so that is "forward".)
	var forward_speed := global_transform.basis.z.dot(linear_velocity)

	# If the driver pushes opposite to current motion, treat it as braking;
	# otherwise it's engine force. This gives a simple, intuitive gas/brake.
	if throttle * forward_speed < -0.1:
		engine_force = 0.0
		brake = max_brake_force
	else:
		engine_force = throttle * max_engine_force
		brake = 0.0

	# Cap the top speed: once we're already at max, stop adding engine force.
	if absf(forward_speed) >= max_speed:
		engine_force = 0.0

	# Reduce steering authority as speed rises so the car doesn't spin out or tip
	# over at high speed, while staying nimble when slow.
	var speed := linear_velocity.length()
	var speed_factor := clampf(1.0 - speed / 35.0, 0.35, 1.0)

	# Ease the steering toward the target angle so turns aren't instant.
	# Positive steering turns the car toward +X (driver's right), so pushing the
	# stick right (input.x > 0) maps straight through.
	var target_steer := input.x * max_steer_angle * speed_factor
	steering = move_toward(steering, target_steer, steer_speed * delta)


func _handle_flip_recovery(delta: float) -> void:
	# The car's own "up" vector; if it points downward we're on our roof/side.
	if global_transform.basis.y.y < 0.2:
		_upside_time += delta
		if _upside_time >= flip_recover_time:
			_upright()
			_upside_time = 0.0
	else:
		_upside_time = 0.0


func _upright() -> void:
	# Re-place the car level and slightly lifted, keeping its heading, and clear
	# all momentum so it doesn't immediately roll again.
	var yaw := rotation.y
	global_transform = Transform3D(Basis(Vector3.UP, yaw), global_position + Vector3.UP * 1.0)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
