extends Node

# Starts the car upside-down and checks car.gd's auto-recovery flips it back
# upright within a couple of seconds, so a rollover can never leave the player
# stuck wheels-up.

var _car: VehicleBody3D
var _frames: int = 0


func _ready() -> void:
	_car = _find_vehicle(get_tree().root)


func _find_vehicle(n: Node) -> VehicleBody3D:
	if n is VehicleBody3D:
		return n
	for c in n.get_children():
		var found := _find_vehicle(c)
		if found != null:
			return found
	return null


func _physics_process(_d: float) -> void:
	_frames += 1
	if _frames % 30 == 0 and _car != null:
		var up_y := _car.global_transform.basis.y.y
		print("frame=%d  up_y=%.2f  (%s)" % [
			_frames, up_y, ("upright" if up_y > 0.5 else "flipped")])
	if _frames >= 200:
		print("FLIPTEST DONE")
		get_tree().quit()
