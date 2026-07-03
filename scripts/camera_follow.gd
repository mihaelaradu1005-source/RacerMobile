extends Camera3D

# Third-person chase camera.
# Stays behind and above the target, swinging around as the target turns so you
# always look where the car is heading. Uses only the target's yaw (heading),
# ignoring suspension pitch/roll, so the view doesn't wobble on bumps. Smoothing
# is frame-rate independent via exp(), so it feels the same at 30 and 60 FPS.

## Node to follow (the car or the cube). Set in the scene.
@export var target_path: NodePath

## How far behind the target the camera sits (metres).
@export var back_distance: float = 8.0

## How high above the target the camera sits (metres).
@export var height: float = 4.0

## How far ahead of the target the camera aims (metres).
@export var look_ahead: float = 3.0

## Aim height above the target's origin (metres).
@export var look_height: float = 1.0

## Position easing: higher = snappier, lower = floatier (1/seconds).
@export var follow_speed: float = 6.0

var _target: Node3D


func _ready() -> void:
	_target = get_node_or_null(target_path)
	# Snap straight to the ideal spot on the first frame (no swoop-in from origin).
	if _target != null:
		var fwd := _flat_forward()
		global_position = _target.global_position - fwd * back_distance + Vector3.UP * height
		look_at(_target.global_position + fwd * look_ahead + Vector3.UP * look_height)


# The target's heading (+Z is "forward"), flattened onto the ground plane.
func _flat_forward() -> Vector3:
	var fwd := _target.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.01:
		return Vector3(0, 0, 1)
	return fwd.normalized()


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	var fwd := _flat_forward()
	var desired := _target.global_position - fwd * back_distance + Vector3.UP * height
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired, weight)
	look_at(_target.global_position + fwd * look_ahead + Vector3.UP * look_height)
