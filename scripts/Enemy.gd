extends Node2D

signal died(reward_amount: int)

@export var max_hp: int = 5
@export var reward: int = 1

var hp: int

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		die()

func die() -> void:
	died.emit(reward)
	# Enemy is a child of EnemyRunner (PathFollow2D),
	# so free the whole runner so it disappears cleanly.
	get_parent().queue_free()
