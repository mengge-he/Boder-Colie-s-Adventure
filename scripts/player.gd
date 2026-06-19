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
