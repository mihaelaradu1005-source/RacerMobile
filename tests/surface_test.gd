extends Node

# Verifies surface-aware grip: a car resting on a "low_grip" (grass) body should
# have its wheels set to the low grass grip, not the asphalt grip.

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
	if _frames == 60 and _car != null:
		for child in _car.get_children():
			if child is VehicleWheel3D:
				var body_name := "none"
				var low := false
				if child.is_in_contact() and child.get_contact_body() != null:
					var b: Node3D = child.get_contact_body()
					body_name = b.name
					low = b.is_in_group("low_grip")
				print("%s: friction=%.1f  on=%s  low_grip=%s" % [
					child.name, child.wheel_friction_slip, body_name, str(low)])
	if _frames >= 70:
		print("SURFACETEST DONE")
		get_tree().quit()
