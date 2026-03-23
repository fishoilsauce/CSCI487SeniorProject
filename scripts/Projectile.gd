extends Area2D

@export var speed: float = 450.0
@export var damage: int = 1

var target: Node2D = null

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return

	var dir := (target.global_position - global_position)
	if dir.length() < 8.0:
		_hit_target()
		return

	global_position += dir.normalized() * speed * delta

func _on_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy != null and enemy.is_in_group("enemies"):
		target = enemy
		_hit_target()

func _hit_target() -> void:
	if target != null and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	queue_free()
