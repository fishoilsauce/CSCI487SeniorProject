extends Node2D

var cost: int = 0

@export var tower_name: String = "Tower"
@export var damage: int = 1

@export var damage_upgrade_costs: Array[int] = [5, 8]
@export var speed_upgrade_costs: Array[int] = [5, 8]

@export var damage_upgrade_bonus: int = 2
@export var speed_upgrade_multiplier: float = 0.85

var upgrade_path: String = ""
var damage_level: int = 0
var speed_level: int = 0
var max_upgrade_level: int = 2

var targets: Array[Node] = []

@onready var range_area: Area2D = $Range
@onready var fire_timer: Timer = $FireTimer

@export var projectile_scene: PackedScene = preload("res://scenes/projectiles/Projectile.tscn")

func _ready() -> void:
	range_area.area_entered.connect(_on_area_entered)
	range_area.area_exited.connect(_on_area_exited)
	fire_timer.timeout.connect(_on_fire_timer_timeout)

	var sprite := $Sprite2D as Sprite2D
	if sprite.material != null:
		sprite.material = sprite.material.duplicate()

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

	var p := projectile_scene.instantiate() as Area2D
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
	p.target = best
	p.damage = damage

	AudioManager.play_tower_shoot()

func can_upgrade_damage() -> bool:
	return (upgrade_path == "" or upgrade_path == "damage") and damage_level < max_upgrade_level

func can_upgrade_speed() -> bool:
	return (upgrade_path == "" or upgrade_path == "speed") and speed_level < max_upgrade_level

func get_damage_upgrade_cost() -> int:
	if not can_upgrade_damage():
		return -1
	return damage_upgrade_costs[damage_level]

func get_speed_upgrade_cost() -> int:
	if not can_upgrade_speed():
		return -1
	return speed_upgrade_costs[speed_level]

func upgrade_damage() -> void:
	if not can_upgrade_damage():
		return

	if upgrade_path == "":
		upgrade_path = "damage"

	damage += damage_upgrade_bonus
	damage_level += 1

func upgrade_speed() -> void:
	if not can_upgrade_speed():
		return

	if upgrade_path == "":
		upgrade_path = "speed"

	fire_timer.wait_time *= speed_upgrade_multiplier
	speed_level += 1

func get_sell_value() -> int:
	return int(cost * 0.5)

func get_stats_text() -> String:
	var shots_per_second: float = 1.0 / fire_timer.wait_time
	return "Damage: %d\nFire Rate: %.2f/s\nSell: $%d" % [damage, shots_per_second, get_sell_value()]

func get_path_text() -> String:
	if upgrade_path == "":
		return "Path: Not Chosen"
	elif upgrade_path == "damage":
		return "Path: Damage (%d/%d)" % [damage_level, max_upgrade_level]
	elif upgrade_path == "speed":
		return "Path: Speed (%d/%d)" % [speed_level, max_upgrade_level]
	return "Path: Unknown"

func set_selected(selected: bool) -> void:
	var sprite := $Sprite2D
	var mat := sprite.material as ShaderMaterial

	if mat == null:
		return

	if selected:
		mat.set_shader_parameter("outline_size", 1.0)
	else:
		mat.set_shader_parameter("outline_size", 0.0)
