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
var is_dead: bool = false

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
	if is_dead:
		return
	health = max(health - amount, 0)
	body.modulate = Color(1.0, 0.75, 0.45, 1.0)
	if health <= 0:
		is_dead = true
		died.emit(self)
		queue_free()

func _on_hurtbox_body_entered(body_node: Node2D) -> void:
	if can_deal_contact_damage and body_node.has_method("take_damage"):
		body_node.take_damage(contact_damage)
		can_deal_contact_damage = false
		contact_timer.start()

func _on_contact_timer_timeout() -> void:
	can_deal_contact_damage = true
