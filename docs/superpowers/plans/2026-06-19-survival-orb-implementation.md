# 首版生存追踪球 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first playable Godot 4.x prototype for 《边牧的牧羊冒险》: a top-down survival game where an anthropomorphic border collie survives timed waves of cattle and sheep using automatic homing attack orbs.

**Architecture:** The project uses focused Godot scenes with one script per gameplay responsibility. `GameManager` owns match state and countdown, `Player` owns movement and health, `Enemy` owns pursuit/contact damage, `AttackController` spawns `AttackOrb` instances, and `Spawner` controls enemy pressure.

**Tech Stack:** Godot 4.x, GDScript, `.tscn` scenes, headless Godot verification where available, lightweight GDScript unit-style checks through a custom runner.

---

## File Structure

- Create `project.godot`: Godot project configuration, main scene, input actions.
- Create `scenes/main.tscn`: root game scene with camera, arena, player, managers, HUD, and timers.
- Create `scenes/player.tscn`: reusable player scene.
- Create `scenes/enemy.tscn`: reusable enemy scene.
- Create `scenes/attack_orb.tscn`: reusable homing projectile scene.
- Create `scenes/hud.tscn`: HUD scene for time, health, kills, and win/lose messages.
- Create `scripts/game_manager.gd`: countdown, win/lose flow, score state.
- Create `scripts/player.gd`: movement, boundary clamping, health, invulnerability.
- Create `scripts/enemy.gd`: chase behavior, contact damage, damage/death events.
- Create `scripts/attack_controller.gd`: attack cadence and target selection.
- Create `scripts/attack_orb.gd`: homing movement and hit handling.
- Create `scripts/spawner.gd`: enemy spawn positions and pressure ramp.
- Create `scripts/hud.gd`: UI update API.
- Create `scripts/test_runner.gd`: headless verification entrypoint.
- Create `docs/development/runbook.md`: how to run, test, and inspect the prototype.
- Modify `docs/index.md`: link the runbook and this plan.

## Task 1: Godot Project Skeleton

**Files:**
- Create: `project.godot`
- Create: `scenes/main.tscn`
- Create: `scripts/test_runner.gd`
- Modify: `docs/index.md`

- [ ] **Step 1: Write the failing project-structure check**

Create `scripts/test_runner.gd`:

```gdscript
extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_check_file_exists("project.godot")
	_check_file_exists("scenes/main.tscn")
	_check_project_has_main_scene()
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

func _finish() -> void:
	if failures.is_empty():
		print("TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
```

- [ ] **Step 2: Run the check and verify it fails**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: FAIL because `project.godot` and `scenes/main.tscn` do not exist yet. If `godot` is not on PATH, record that verification is blocked and continue only after installing or locating Godot 4.x.

- [ ] **Step 3: Create minimal project configuration**

Create `project.godot`:

```ini
; Engine configuration file.
; It is best edited using the editor UI and not directly,
; since the parameters that go here are not all obvious.
;
; Format:
;   [section]
;   param=value

config_version=5

[application]

config/name="边牧的牧羊冒险"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("4.2", "Forward Plus")

[display]

window/size/viewport_width=540
window/size/viewport_height=960
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[input]

move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":65,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194319,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":68,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194321,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":87,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194320,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":83,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":4194322,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
restart={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":82,"physical_keycode":0,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
```

Create `scenes/main.tscn`:

```ini
[gd_scene format=3 uid="uid://main_survival_scene"]

[node name="Main" type="Node2D"]
```

- [ ] **Step 4: Run the check and verify it passes**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: PASS with `TESTS PASSED`.

- [ ] **Step 5: Commit**

```powershell
git add project.godot scenes/main.tscn scripts/test_runner.gd docs/index.md
git commit -m "chore: add godot project skeleton"
```

## Task 2: Player Movement and Health

**Files:**
- Create: `scripts/player.gd`
- Create: `scenes/player.tscn`
- Modify: `scripts/test_runner.gd`
- Modify: `scenes/main.tscn`

- [ ] **Step 1: Write failing player behavior tests**

Replace `scripts/test_runner.gd` with:

