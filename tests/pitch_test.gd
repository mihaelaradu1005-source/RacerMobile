extends Node

# Checks the visual weight-transfer pitch sign: body should pitch nose-UP while
# accelerating (rotation.x < 0) and nose-DOWN while braking (rotation.x > 0).

var _car: VehicleBody3D
var _joy: Node
var _f: int = 0


func _ready() -> void:
	_joy = get_tree().get_first_node_in_group("joystick")
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
	_f += 1
	var phase := "ACCEL"
	if _joy != null:
		if _f <= 80:
			_joy.output = Vector2(0.0, -1.0)     # accelerate
		else:
			_joy.output = Vector2(0.0, 1.0)      # brake / reverse
			phase = "BRAKE"

	if _f % 20 == 0:
		var chassis: Node3D = _car.get_node_or_null("Chassis")
		var pitch := 0.0
		if chassis != null:
			pitch = rad_to_deg(chassis.rotation.x)
		var kmh := _car.linear_velocity.length() * 3.6
		print("f=%d %s speed=%.1f pitch=%.1f deg (%s)" % [
			_f, phase, kmh, pitch,
			("nose-up" if pitch < -0.3 else ("nose-down" if pitch > 0.3 else "level"))])

	if _f >= 160:
		print("PITCHTEST DONE")
		get_tree().quit()
