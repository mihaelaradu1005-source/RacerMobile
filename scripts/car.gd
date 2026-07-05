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
@export var max_engine_force: float = 1600.0

## Top speed in m/s; above this the engine stops pushing (~18 m/s ≈ 65 km/h).
@export var max_speed: float = 18.0

@export_group("Automatic gearbox")
## Gear ratios, low to high. More gears = smoother stepped acceleration.
@export var gear_ratios: Array[float] = [2.9, 1.9, 1.4, 1.05, 0.82]
## Overall drive ratio multiplier (tunes what speed maps to what RPM).
@export var final_drive: float = 12.0
## Shift up when engine RPM climbs past this.
@export var upshift_rpm: float = 5800.0
## Shift down when engine RPM drops below this.
@export var downshift_rpm: float = 2600.0
## Idle floor and redline ceiling for the simulated engine RPM.
@export var idle_rpm: float = 900.0
@export var max_rpm: float = 6500.0

## Brake force applied when reversing against forward motion.
@export var max_brake_force: float = 60.0

## Maximum steering angle in radians (~0.33 rad ≈ 19°).
@export var max_steer_angle: float = 0.33

## Stick sideways movement below this is treated as "straight" (go-straight aid).
@export var steer_deadzone: float = 0.15

## How fast the wheels turn toward the target steering angle (rad/s of input).
@export var steer_speed: float = 3.0

## Seconds spent upside-down before the car auto-rights itself.
@export var flip_recover_time: float = 2.0

## Tyre grip on normal ground (asphalt). Higher = sticks harder.
@export var asphalt_grip: float = 9.0

## Tyre grip on low-grip surfaces (grass/dirt). Lower = slides more.
@export var grass_grip: float = 3.0

## Rear-wheel grip while the handbrake is held — low so the back slides (drift).
@export var drift_grip: float = 1.8

@export_group("Weight transfer (visual)")
## How much the body pitches per unit of forward acceleration (rad per m/s²).
@export var body_pitch_amount: float = 0.02
## Cap on body pitch in radians (~0.13 ≈ 7°).
@export var max_body_pitch: float = 0.13

# The on-screen touch joystick, if present (found by group at runtime).
var _joystick: Node = null

# The on-screen handbrake/drift button, if present (found by group at runtime).
var _handbrake: Node = null

# How long we've been flipped over (for auto-recovery).
var _upside_time: float = 0.0

# Where the car started, so we can respawn it if it ever falls off the world.
var _spawn_position: Vector3 = Vector3.ZERO

# Cached wheels, so we can adjust their grip per surface each frame.
var _wheels: Array[VehicleWheel3D] = []

# Gearbox state (also read later by the HUD and engine sound).
var _gear: int = 0            # 0-based index into gear_ratios
var _rpm: float = 900.0
var _shift_cooldown: float = 0.0

# Drive wheel radius in metres (matches the VehicleWheel3D wheel_radius).
const WHEEL_RADIUS := 0.35

# Visual body-pitch (weight transfer) state.
var _chassis: Node3D = null
var _prev_forward_speed: float = 0.0
var _body_pitch: float = 0.0


