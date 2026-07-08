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
	if not mgr.started:
		# Show a big 3-2-1 style countdown before the opponent is released.
		text = "%s\nStart în %d..." % [line1, int(ceil(mgr.countdown))]
		return
	var line2 := "Tur %d   %s   ·   record %s" % [
		mgr.lap + 1, _fmt_time(mgr.lap_time), _fmt_time(mgr.best_time)]
	if mgr.has_opponent:
		line2 += "   ·   locul P%d" % mgr.position
	text = "%s\n%s" % [line1, line2]
