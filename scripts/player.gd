extends CharacterBody3D

# Phase 1 player movement.
# Reads keyboard input and moves the cube on the ground plane (XZ).
# Movement uses smooth acceleration / friction so it doesn't feel snappy.
# Touch input on mobile will be wired in later by feeding the same actions.

# -- Tunable parameters (visible in Inspector via @export) --

## Top horizontal speed in units per second.
@export var speed: float = 8.0

## How quickly we ramp up to top speed when input is given.
@export var acceleration: float = 12.0

## How quickly we slow down when no input is given.
@export var friction: float = 14.0


# Default 3D gravity from project settings (falls back to 9.8 if unset).
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)


func _physics_process(delta: float) -> void:
	# 1. Read the four directional actions as a single 2D vector in [-1, 1].
	#    "left/right" maps to X, "forward/back" maps to Y of this vector.
	var input_dir := Input.get_vector(
		"move_left", "move_right",
		"move_forward", "move_back"
	)

	# 2. Translate the 2D input into a horizontal target velocity in 3D.
	#    World axes here: +X is right, +Z is "back" (away from camera).
	var target_horizontal := Vector3(input_dir.x, 0.0, input_dir.y) * speed

	# 3. Smoothly approach the target horizontal velocity.
	#    Use a faster rate when accelerating, slower when stopping (friction).
	var current_horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var rate: float = acceleration if input_dir != Vector2.ZERO else friction
	var next_horizontal := current_horizontal.move_toward(target_horizontal, rate * delta)

	velocity.x = next_horizontal.x
	velocity.z = next_horizontal.z

	# 4. Vertical: apply gravity when airborne; clamp to 0 when grounded
	#    so velocity doesn't accumulate while just sitting on the floor.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	# 5. Apply movement; CharacterBody3D handles collisions automatically.
	move_and_slide()
