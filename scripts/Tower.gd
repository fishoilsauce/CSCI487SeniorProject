extends Node2D

@export var damage: int = 1

var targets: Array[Node] = []

@onready var range_area: Area2D = $Range
@onready var fire_timer: Timer = $FireTimer

var projectile_scene: PackedScene = preload("res://scenes/projectiles/Projectile.tscn")

func _ready() -> void:
	range_area.area_entered.connect(_on_area_entered)
	range_area.area_exited.connect(_on_area_exited)
	fire_timer.timeout.connect(_on_fire_timer_timeout)

func _on_area_entered(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy != null and enemy.is_in_group("enemies"):
		targets.append(enemy)

func _on_area_exited(area: Area2D) -> void:
	var enemy = area.get_parent()
	if enemy != null:
		targets.erase(enemy)

func _on_fire_timer_timeout() -> void:
	targets = targets.filter(func(t): return is_instance_valid(t))

	if targets.is_empty():
		return

	var best = targets[0]
	var best_dist = global_position.distance_squared_to(best.global_position)
	for t in targets:
		var d = global_position.distance_squared_to(t.global_position)
		if d < best_dist:
			best = t
			best_dist = d

	# Spawn projectile
	var p := projectile_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(p)
	p.global_position = global_position

	# Set target + damage (Projectile.gd variables)
	p.target = best
	p.damage = damage