```gdscript
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
	var player := player_scene.instantiate()
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
	var player := player_scene.instantiate()
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
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: FAIL because `scenes/player.tscn` and `scripts/player.gd` do not exist.

- [ ] **Step 3: Implement minimal player scene and script**

Create `scripts/player.gd`:

```gdscript
class_name Player
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal died

@export var speed: float = 260.0
@export var max_health: int = 5
@export var invulnerability_time: float = 0.8
@export var arena_rect: Rect2 = Rect2(Vector2(20, 90), Vector2(500, 820))

var health: int = max_health
var invulnerable: bool = false

@onready var body: Polygon2D = $Body
@onready var invulnerability_timer: Timer = $InvulnerabilityTimer

func _ready() -> void:
	health = max_health
	invulnerability_timer.wait_time = invulnerability_time
	health_changed.emit(health, max_health)

func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * speed
	move_and_slide()
	clamp_to_arena()
	if input_vector.length() > 0.01:
		body.scale.x = -1.0 if input_vector.x < -0.01 else 1.0

func clamp_to_arena() -> void:
	global_position = global_position.clamp(arena_rect.position, arena_rect.position + arena_rect.size)

func take_damage(amount: int) -> void:
	if invulnerable or health <= 0:
		return
	health = max(health - amount, 0)
	health_changed.emit(health, max_health)
	if health <= 0:
		died.emit()
		return
	invulnerable = true
	body.modulate = Color(1.0, 0.45, 0.45, 0.75)
	invulnerability_timer.start()

func _on_invulnerability_timer_timeout() -> void:
	invulnerable = false
	body.modulate = Color.WHITE
```

Create `scenes/player.tscn`:

```ini
[gd_scene load_steps=4 format=3 uid="uid://player_scene"]

[ext_resource type="Script" path="res://scripts/player.gd" id="1_player"]

[sub_resource type="CapsuleShape2D" id="CapsuleShape2D_player"]
radius = 17.0
height = 46.0

[node name="Player" type="CharacterBody2D"]
collision_layer = 1
collision_mask = 2
script = ExtResource("1_player")

[node name="Body" type="Polygon2D" parent="."]
color = Color(0.95, 0.95, 0.9, 1)
polygon = PackedVector2Array(-12, -24, 12, -24, 18, 4, 8, 28, -8, 28, -18, 4)

[node name="FacePatch" type="Polygon2D" parent="."]
color = Color(0.05, 0.05, 0.05, 1)
polygon = PackedVector2Array(-12, -24, 4, -22, 8, -4, -10, 0)

[node name="Hand" type="Polygon2D" parent="."]
position = Vector2(18, -2)
color = Color(0.98, 0.78, 0.52, 1)
polygon = PackedVector2Array(-4, -4, 6, -4, 6, 4, -4, 4)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CapsuleShape2D_player")

[node name="InvulnerabilityTimer" type="Timer" parent="."]
one_shot = true

[connection signal="timeout" from="InvulnerabilityTimer" to="." method="_on_invulnerability_timer_timeout"]
```

Modify `scenes/main.tscn`:

```ini
[gd_scene load_steps=2 format=3 uid="uid://main_survival_scene"]

[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="1_player"]

[node name="Main" type="Node2D"]

[node name="Grass" type="ColorRect" parent="."]
offset_right = 540.0
offset_bottom = 960.0
color = Color(0.28, 0.38, 0.18, 1)

[node name="Player" parent="." instance=ExtResource("1_player")]
position = Vector2(270, 520)
```

- [ ] **Step 4: Run tests and verify they pass**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: PASS with `TESTS PASSED`.

- [ ] **Step 5: Commit**

```powershell
git add scripts/player.gd scenes/player.tscn scenes/main.tscn scripts/test_runner.gd
git commit -m "feat: add player movement and health"
```

## Task 3: Enemy Pursuit and Damage

**Files:**
- Create: `scripts/enemy.gd`
- Create: `scenes/enemy.tscn`
- Modify: `scripts/test_runner.gd`
- Modify: `scenes/main.tscn`

- [ ] **Step 1: Write failing enemy tests**

Append these calls before `_finish()` in `_init()` inside `scripts/test_runner.gd`:

```gdscript
	await _test_enemy_moves_toward_player()
	await _test_enemy_damage_and_death_signal()
