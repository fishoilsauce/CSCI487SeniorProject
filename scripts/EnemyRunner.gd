extends PathFollow2D

signal leaked(leak_damage: int)

@export var speed: float = 200.0

var has_leaked: bool = false

func _process(delta: float) -> void:
	if has_leaked:
		return

	progress += speed * delta

	if progress_ratio >= 0.999:
		has_leaked = true
		var enemy = get_node("Enemy")
		leaked.emit(enemy.leak_damage)
		queue_free()
