extends Node2D

signal died(reward_amount: int)

@export var leak_damage: int = 1
@export var max_hp: int = 5
@export var reward: int = 1

@onready var health_bar: ProgressBar = $HealthBar

var hp: int

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_bar.visible = false

func take_damage(amount: int) -> void:
	hp -= amount
	
	if hp < 0:
		hp = 0
	
	health_bar.visible = true
	health_bar.value = hp
	
	if hp <= 0:
		die()

func die() -> void:
	died.emit(reward)
	# Enemy is a child of EnemyRunner (PathFollow2D),
	# so free the whole runner so it disappears cleanly.
	get_parent().queue_free()