```

Append these functions before `_finish()`:

```gdscript
func _test_enemy_moves_toward_player() -> void:
	var enemy_scene := load("res://scenes/enemy.tscn")
	if enemy_scene == null:
		failures.append("Cannot load enemy scene")
		return
	var enemy := enemy_scene.instantiate()
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

func _test_enemy_damage_and_death_signal() -> void:
	var enemy_scene := load("res://scenes/enemy.tscn")
	if enemy_scene == null:
		failures.append("Cannot load enemy scene")
		return
	var enemy := enemy_scene.instantiate()
	root.add_child(enemy)
	var deaths := 0
	enemy.died.connect(func(_enemy: Node) -> void: deaths += 1)
	enemy.health = 1
	enemy.take_damage(1)
	if deaths != 1:
		failures.append("Enemy death signal expected once, got %s" % deaths)
	enemy.queue_free()
	await process_frame
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: FAIL because `scenes/enemy.tscn` does not exist.

- [ ] **Step 3: Implement enemy scene and script**

Create `scripts/enemy.gd`:

```gdscript
class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)

@export var speed: float = 95.0
@export var max_health: int = 1
@export var contact_damage: int = 1
@export var contact_cooldown: float = 0.5

var health: int = max_health
var target: Node2D
var can_deal_contact_damage: bool = true

@onready var body: Polygon2D = $Body
@onready var contact_timer: Timer = $ContactTimer

func _ready() -> void:
	health = max_health
	contact_timer.wait_time = contact_cooldown

func _physics_process(delta: float) -> void:
	update_chase(delta)
	move_and_slide()

func update_chase(_delta: float) -> void:
	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		return
	var direction := global_position.direction_to(target.global_position)
	velocity = direction * speed
	if abs(direction.x) > 0.01:
		body.scale.x = -1.0 if direction.x < 0.0 else 1.0

func take_damage(amount: int) -> void:
	health = max(health - amount, 0)
	body.modulate = Color(1.0, 0.75, 0.45, 1.0)
	if health <= 0:
		died.emit(self)
		queue_free()

func _on_hurtbox_body_entered(body_node: Node2D) -> void:
	if can_deal_contact_damage and body_node.has_method("take_damage"):
		body_node.take_damage(contact_damage)
		can_deal_contact_damage = false
		contact_timer.start()

func _on_contact_timer_timeout() -> void:
	can_deal_contact_damage = true
```

Create `scenes/enemy.tscn`:

```ini
[gd_scene load_steps=4 format=3 uid="uid://enemy_scene"]

[ext_resource type="Script" path="res://scripts/enemy.gd" id="1_enemy"]

[sub_resource type="CircleShape2D" id="CircleShape2D_enemy"]
radius = 20.0

[node name="Enemy" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 1
script = ExtResource("1_enemy")

[node name="Body" type="Polygon2D" parent="."]
color = Color(0.12, 0.1, 0.08, 1)
polygon = PackedVector2Array(-24, -12, 14, -18, 26, 0, 14, 18, -24, 12)

[node name="Patch" type="Polygon2D" parent="."]
color = Color(0.95, 0.9, 0.82, 1)
polygon = PackedVector2Array(-12, -10, 8, -12, 14, 2, 0, 10, -16, 4)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_enemy")

[node name="Hurtbox" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 1

[node name="CollisionShape2D" type="CollisionShape2D" parent="Hurtbox"]
shape = SubResource("CircleShape2D_enemy")

[node name="ContactTimer" type="Timer" parent="."]
one_shot = true

[connection signal="body_entered" from="Hurtbox" to="." method="_on_hurtbox_body_entered"]
[connection signal="timeout" from="ContactTimer" to="." method="_on_contact_timer_timeout"]
```

- [ ] **Step 4: Run tests and verify they pass**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: PASS with `TESTS PASSED`.

- [ ] **Step 5: Commit**

