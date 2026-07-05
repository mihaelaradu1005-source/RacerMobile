extends Node

# Lap timing for a closed circuit.
# Checkpoints (Area3D) are children of `checkpoints_path`, in track order, with
# index 0 being the start/finish line. The car must trigger them in order; out-
# of-order hits are ignored (so you can't shortcut or drive the wrong way). Each
# time the car crosses the start/finish after a full lap, the lap time is banked
# and the best time updated. Read by the HUD.

@export var checkpoints_path: NodePath

var lap: int = 0            # completed laps
var lap_time: float = 0.0   # time on the current lap (seconds)
var best_time: float = -1.0 # best completed lap, -1 until one is set

var _expected: int = 0
var _running: bool = false
var _count: int = 0


func _ready() -> void:
	add_to_group("race_manager")
	var container := get_node_or_null(checkpoints_path)
	if container == null:
		return
	var kids := container.get_children()
	_count = kids.size()
	for i in kids.size():
		var area := kids[i] as Area3D
		if area != null:
			area.body_entered.connect(_on_checkpoint.bind(i))


func _process(delta: float) -> void:
	if _running:
		lap_time += delta


func _on_checkpoint(body: Node, idx: int) -> void:
	if not (body is VehicleBody3D):
		return
	if idx != _expected:
		return   # wrong order — ignore (prevents shortcuts / wrong-way laps)

	if idx == 0:
		if _running:
			# Crossing the line again completes a lap.
			lap += 1
			if best_time < 0.0 or lap_time < best_time:
				best_time = lap_time
		_running = true
		lap_time = 0.0

	_expected = (idx + 1) % _count
