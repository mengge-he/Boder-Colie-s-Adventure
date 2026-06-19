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