```powershell
git add scripts/enemy.gd scenes/enemy.tscn scripts/test_runner.gd scenes/main.tscn
git commit -m "feat: add pursuing enemy"
```

## Task 4: Homing Attack Orb and Attack Controller

**Files:**
- Create: `scripts/attack_orb.gd`
- Create: `scripts/attack_controller.gd`
- Create: `scenes/attack_orb.tscn`
- Modify: `scenes/player.tscn`
- Modify: `scripts/test_runner.gd`

- [ ] **Step 1: Write failing attack tests**

Append these calls before `_finish()` in `_init()`:

```gdscript
	await _test_attack_controller_selects_nearest_enemy()
	await _test_attack_orb_hits_target()
```

Append these functions before `_finish()`:

```gdscript
func _test_attack_controller_selects_nearest_enemy() -> void:
	var controller_script := load("res://scripts/attack_controller.gd")
	if controller_script == null:
		failures.append("Cannot load attack_controller.gd")
		return
	var controller := Node2D.new()
	controller.set_script(controller_script)
	root.add_child(controller)
	var far_enemy := Node2D.new()
	var near_enemy := Node2D.new()
	root.add_child(far_enemy)
	root.add_child(near_enemy)
	far_enemy.add_to_group("enemies")
	near_enemy.add_to_group("enemies")
	controller.global_position = Vector2.ZERO
	far_enemy.global_position = Vector2(300, 0)
	near_enemy.global_position = Vector2(40, 0)
	var selected := controller.find_nearest_enemy()
	if selected != near_enemy:
		failures.append("AttackController should select nearest enemy")
	controller.queue_free()
	far_enemy.queue_free()
	near_enemy.queue_free()
	await process_frame

func _test_attack_orb_hits_target() -> void:
	var orb_scene := load("res://scenes/attack_orb.tscn")
	var enemy_scene := load("res://scenes/enemy.tscn")
	if orb_scene == null or enemy_scene == null:
		failures.append("Cannot load orb or enemy scene")
		return
	var orb := orb_scene.instantiate()
	var enemy := enemy_scene.instantiate()
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
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: FAIL because `attack_controller.gd` and `attack_orb.tscn` do not exist.

- [ ] **Step 3: Implement attack orb**

Create `scripts/attack_orb.gd`:

```gdscript
class_name AttackOrb
extends Area2D

@export var speed: float = 420.0
@export var damage: int = 1
@export var hit_distance: float = 18.0
@export var lifetime: float = 2.5

var target: Node2D

@onready var life_timer: Timer = $LifeTimer

func _ready() -> void:
	life_timer.wait_time = lifetime
	life_timer.start()

func set_target(new_target: Node2D) -> void:
	target = new_target

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	var direction := global_position.direction_to(target.global_position)
	global_position += direction * speed * delta
	rotation = direction.angle()
	apply_hit_if_close()

func apply_hit_if_close() -> void:
	if not is_instance_valid(target):
		queue_free()
		return
	if global_position.distance_to(target.global_position) <= hit_distance:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()

func _on_life_timer_timeout() -> void:
	queue_free()
```

Create `scenes/attack_orb.tscn`:

```ini
[gd_scene load_steps=4 format=3 uid="uid://attack_orb_scene"]

[ext_resource type="Script" path="res://scripts/attack_orb.gd" id="1_orb"]

[sub_resource type="CircleShape2D" id="CircleShape2D_orb"]
radius = 8.0

[node name="AttackOrb" type="Area2D"]
collision_layer = 4
collision_mask = 2
script = ExtResource("1_orb")

[node name="Glow" type="Polygon2D" parent="."]
color = Color(1, 0.82, 0.26, 1)
polygon = PackedVector2Array(9, 0, 4, 7, -4, 7, -9, 0, -4, -7, 4, -7)

[node name="Tail" type="Polygon2D" parent="."]
position = Vector2(-10, 0)
color = Color(1, 0.92, 0.45, 0.45)
polygon = PackedVector2Array(0, -4, -18, 0, 0, 4)

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_orb")

[node name="LifeTimer" type="Timer" parent="."]
one_shot = true

