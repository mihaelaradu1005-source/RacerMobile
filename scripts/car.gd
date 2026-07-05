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
@export var max_engine_force: float = 2200.0

## Brake force applied when reversing against forward motion.
@export var max_brake_force: float = 60.0

## Maximum steering angle in radians (~0.45 rad ≈ 26°).
@export var max_steer_angle: float = 0.45

## How fast the wheels turn toward the target steering angle (rad/s of input).
@export var steer_speed: float = 3.0

# The on-screen touch joystick, if present (found by group at runtime).
var _joystick: Node = null


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

	# Reduce steering authority as speed rises so the car doesn't spin out at
	# high speed, while staying nimble when slow. Full angle up to ~easing, down
	# to 35% at high speed.
	var speed := linear_velocity.length()
	var speed_factor := clampf(1.0 - speed / 40.0, 0.35, 1.0)

	# Ease the steering toward the target angle so turns aren't instant.
	# Positive steering turns the car toward +X (driver's right), so pushing the
	# stick right (input.x > 0) maps straight through.
	var target_steer := input.x * max_steer_angle * speed_factor
	steering = move_toward(steering, target_steer, steer_speed * delta)
