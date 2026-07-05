extends Label

# Minimal heads-up display: current speed and gear, read from the car each
# frame. A fuller HUD (lap time, position) comes in Phase 4.

@export var car_path: NodePath

var _car: VehicleBody3D


func _ready() -> void:
	_car = get_node_or_null(car_path)


func _process(_delta: float) -> void:
	if _car == null:
		return
	var kmh := int(round(_car.linear_velocity.length() * 3.6))
	text = "%d km/h   ·   treapta %d" % [kmh, _car._gear + 1]