func _ready() -> void:
	_spawn_position = global_position
	for child in get_children():
		if child is VehicleWheel3D:
			_wheels.append(child)
	_chassis = get_node_or_null("Chassis")


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
	_update_surface_grip()

	var input := _get_input()

	# Forward is "stick up", which is negative y in our convention.
	var throttle := -input.y

	# How fast are we already going along our own forward (+Z) axis?
	# (Positive engine_force drives the car toward +Z, so that is "forward".)
	var forward_speed := global_transform.basis.z.dot(linear_velocity)

	# Automatic gearbox: pick a gear and a torque multiplier from engine RPM,
	# so acceleration comes in believable steps instead of one flat pull.
	_update_gearbox(forward_speed, delta)
	var torque := _torque_factor(_rpm)

	# If the driver pushes opposite to current motion, treat it as braking;
	# otherwise it's engine force. This gives a simple, intuitive gas/brake.
	if throttle * forward_speed < -0.1:
		engine_force = 0.0
		brake = max_brake_force
	else:
		engine_force = throttle * max_engine_force * torque
		brake = 0.0

	# Cap the top speed: once we're already at max, stop adding engine force.
	if absf(forward_speed) >= max_speed:
		engine_force = 0.0

	# Reduce steering authority as speed rises so the car doesn't spin out or tip
	# over at high speed, while staying nimble when slow.
	var speed := linear_velocity.length()
	var speed_factor := clampf(1.0 - speed / 35.0, 0.35, 1.0)

	# Small sideways stick offsets read as "straight" so the car tracks straight
	# instead of drifting into a slow circle when the driver mostly wants forward.
	var steer_input := input.x
	if absf(steer_input) < steer_deadzone:
		steer_input = 0.0

	# Ease the steering toward the target angle so turns aren't instant.
	# From the chase camera (behind the car), positive VehicleWheel3D steering
	# turns the car to the LEFT of the screen, so we negate: pushing the stick
	# right (input.x > 0) must steer visually right.
	var target_steer := -steer_input * max_steer_angle * speed_factor
	steering = move_toward(steering, target_steer, steer_speed * delta)

	_update_body_pitch(forward_speed, delta)


func _update_body_pitch(forward_speed: float, delta: float) -> void:
	# Visual-only weight transfer: pitch the body nose-down when slowing and
	# nose-up when accelerating. Wheels stay planted, so it reads like the body
	# rocking on its suspension. Does not affect the physics.
	if _chassis == null or delta <= 0.0:
		return
	var accel := (forward_speed - _prev_forward_speed) / delta
	_prev_forward_speed = forward_speed
	# Nose UP on acceleration means a negative rotation about local X, so negate.
	var target := clampf(-accel * body_pitch_amount, -max_body_pitch, max_body_pitch)
	_body_pitch = lerpf(_body_pitch, target, 1.0 - exp(-8.0 * delta))
	_chassis.rotation.x = _body_pitch


func _update_gearbox(forward_speed: float, delta: float) -> void:
	# Engine RPM implied by how fast the wheels turn in the current gear.
	var v := maxf(forward_speed, 0.0)
	var wheel_rev_per_s := v / (TAU * WHEEL_RADIUS)
	_rpm = clampf(wheel_rev_per_s * 60.0 * gear_ratios[_gear] * final_drive, idle_rpm, max_rpm)

	# Shift with a short cooldown so it can't flutter between two gears.
	_shift_cooldown = maxf(0.0, _shift_cooldown - delta)
	if _shift_cooldown > 0.0:
		return
	if _rpm >= upshift_rpm and _gear < gear_ratios.size() - 1:
		_gear += 1
		_shift_cooldown = 0.4
	elif _rpm <= downshift_rpm and _gear > 0:
		_gear -= 1
		_shift_cooldown = 0.4


func _torque_factor(rpm: float) -> float:
	# Simple torque curve: strongest in the mid-range, weaker near idle/redline.
	return clampf(1.0 - 0.6 * absf(rpm - 4000.0) / 4000.0, 0.35, 1.0)


func _handbrake_held() -> bool:
	if _handbrake == null:
		_handbrake = get_tree().get_first_node_in_group("handbrake")
	return _handbrake != null and _handbrake.pressed


func _update_surface_grip() -> void:
	# Each wheel checks what it's resting on. Bodies in the "low_grip" group
	# (grass/dirt) make that wheel slide; everything else is asphalt grip.
	# Holding the handbrake drops the REAR wheels' grip so the car drifts.
	var handbrake := _handbrake_held()
	for wheel in _wheels:
		var grip := asphalt_grip
		if wheel.is_in_contact():
			var body := wheel.get_contact_body()
			if body != null and body.is_in_group("low_grip"):
				grip = grass_grip
		if handbrake and not wheel.use_as_steering:
			grip = minf(grip, drift_grip)
		wheel.wheel_friction_slip = grip


func _handle_flip_recovery(delta: float) -> void:
	# Safety net: if the car somehow falls off the world, put it back at start.
	if global_position.y < -5.0:
		_respawn()
		return

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


func _respawn() -> void:
	# Return to the starting spot, upright and stationary.
	global_transform = Transform3D(Basis(), _spawn_position + Vector3.UP * 1.0)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
