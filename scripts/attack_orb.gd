class_name AttackOrb
extends Area2D

@export var speed: float = 420.0
@export var damage: int = 1
@export var hit_distance: float = 18.0
@export var lifetime: float = 2.5

var target: Node2D

@onready var life_timer: Timer = $LifeTimer

func _ready() -> void:
	add_to_group("orbs")
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
