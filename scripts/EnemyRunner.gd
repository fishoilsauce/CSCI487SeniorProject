extends PathFollow2D

signal leaked

@export var speed: float = 200.0

func _process(delta: float) -> void:
	progress += speed * delta
	if progress_ratio >= 0.999:
		leaked.emit()
		queue_free()
