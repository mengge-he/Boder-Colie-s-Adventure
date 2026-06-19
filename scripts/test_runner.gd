extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_check_file_exists("project.godot")
	_check_file_exists("scenes/main.tscn")
	_check_file_exists("scenes/player.tscn")
	_check_project_has_main_scene()
	await _test_player_clamps_to_arena()
	await _test_player_damage_uses_invulnerability()
	_finish()

func _check_file_exists(path: String) -> void:
	if not FileAccess.file_exists(path):
		failures.append("Missing file: %s" % path)

func _check_project_has_main_scene() -> void:
	var config := ConfigFile.new()
	var err := config.load("project.godot")
	if err != OK:
		failures.append("Cannot load project.godot")
		return
	var main_scene := str(config.get_value("application", "run/main_scene", ""))
	if main_scene != "res://scenes/main.tscn":
		failures.append("Expected main scene res://scenes/main.tscn, got %s" % main_scene)

func _test_player_clamps_to_arena() -> void:
	var player_scene := load("res://scenes/player.tscn")
	if player_scene == null:
		failures.append("Cannot load player scene")
		return
	var player = player_scene.instantiate()
	root.add_child(player)
	player.arena_rect = Rect2(Vector2.ZERO, Vector2(100, 100))
	player.global_position = Vector2(150, -20)
	player.clamp_to_arena()
	if player.global_position != Vector2(100, 0):
		failures.append("Player clamp expected (100, 0), got %s" % player.global_position)
	player.queue_free()
	await process_frame

func _test_player_damage_uses_invulnerability() -> void:
	var player_scene := load("res://scenes/player.tscn")
	if player_scene == null:
		failures.append("Cannot load player scene")
		return
	var player = player_scene.instantiate()
	root.add_child(player)
	player.max_health = 3
	player.health = 3
	player.take_damage(1)
	player.take_damage(1)
	if player.health != 2:
		failures.append("Player should ignore damage during invulnerability, got health %s" % player.health)
	player.queue_free()
	await process_frame

func _finish() -> void:
	if failures.is_empty():
		print("TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