[connection signal="timeout" from="LifeTimer" to="." method="_on_life_timer_timeout"]
```

- [ ] **Step 4: Implement attack controller on player**

Create `scripts/attack_controller.gd`:

```gdscript
class_name AttackController
extends Node2D

@export var orb_scene: PackedScene
@export var attack_interval: float = 0.65
@export var target_range: float = 520.0

@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	attack_timer.wait_time = attack_interval
	attack_timer.start()

func find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D:
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= target_range and distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest

func fire_at_nearest_enemy() -> void:
	if orb_scene == null:
		return
	var target := find_nearest_enemy()
	if target == null:
		return
	var orb := orb_scene.instantiate()
	get_tree().current_scene.add_child(orb)
	orb.global_position = global_position
	orb.set_target(target)

func _on_attack_timer_timeout() -> void:
	fire_at_nearest_enemy()
```

Modify `scenes/player.tscn`:

```ini
[gd_scene load_steps=6 format=3 uid="uid://player_scene"]

[ext_resource type="Script" path="res://scripts/player.gd" id="1_player"]
[ext_resource type="Script" path="res://scripts/attack_controller.gd" id="2_attack_controller"]
[ext_resource type="PackedScene" path="res://scenes/attack_orb.tscn" id="3_attack_orb"]

[sub_resource type="CapsuleShape2D" id="CapsuleShape2D_player"]
radius = 17.0
height = 46.0

[node name="Player" type="CharacterBody2D"]
collision_layer = 1
collision_mask = 2
script = ExtResource("1_player")

[node name="Body" type="Polygon2D" parent="."]
color = Color(0.95, 0.95, 0.9, 1)
polygon = PackedVector2Array(-12, -24, 12, -24, 18, 4, 8, 28, -8, 28, -18, 4)

[node name="FacePatch" type="Polygon2D" parent="."]
color = Color(0.05, 0.05, 0.05, 1)
polygon = PackedVector2Array(-12, -24, 4, -22, 8, -4, -10, 0)

[node name="Hand" type="Polygon2D" parent="."]
position = Vector2(18, -2)
color = Color(0.98, 0.78, 0.52, 1)
polygon = PackedVector2Array(-4, -4, 6, -4, 6, 4, -4, 4)

[node name="AttackController" type="Node2D" parent="Hand"]
script = ExtResource("2_attack_controller")
orb_scene = ExtResource("3_attack_orb")

[node name="AttackTimer" type="Timer" parent="Hand/AttackController"]

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CapsuleShape2D_player")

[node name="InvulnerabilityTimer" type="Timer" parent="."]
one_shot = true

[connection signal="timeout" from="InvulnerabilityTimer" to="." method="_on_invulnerability_timer_timeout"]
[connection signal="timeout" from="Hand/AttackController/AttackTimer" to="Hand/AttackController" method="_on_attack_timer_timeout"]
```

- [ ] **Step 5: Run tests and verify they pass**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: PASS with `TESTS PASSED`.

- [ ] **Step 6: Commit**

```powershell
git add scripts/attack_orb.gd scripts/attack_controller.gd scenes/attack_orb.tscn scenes/player.tscn scripts/test_runner.gd
git commit -m "feat: add homing attack orb"
```

## Task 5: Spawner and Pressure Ramp

**Files:**
- Create: `scripts/spawner.gd`
- Modify: `scenes/main.tscn`
- Modify: `scripts/test_runner.gd`

- [ ] **Step 1: Write failing spawner tests**

Append this call before `_finish()` in `_init()`:

```gdscript
	await _test_spawner_interval_decreases_over_time()
```

Append this function before `_finish()`:

```gdscript
func _test_spawner_interval_decreases_over_time() -> void:
	var spawner_script := load("res://scripts/spawner.gd")
	if spawner_script == null:
		failures.append("Cannot load spawner.gd")
		return
	var spawner := Node2D.new()
	spawner.set_script(spawner_script)
	root.add_child(spawner)
	var early := spawner.get_spawn_interval(0.0)
	var late := spawner.get_spawn_interval(60.0)
	if late >= early:
		failures.append("Spawner interval should decrease over time, early %s late %s" % [early, late])
	spawner.queue_free()
	await process_frame
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: FAIL because `scripts/spawner.gd` does not exist.

