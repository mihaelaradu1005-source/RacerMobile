extends Control

# On-screen virtual joystick for touch devices.
# Lives on the LEFT half of the screen. Touch anywhere in that half to place
# the stick under your finger, then drag to steer. Releasing recenters to zero.
#
# Exposes `output` as a Vector2 in [-1, 1] that matches the keyboard convention
# used by player.gd: x = right(+)/left(-), y = back(+)/forward(-). So pushing
# the finger UP the screen produces a negative y == "forward", same as W.
#
# Drawn entirely with draw_circle() — no image assets required.

## Max distance (px) the knob can travel from its center before clamping.
@export var max_radius: float = 130.0

## Fraction of travel ignored near the center so a resting thumb reads as zero.
@export var deadzone: float = 0.15

## Base ring color (semi-transparent) shown while the stick is active.
@export var base_color: Color = Color(1, 1, 1, 0.15)

## Knob color (more opaque) shown while the stick is active.
@export var knob_color: Color = Color(1, 1, 1, 0.35)

# Current steering value read by player.gd. Zero when the finger is up.
var output: Vector2 = Vector2.ZERO

var _finger_index: int = -1        # which touch/drag we are tracking (-1 = none)
var _center: Vector2 = Vector2.ZERO # where the stick was placed
var _knob: Vector2 = Vector2.ZERO   # current knob position (clamped)


func _ready() -> void:
	# Let player.gd find us without hard-wiring a node path in the scene.
	add_to_group("joystick")
	# We read input directly via _input(), so ignore normal GUI mouse routing.
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _is_in_left_half(pos: Vector2) -> bool:
	# Only the left half of the screen activates the joystick; the right half
	# is reserved for future action buttons (accelerate/brake in later phases).
	return pos.x < size.x * 0.5


func _input(event: InputEvent) -> void:
	# --- Finger pressed down ---
	if event is InputEventScreenTouch:
		if event.pressed and _finger_index == -1 and _is_in_left_half(event.position):
			_finger_index = event.index
			_center = event.position
			_knob = event.position
			_update_output()
			queue_redraw()
		elif not event.pressed and event.index == _finger_index:
			# Finger lifted: reset.
			_finger_index = -1
			output = Vector2.ZERO
			queue_redraw()

	# --- Finger dragged ---
	elif event is InputEventScreenDrag and event.index == _finger_index:
		var offset: Vector2 = event.position - _center
		_knob = _center + offset.limit_length(max_radius)
		_update_output()
		queue_redraw()


func _update_output() -> void:
	var raw := (_knob - _center) / max_radius   # in [-1, 1]
	if raw.length() < deadzone:
		output = Vector2.ZERO
	else:
		output = raw


func _draw() -> void:
	if _finger_index == -1:
		return
	draw_circle(_center, max_radius, base_color)
	draw_circle(_knob, max_radius * 0.45, knob_color)
