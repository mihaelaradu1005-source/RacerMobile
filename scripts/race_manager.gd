extends Node

# Lap timing for a closed circuit.
# Checkpoints (Area3D) are children of `checkpoints_path`, in track order, with
# index 0 being the start/finish line. The car must trigger them in order; out-
# of-order hits are ignored (so you can't shortcut or drive the wrong way). Each
# time the car crosses the start/finish after a full lap, the lap time is banked
# and the best time updated. Read by the HUD.

@export var checkpoints_path: NodePath

## Countdown before the opponent is released, so it can't grab a head start.
@export var start_delay: float = 3.0

var started: bool = false
var countdown: float = 0.0

var lap: int = 0            # completed laps
var lap_time: float = 0.0   # time on the current lap (seconds)
var best_time: float = -1.0 # best completed lap, -1 until one is set

var has_opponent: bool = false
var position: int = 1       # 1 = ahead of the AI, 2 = behind

var _expected: int = 0
var _running: bool = false
var _count: int = 0
var _player: VehicleBody3D
var _ai: Node


func _ready() -> void:
	add_to_group("race_manager")
	countdown = start_delay
	_player = _find_vehicle(get_tree().root)
	var container := get_node_or_null(checkpoints_path)
	if container == null:
		return
	var kids := container.get_children()
	_count = kids.size()
	for i in kids.size():
		var area := kids[i] as Area3D
		if area != null:
			area.body_entered.connect(_on_checkpoint.bind(i))


func _find_vehicle(n: Node) -> VehicleBody3D:
	if n is VehicleBody3D:
		return n
	for c in n.get_children():
		var found := _find_vehicle(c)
		if found != null:
			return found
	return null


func _process(delta: float) -> void:
	if not started:
		countdown -= delta
		if countdown <= 0.0:
			countdown = 0.0
			started = true
	if _running:
		lap_time += delta
	_update_position()


func _update_position() -> void:
	if _ai == null:
		_ai = get_tree().get_first_node_in_group("ai")
	if _ai == null or _player == null:
		has_opponent = false
		return
	has_opponent = true
	var path := _ai.get_parent() as Path3D
	if path == null or path.curve == null:
		return
	var length := path.curve.get_baked_length()
	var player_ratio := path.curve.get_closest_offset(_player.global_position) / length
	var player_total := float(lap) + player_ratio
	var ai_total: float = float(_ai.laps) + float(_ai.progress_ratio)
	position = 1 if player_total >= ai_total else 2


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