- [ ] **Step 3: Implement spawner**

Create `scripts/spawner.gd`:

```gdscript
class_name Spawner
extends Node2D

@export var enemy_scene: PackedScene
@export var player_path: NodePath
@export var arena_rect: Rect2 = Rect2(Vector2(20, 90), Vector2(500, 820))
@export var start_interval: float = 1.4
@export var minimum_interval: float = 0.35
@export var ramp_duration: float = 90.0

var elapsed: float = 0.0

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	spawn_timer.wait_time = start_interval
	spawn_timer.start()

func _process(delta: float) -> void:
	elapsed += delta

func get_spawn_interval(time: float) -> float:
	var t := clamp(time / ramp_duration, 0.0, 1.0)
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
	spawn_timer.wait_time = get_spawn_interval(elapsed)
	spawn_timer.start()
```

Modify `scenes/main.tscn`:

```ini
[gd_scene load_steps=4 format=3 uid="uid://main_survival_scene"]

[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="1_player"]
[ext_resource type="PackedScene" path="res://scenes/enemy.tscn" id="2_enemy"]
[ext_resource type="Script" path="res://scripts/spawner.gd" id="3_spawner"]

[node name="Main" type="Node2D"]

[node name="Grass" type="ColorRect" parent="."]
offset_right = 540.0
offset_bottom = 960.0
color = Color(0.28, 0.38, 0.18, 1)

[node name="Player" parent="." instance=ExtResource("1_player")]
position = Vector2(270, 520)

[node name="Spawner" type="Node2D" parent="."]
script = ExtResource("3_spawner")
enemy_scene = ExtResource("2_enemy")
player_path = NodePath("../Player")

[node name="SpawnTimer" type="Timer" parent="Spawner"]

[connection signal="timeout" from="Spawner/SpawnTimer" to="Spawner" method="_on_spawn_timer_timeout"]
```

- [ ] **Step 4: Run tests and verify they pass**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: PASS with `TESTS PASSED`.

- [ ] **Step 5: Commit**

```powershell
git add scripts/spawner.gd scenes/main.tscn scripts/test_runner.gd
git commit -m "feat: add enemy spawner"
```

## Task 6: Game Manager, HUD, and Win/Lose Flow

**Files:**
- Create: `scripts/game_manager.gd`
- Create: `scripts/hud.gd`
- Create: `scenes/hud.tscn`
- Modify: `scenes/main.tscn`
- Modify: `scripts/test_runner.gd`

- [ ] **Step 1: Write failing game-state tests**

Append these calls before `_finish()` in `_init()`:

```gdscript
	await _test_game_manager_win_and_loss_states()
	await _test_hud_updates_labels()
```

Append these functions before `_finish()`:

```gdscript
func _test_game_manager_win_and_loss_states() -> void:
	var manager_script := load("res://scripts/game_manager.gd")
	if manager_script == null:
		failures.append("Cannot load game_manager.gd")
		return
	var manager := Node.new()
	manager.set_script(manager_script)
	root.add_child(manager)
	manager.remaining_time = 0.0
	manager.evaluate_timer()
	if manager.game_state != "won":
		failures.append("GameManager should enter won state when timer reaches zero")
	manager.start_game()
	manager.on_player_died()
	if manager.game_state != "lost":
		failures.append("GameManager should enter lost state when player dies")
	manager.queue_free()
	await process_frame

func _test_hud_updates_labels() -> void:
	var hud_scene := load("res://scenes/hud.tscn")
	if hud_scene == null:
		failures.append("Cannot load hud scene")
		return
	var hud := hud_scene.instantiate()
	root.add_child(hud)
	hud.set_time(42.8)
	hud.set_health(2, 5)
	hud.set_kills(7)
	if hud.get_node("TimeLabel").text != "Time 43":
		failures.append("HUD time label did not update")
	if hud.get_node("HealthLabel").text != "HP 2/5":
		failures.append("HUD health label did not update")
	if hud.get_node("KillsLabel").text != "Kills 7":
		failures.append("HUD kills label did not update")
	hud.queue_free()
	await process_frame
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: FAIL because `game_manager.gd` and `hud.tscn` do not exist.

- [ ] **Step 3: Implement GameManager**

Create `scripts/game_manager.gd`:

```gdscript
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

