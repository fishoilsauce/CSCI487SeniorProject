extends PathFollow2D

signal leaked(leak_damage: int)

@export var speed: float = 200.0

func _process(delta: float) -> void:
	progress += speed * delta
	if progress_ratio >= 0.999:
		var enemy = get_node("Enemy")
		leaked.emit(enemy.leak_damage)
		queue_free()
