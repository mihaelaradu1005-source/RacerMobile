extends Label

# Heads-up display: speed and gear, plus lap number, current lap time and best
# lap time when a race manager is present.

@export var car_path: NodePath

var _car: VehicleBody3D


func _ready() -> void:
	_car = get_node_or_null(car_path)


func _fmt_time(t: float) -> String:
	if t < 0.0:
		return "--"
	return "%.2f s" % t


func _process(_delta: float) -> void:
	if _car == null:
		return
	var kmh := int(round(_car.linear_velocity.length() * 3.6))
	var line1 := "%d km/h   ·   treapta %d" % [kmh, _car._gear + 1]

	var mgr := get_tree().get_first_node_in_group("race_manager")
	if mgr == null:
		text = line1
		return
	text = "%s\nTur %d   %s   ·   record %s" % [
		line1, mgr.lap + 1, _fmt_time(mgr.lap_time), _fmt_time(mgr.best_time)]
