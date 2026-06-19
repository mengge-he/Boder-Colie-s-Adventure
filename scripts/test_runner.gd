extends SceneTree

class DamageTarget:
	extends Node2D

	var health: int = 3
	var damage_count: int = 0

	func take_damage(amount: int) -> void:
		health -= amount
		damage_count += 1

var failures: Array[String] = []

func _init() -> void:
	_check_file_exists("project.godot")
	_check_file_exists("scenes/main.tscn")
	_check_file_exists("scenes/player.tscn")
	_check_project_has_main_scene()
	await _test_player_clamps_to_arena()
	await _test_player_damage_uses_invulnerability()
	await _test_enemy_moves_toward_player()
	await _test_enemy_reapplies_contact_damage_after_cooldown()
	await _test_enemy_damage_and_death_signal()
	await _test_attack_controller_selects_nearest_enemy()
	await _test_attack_orb_hits_target()
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

func _test_enemy_moves_toward_player() -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	if enemy_scene == null:
		failures.append("Cannot load enemy scene")
		return
	var enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	enemy.global_position = Vector2.ZERO
	enemy.target = Node2D.new()
	root.add_child(enemy.target)
	enemy.target.global_position = Vector2(100, 0)
	enemy.update_chase(1.0)
	if enemy.velocity.x <= 0:
		failures.append("Enemy should move toward positive X, velocity was %s" % enemy.velocity)
	enemy.target.queue_free()
	enemy.queue_free()
	await process_frame

func _test_enemy_reapplies_contact_damage_after_cooldown() -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	if enemy_scene == null:
		failures.append("Cannot load enemy scene")
		return
	var enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	var target := DamageTarget.new()
	root.add_child(target)
	enemy.contact_damage = 1
	enemy._on_hurtbox_body_entered(target)
	enemy._on_contact_timer_timeout()
	if target.damage_count != 2 or target.health != 1:
		failures.append("Enemy sustained contact should deal damage twice after cooldown, got %s hits and health %s" % [target.damage_count, target.health])
	target.queue_free()
	enemy.queue_free()
	await process_frame

func _test_enemy_damage_and_death_signal() -> void:
	var enemy_scene = load("res://scenes/enemy.tscn")
	if enemy_scene == null:
		failures.append("Cannot load enemy scene")
		return
	var enemy = enemy_scene.instantiate()
	root.add_child(enemy)
	var deaths := [0]
	var death_payloads: Array[Node] = []
	enemy.died.connect(func(dead_enemy: Node) -> void:
		deaths[0] += 1
		death_payloads.append(dead_enemy)
	)
	enemy.health = 1
	enemy.take_damage(1)
	enemy.take_damage(1)
	if deaths[0] != 1:
		failures.append("Enemy death signal expected once, got %s" % deaths[0])
	if death_payloads.size() != 1 or death_payloads[0] != enemy:
		failures.append("Enemy death signal payload should be enemy instance, got %s" % death_payloads)
	enemy.queue_free()
	await process_frame

func _test_attack_controller_selects_nearest_enemy() -> void:
	var controller_script = load("res://scripts/attack_controller.gd")
	if controller_script == null:
		failures.append("Cannot load attack_controller.gd")
		return
	var controller = Node2D.new()
	controller.set_script(controller_script)
	root.add_child(controller)
	var far_enemy = Node2D.new()
	var near_enemy = Node2D.new()
	root.add_child(far_enemy)
	root.add_child(near_enemy)
	far_enemy.add_to_group("enemies")
	near_enemy.add_to_group("enemies")
	controller.global_position = Vector2.ZERO
	far_enemy.global_position = Vector2(300, 0)
	near_enemy.global_position = Vector2(40, 0)
	var selected = controller.find_nearest_enemy()
	if selected != near_enemy:
		failures.append("AttackController should select nearest enemy")
	controller.queue_free()
	far_enemy.queue_free()
	near_enemy.queue_free()
	await process_frame

func _test_attack_orb_hits_target() -> void:
	var orb_scene = load("res://scenes/attack_orb.tscn")
	var enemy_scene = load("res://scenes/enemy.tscn")
	if orb_scene == null or enemy_scene == null:
		failures.append("Cannot load orb or enemy scene")
		return
	var orb = orb_scene.instantiate()
	var enemy = enemy_scene.instantiate()
	root.add_child(orb)
	root.add_child(enemy)
	orb.global_position = Vector2.ZERO
	enemy.global_position = Vector2(2, 0)
	enemy.health = 1
	orb.set_target(enemy)
	orb.apply_hit_if_close()
	if is_instance_valid(enemy) and enemy.health > 0:
		failures.append("AttackOrb should damage close target")
	orb.queue_free()
	if is_instance_valid(enemy):
		enemy.queue_free()
	await process_frame

func _finish() -> void:
	if failures.is_empty():
		print("TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
