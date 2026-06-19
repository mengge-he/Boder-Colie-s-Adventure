class_name GameManager
extends Node

@export var match_duration: float = 120.0
@export var player_path: NodePath
@export var hud_path: NodePath
@export var spawner_path: NodePath

var remaining_time: float = match_duration
var kills: int = 0
var game_state: String = "playing"

func _ready() -> void:
	start_game()
	var player := get_node_or_null(player_path)
	if player != null:
		player.health_changed.connect(on_player_health_changed)
		player.died.connect(on_player_died)
		on_player_health_changed(player.health, player.max_health)
	var hud := get_node_or_null(hud_path)
	if hud != null:
		hud.set_kills(kills)
		hud.set_time(remaining_time)

func _process(delta: float) -> void:
	if game_state != "playing":
		return
	remaining_time = max(remaining_time - delta, 0.0)
	var hud := get_node_or_null(hud_path)
	if hud != null:
		hud.set_time(remaining_time)
	evaluate_timer()

func start_game() -> void:
	remaining_time = match_duration
	kills = 0
	game_state = "playing"
	get_tree().paused = false

func evaluate_timer() -> void:
	if game_state == "playing" and remaining_time <= 0.0:
		win_game()

func win_game() -> void:
	game_state = "won"
	_stop_match("Survived!")

func on_player_died() -> void:
	if game_state == "playing":
		game_state = "lost"
		_stop_match("Defeated")

func on_enemy_died(_enemy: Node) -> void:
	if game_state != "playing":
		return
	kills += 1
	var hud := get_node_or_null(hud_path)
	if hud != null:
		hud.set_kills(kills)

func on_player_health_changed(current: int, maximum: int) -> void:
	var hud := get_node_or_null(hud_path)
	if hud != null:
		hud.set_health(current, maximum)

func _stop_match(message: String) -> void:
	var spawner := get_node_or_null(spawner_path)
	if spawner != null:
		spawner.process_mode = Node.PROCESS_MODE_DISABLED
	var player := get_node_or_null(player_path)
	if player != null:
		if player.has_method("stop_control"):
			player.stop_control()
		var attack_controller := player.get_node_or_null("Hand/AttackController")
		if attack_controller != null and attack_controller.has_method("stop_attacks"):
			attack_controller.stop_attacks()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	for orb in get_tree().get_nodes_in_group("orbs"):
		orb.queue_free()
	var hud := get_node_or_null(hud_path)
	if hud != null:
		hud.show_message(message)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and game_state != "playing":
		get_tree().reload_current_scene()
