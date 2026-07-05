extends Node

# Feeds synthetic touch events straight into the virtual joystick and prints
# its output, to confirm: up = forward (negative y), right = positive x, and
# releasing resets to zero (no "stuck" state that would make the car circle).

var joy: Control
var step: int = 0


func _ready() -> void:
	joy = get_tree().get_first_node_in_group("joystick")


func _report(label: String) -> void:
	print("%s -> output=(%.2f, %.2f)  finger_index=%d" % [
		label, joy.output.x, joy.output.y, joy._finger_index])


func _physics_process(_d: float) -> void:
	step += 1
	match step:
		2:
			print("joystick size = ", joy.size)
			var t := InputEventScreenTouch.new()
			t.index = 0
			t.pressed = true
			t.position = Vector2(200, 400)   # left half -> place stick here
			joy._input(t)
			_report("press(200,400)")
		4:
			var dr := InputEventScreenDrag.new()
			dr.index = 0
			dr.position = Vector2(200, 250)  # 150 px UP  -> expect forward
			joy._input(dr)
			_report("drag up   ")
		6:
			var dr := InputEventScreenDrag.new()
			dr.index = 0
			dr.position = Vector2(350, 400)  # 150 px RIGHT -> expect +x
			joy._input(dr)
			_report("drag right")
		8:
			var t := InputEventScreenTouch.new()
			t.index = 0
			t.pressed = false
			t.position = Vector2(350, 400)
			joy._input(t)
			_report("release   ")
		10:
			print("JOYTEST DONE")
			get_tree().quit()