func on_enemy_died(_enemy: Enemy) -> void:
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
```

- [ ] **Step 4: Implement HUD**

Create `scripts/hud.gd`:

```gdscript
class_name HUD
extends CanvasLayer

@onready var time_label: Label = $TimeLabel
@onready var health_label: Label = $HealthLabel
@onready var kills_label: Label = $KillsLabel
@onready var message_label: Label = $MessageLabel

func set_time(value: float) -> void:
	time_label.text = "Time %d" % ceili(value)

func set_health(current: int, maximum: int) -> void:
	health_label.text = "HP %d/%d" % [current, maximum]

func set_kills(value: int) -> void:
	kills_label.text = "Kills %d" % value

func show_message(message: String) -> void:
	message_label.text = "%s\nPress R" % message
	message_label.visible = true
```

Create `scenes/hud.tscn`:

```ini
[gd_scene load_steps=2 format=3 uid="uid://hud_scene"]

[ext_resource type="Script" path="res://scripts/hud.gd" id="1_hud"]

[node name="HUD" type="CanvasLayer"]
script = ExtResource("1_hud")

[node name="TimeLabel" type="Label" parent="."]
offset_left = 16.0
offset_top = 14.0
offset_right = 160.0
offset_bottom = 46.0
text = "Time 120"

[node name="HealthLabel" type="Label" parent="."]
offset_left = 16.0
offset_top = 48.0
offset_right = 160.0
offset_bottom = 80.0
text = "HP 5/5"

[node name="KillsLabel" type="Label" parent="."]
offset_left = 16.0
offset_top = 82.0
offset_right = 160.0
offset_bottom = 114.0
text = "Kills 0"

[node name="MessageLabel" type="Label" parent="."]
visible = false
horizontal_alignment = 1
vertical_alignment = 1
offset_left = 120.0
offset_top = 390.0
offset_right = 420.0
offset_bottom = 530.0
text = "Survived!\nPress R"
```

- [ ] **Step 5: Wire manager, HUD, and enemy death accounting**

Modify `scenes/main.tscn`:

```ini
[gd_scene load_steps=6 format=3 uid="uid://main_survival_scene"]

[ext_resource type="PackedScene" path="res://scenes/player.tscn" id="1_player"]
[ext_resource type="PackedScene" path="res://scenes/enemy.tscn" id="2_enemy"]
[ext_resource type="Script" path="res://scripts/spawner.gd" id="3_spawner"]
[ext_resource type="PackedScene" path="res://scenes/hud.tscn" id="4_hud"]
[ext_resource type="Script" path="res://scripts/game_manager.gd" id="5_game_manager"]

[node name="Main" type="Node2D"]

[node name="Grass" type="ColorRect" parent="."]
offset_right = 540.0
offset_bottom = 960.0
color = Color(0.28, 0.38, 0.18, 1)

[node name="Player" parent="." instance=ExtResource("1_player")]
position = Vector2(270, 520)

[node name="Spawner" type="Node2D" parent="."]
script = ExtResource("3_spawner")
enemy_scene = ExtResource("2_enemy")
player_path = NodePath("../Player")

[node name="SpawnTimer" type="Timer" parent="Spawner"]

[node name="HUD" parent="." instance=ExtResource("4_hud")]

[node name="GameManager" type="Node" parent="."]
script = ExtResource("5_game_manager")
player_path = NodePath("../Player")
hud_path = NodePath("../HUD")
spawner_path = NodePath("../Spawner")

