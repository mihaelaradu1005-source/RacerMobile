extends Control

# On-screen round button on the RIGHT side of the screen (the handbrake / drift
# button). Exposes `pressed` (bool), read by car.gd. Drawn with draw_circle so it
# needs no image assets. Touches on the left half are left for the joystick.

## Radius of the touchable/visible button in pixels.
@export var button_radius: float = 120.0

## Distance of the button centre from the bottom-right corner.
@export var margin: float = 160.0

## Label shown on the button.
@export var caption: String = "DRIFT"

var pressed: bool = false

var _finger_index: int = -1


func _enter_tree() -> void:
	# Register early so the car can find us regardless of node ready-order.
	add_to_group("handbrake")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _center() -> Vector2:
	return Vector2(size.x - margin, size.y - margin)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _finger_index == -1 and event.position.distance_to(_center()) <= button_radius:
			_finger_index = event.index
			pressed = true
			queue_redraw()
		elif not event.pressed and event.index == _finger_index:
			_finger_index = -1
			pressed = false
			queue_redraw()


func _draw() -> void:
	var c := _center()
	var fill := Color(0.95, 0.5, 0.2, 0.55) if pressed else Color(1, 1, 1, 0.12)
	draw_circle(c, button_radius, fill)
	draw_circle(c, button_radius, Color(1, 1, 1, 0.3), false, 3.0)
	var font := ThemeDB.fallback_font
	draw_string(font, c + Vector2(-button_radius, 12), caption,
		HORIZONTAL_ALIGNMENT_CENTER, button_radius * 2.0, 32, Color(1, 1, 1, 0.85))
