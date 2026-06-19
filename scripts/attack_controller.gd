class_name AttackController
extends Node2D

@export var orb_scene: PackedScene
@export var attack_interval: float = 0.65
@export var target_range: float = 520.0

@onready var attack_timer: Timer = get_node_or_null("AttackTimer") as Timer

func _ready() -> void:
	if attack_timer == null:
		return
	attack_timer.wait_time = attack_interval
	attack_timer.start()

func find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D:
			continue
		var enemy_node := enemy as Node2D
		var distance := global_position.distance_to(enemy_node.global_position)
		if distance <= target_range and distance < nearest_distance:
			nearest = enemy_node
			nearest_distance = distance
	return nearest

func fire_at_nearest_enemy() -> void:
	if orb_scene == null:
		return
	var target := find_nearest_enemy()
	if target == null:
		return
	var orb := orb_scene.instantiate()
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_tree().root
	parent.add_child(orb)
	orb.global_position = global_position
	orb.set_target(target)

func _on_attack_timer_timeout() -> void:
	fire_at_nearest_enemy()
