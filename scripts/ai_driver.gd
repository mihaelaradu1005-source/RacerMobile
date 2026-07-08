extends PathFollow3D

# Simple, robust AI opponent: rides the racing-line Path3D and slows down for
# corners. It's on rails (follows the curve) rather than a full physics driver,
# which keeps it predictable and impossible to send spinning off the track.
# Looks ahead on the curve; the sharper the upcoming bend, the more it slows.

## Cruising speed on the straights (m/s).
@export var base_speed: float = 20.0

## Minimum speed through the tightest corners (m/s).
@export var min_corner_speed: float = 11.0

## How quickly the AI changes speed (m/s per second).
@export var accel: float = 12.0

## How far ahead (metres) it looks to judge the next corner.
@export var lookahead: float = 12.0

var laps: int = 0

var _speed: float = 0.0
var _prev_ratio: float = 0.0
var _curve: Curve3D


func _ready() -> void:
	add_to_group("ai")
	var path := get_parent() as Path3D
	if path != null:
		_curve = path.curve
	_speed = base_speed


func _physics_process(delta: float) -> void:
	if _curve == null:
		return
	var length := _curve.get_baked_length()

	# Compare the current heading with the heading a little way ahead: if they
	# point the same way it's a straight (go fast), if they diverge it's a corner.
	var here_dir := _dir_at(progress + 1.0, length)
	var ahead_dir := _dir_at(progress + lookahead, length)
	var straightness := clampf(here_dir.dot(ahead_dir), 0.0, 1.0)
	var target := lerpf(min_corner_speed, base_speed, straightness)

	_speed = move_toward(_speed, target, accel * delta)
	progress += _speed * delta

	# progress_ratio wraps 0..1 each lap; a drop means we crossed the line.
	if progress_ratio < _prev_ratio:
		laps += 1
	_prev_ratio = progress_ratio


func _dir_at(offset: float, length: float) -> Vector3:
	var a := _curve.sample_baked(fposmod(offset - 1.0, length))
	var b := _curve.sample_baked(fposmod(offset + 1.0, length))
	var d := b - a
	d.y = 0.0
	if d.length() < 0.001:
		return Vector3(0, 0, 1)
	return d.normalized()
