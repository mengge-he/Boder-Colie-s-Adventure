class_name Spawner
extends Node2D

@export var enemy_scene: PackedScene
@export var player_path: NodePath
@export var arena_rect: Rect2 = Rect2(Vector2(20, 90), Vector2(500, 820))
@export var start_interval: float = 1.4
@export var minimum_interval: float = 0.35
@export var ramp_duration: float = 90.0

var elapsed: float = 0.0

@onready var spawn_timer: Timer = get_node_or_null("SpawnTimer")

func _ready() -> void:
	if spawn_timer == null:
		return
	spawn_timer.wait_time = start_interval
	spawn_timer.start()

func _process(delta: float) -> void:
	elapsed += delta

func get_spawn_interval(time: float) -> float:
	var t: float = clamp(time / ramp_duration, 0.0, 1.0)
	return lerp(start_interval, minimum_interval, t)

func spawn_enemy() -> void:
	if enemy_scene == null:
		return
	var player := get_node_or_null(player_path)
	var enemy := enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = _pick_edge_position()
	enemy.target = player
	enemy.add_to_group("enemies")

func _pick_edge_position() -> Vector2:
	var side := randi() % 4
	var left := arena_rect.position.x
	var top := arena_rect.position.y
	var right := arena_rect.position.x + arena_rect.size.x
	var bottom := arena_rect.position.y + arena_rect.size.y
	match side:
		0:
			return Vector2(randf_range(left, right), top)
		1:
			return Vector2(randf_range(left, right), bottom)
		2:
			return Vector2(left, randf_range(top, bottom))
		_:
			return Vector2(right, randf_range(top, bottom))

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()
	if spawn_timer == null:
		return
	spawn_timer.wait_time = get_spawn_interval(elapsed)
	spawn_timer.start()
