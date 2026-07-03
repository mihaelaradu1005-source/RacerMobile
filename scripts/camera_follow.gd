extends Camera3D

# Third-person follow camera.
# Sits at a fixed offset behind/above the target and eases toward it every
# frame so movement feels smooth instead of rigidly glued. Always looks at
# the target. Frame-rate independent smoothing via exp() so it behaves the
# same at 30 FPS (cheap phone) and 60 FPS (flagship).

## Node to follow (the player). Set in the scene.
@export var target_path: NodePath

## Camera position relative to the target: up and behind (+Y up, +Z toward camera).
@export var offset: Vector3 = Vector3(0.0, 8.0, 12.0)

## Higher = snappier follow, lower = floatier. Units are 1/seconds.
@export var follow_speed: float = 6.0

## Aim slightly above the target's feet so the cube isn't at the frame edge.
@export var look_height: float = 1.0

var _target: Node3D


func _ready() -> void:
	_target = get_node_or_null(target_path)


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	var desired := _target.global_position + offset
	# exp()-based lerp: frame-rate independent easing.
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(desired, weight)
	look_at(_target.global_position + Vector3.UP * look_height)