[connection signal="timeout" from="Spawner/SpawnTimer" to="Spawner" method="_on_spawn_timer_timeout"]
```

Modify `scripts/spawner.gd` so spawned enemy deaths notify the manager:

```gdscript
func spawn_enemy() -> void:
	if enemy_scene == null:
		return
	var player := get_node_or_null(player_path)
	var enemy := enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = _pick_edge_position()
	enemy.target = player
	enemy.add_to_group("enemies")
	var manager := get_tree().current_scene.get_node_or_null("GameManager")
	if manager != null and enemy.has_signal("died"):
		enemy.died.connect(manager.on_enemy_died)
```

Modify `scripts/attack_orb.gd` so orbs are discoverable for cleanup:

```gdscript
func _ready() -> void:
	add_to_group("orbs")
	life_timer.wait_time = lifetime
	life_timer.start()
```

- [ ] **Step 6: Run tests and verify they pass**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: PASS with `TESTS PASSED`.

- [ ] **Step 7: Commit**

```powershell
git add scripts/game_manager.gd scripts/hud.gd scenes/hud.tscn scenes/main.tscn scripts/spawner.gd scripts/attack_orb.gd scripts/test_runner.gd
git commit -m "feat: add survival win and lose flow"
```

## Task 7: Runbook and Final Verification

**Files:**
- Create: `docs/development/runbook.md`
- Modify: `docs/index.md`

- [ ] **Step 1: Write runbook**

Create `docs/development/runbook.md`:

```markdown
# 运行手册

## 运行游戏

1. 安装 Godot 4.x。
2. 用 Godot 打开本仓库根目录。
3. 运行主场景 `res://scenes/main.tscn`。

## 操作

- `WASD` 或方向键：移动拟人化边牧。
- 自动攻击：边牧会从手部周期性发射追踪攻击球。
- `R`：胜利或失败后重新开始。

## 目标

在倒计时结束前存活。牛羊是敌人，会追踪玩家并在接触时造成伤害。

## 验证

命令行可用 Godot 时运行：

```powershell
godot --headless --script scripts/test_runner.gd
```

期望输出包含：

```text
TESTS PASSED
```

## 调试辅助层

正常运行默认不显示碰撞、范围、坐标、刷怪区或对象池信息。后续如需加入调试辅助层，必须通过显式调试参数或专用验证入口开启。
```

- [ ] **Step 2: Update docs index**

Modify `docs/index.md` so it contains:

```markdown
# 文档索引

## 设计规格

- [首版生存追踪球设计](superpowers/specs/2026-06-19-survival-orb-design.md)

## 实现计划

- [首版生存追踪球实现计划](superpowers/plans/2026-06-19-survival-orb-implementation.md)

## 开发验收

- [验收标准](development/acceptance-standard)
- [运行手册](development/runbook.md)
```

- [ ] **Step 3: Run automated verification**

Run:

```powershell
godot --headless --script scripts/test_runner.gd
```

Expected: PASS with `TESTS PASSED`.

- [ ] **Step 4: Run manual smoke check**

Open the project in Godot 4.x and run `res://scenes/main.tscn`.

Expected:

- Player appears centered on a grass field.
- WASD and arrow keys move the player.
- Cattle/sheep enemies spawn from the arena edges.
- Enemies chase the player.
- Attack orbs fire from the player's hand and hit enemies.
- HUD shows time, HP, and kills.
- Timer reaching zero shows `Survived!`.
- Player HP reaching zero shows `Defeated`.
- No debug collision/range/coordinate overlays appear.

- [ ] **Step 5: Commit**

```powershell
git add docs/development/runbook.md docs/index.md
git commit -m "docs: add prototype runbook"
```

## Self-Review

- Spec coverage: The plan covers project setup, player movement and health, enemy pursuit and contact damage, automatic homing attack orbs, spawn pressure, countdown victory, death failure, HUD, runbook, and no-debug-overlay acceptance.
- Placeholder scan: The plan contains no placeholder markers or unspecified edge-handling instructions.
- Type consistency: The plan consistently uses `Player`, `Enemy`, `AttackOrb`, `AttackController`, `Spawner`, `GameManager`, and `HUD` class names and matching scene/script paths.
- Scope check: The plan implements only the approved first version. It does not add upgrades, items, saves, narrative, or multi-level progression.
