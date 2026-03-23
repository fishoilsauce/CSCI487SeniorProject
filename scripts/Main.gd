extends Node2D

# ----------------------------
# Constants / Config
# ----------------------------
const BUILDABLE_ATLAS := Vector2i(6, 1)
const TOWER_COST := 5
const HEAVY_TOWER_COST := 8
const MAX_WAVES := 3

@export var enemies_per_wave: int = 5
@export var spawn_interval: float = 0.6

# ----------------------------
# Scene References
# ----------------------------
@onready var enemy_path: Path2D = $EnemyPath
@onready var grid: TileMap = $Grid

@onready var money_label: Label = $UI/MoneyLabel
@onready var health_label: Label = $UI/HealthLabel
@onready var wave_label: Label = $UI/WaveLabel
@onready var prompt_label: Label = $UI/PromptLabel
@onready var enemies_label: Label = $UI/EnemiesLabel

@onready var basic_tower_button: Button = $UI/TowerPanel/VBoxContainer/BasicTowerButton
@onready var heavy_tower_button: Button = $UI/TowerPanel/VBoxContainer/HeavyTowerButton
@onready var selected_tower_label: Label = $UI/TowerPanel/VBoxContainer/SelectedTowerLabel

# ----------------------------
# Packed Scenes
# ----------------------------
var enemy_runner_scene: PackedScene = preload("res://scenes/enemies/EnemyRunner.tscn")
var tank_enemy_runner_scene: PackedScene = preload("res://scenes/enemies/TankEnemyRunner.tscn")
var tower_scene: PackedScene = preload("res://scenes/towers/Tower.tscn")
var heavy_tower_scene: PackedScene = preload("res://scenes/towers/HeavyTower.tscn")

# ----------------------------
# Game State
# ----------------------------
var occupied := {}               # placed tower cells
var money: int = 50
var health: int = 20
var wave: int = 0

# Game over state
var game_over: bool = false
# Game won state
var game_won: bool = false

# Wave state
var spawning_wave: bool = false
var wave_spawning_done: bool = false
var alive_enemies: int = 0

var selected_tower: TowerType = TowerType.NONE
enum TowerType { NONE, BASIC, HEAVY }

# ----------------------------
# Lifecycle
# ----------------------------
func _ready() -> void:
	basic_tower_button.pressed.connect(_on_basic_tower_button_pressed)
	heavy_tower_button.pressed.connect(_on_heavy_tower_button_pressed)
	update_ui()

# ----------------------------
# Input
# ----------------------------
func _unhandled_input(event: InputEvent) -> void:
	if game_over or game_won:
		return

	# Mouse click = place tower
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match selected_tower:
			TowerType.BASIC:
				place_tower_at_mouse(tower_scene, TOWER_COST)
			TowerType.HEAVY:
				place_tower_at_mouse(heavy_tower_scene, HEAVY_TOWER_COST)
			TowerType.NONE:
				return

	# Space = start wave (only if no wave active)
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE and not event.echo:
		if spawning_wave:
			return
		start_wave()

# ----------------------------
# Tower Placement
# ----------------------------
func place_tower_at_mouse(tower_scene_to_place: PackedScene, tower_cost: int) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var cell: Vector2i = grid.local_to_map(grid.to_local(mouse_pos))

	# Must click on painted tiles
	if grid.get_cell_source_id(0, cell) == -1:
		return

	# Must be buildable tile
	var atlas: Vector2i = grid.get_cell_atlas_coords(0, cell)
	if atlas != BUILDABLE_ATLAS:
		return

	# Must be empty
	if occupied.has(cell):
		return

	# Must afford tower
	if money < tower_cost:
		return

	# Pay + place
	money -= tower_cost
	update_ui()

	var tower := tower_scene_to_place.instantiate() as Node2D
	add_child(tower)
	tower.global_position = grid.to_global(grid.map_to_local(cell))

	occupied[cell] = true

# ----------------------------
# Waves / Spawning
# ----------------------------
func start_wave() -> void:
	spawning_wave = true
	wave_spawning_done = false

	wave += 1
	prompt_label.text = "Wave in progress..."
	update_ui()

	for i in range(enemies_per_wave):
		if game_over:
			return
		if wave > 1 and i % 3 == 2:
			spawn_enemy(tank_enemy_runner_scene)
		else: 
			spawn_enemy(enemy_runner_scene)
		await get_tree().create_timer(spawn_interval).timeout

	wave_spawning_done = true
	_check_wave_end()

func spawn_enemy(enemy_scene: PackedScene) -> void:
	var runner := enemy_scene.instantiate()
	runner.progress = 0.0
	enemy_path.add_child(runner)

	runner.connect("leaked", Callable(self, "_on_enemy_leaked"))

	var enemy = runner.get_node("Enemy")
	enemy.died.connect(_on_enemy_died)

	alive_enemies += 1
	update_ui()

# ----------------------------
# Events (Enemy Death / Leak)
# ----------------------------
func _on_enemy_died(reward_amount: int) -> void:
	if game_over:
		return

	money += reward_amount
	alive_enemies -= 1
	update_ui()
	_check_wave_end()

func _on_enemy_leaked() -> void:
	if game_over:
		return

	health -= 1
	if health < 0:
		health = 0

	alive_enemies -= 1
	update_ui()

	if health == 0:
		_trigger_game_over()
		return

	_check_wave_end()

func _trigger_game_over() -> void:
	game_over = true
	spawning_wave = false
	prompt_label.text = "GAME OVER"

func _trigger_game_won() -> void:
	game_won = true
	spawning_wave = false
	prompt_label.text = "YOU WIN!"

# ----------------------------
# UI
# ----------------------------
func update_ui() -> void:
	money_label.text = "Money: " + str(money)
	health_label.text = "Health: " + str(health)
	wave_label.text = "Wave: " + str(wave)
	enemies_label.text = "Enemies: " + str(alive_enemies)
	
	match selected_tower:
		TowerType.NONE:
			selected_tower_label.text = "Selected: None"
		TowerType.BASIC:
			selected_tower_label.text = "Selected: Basic Tower"
		TowerType.HEAVY:
			selected_tower_label.text = "Selected: Heavy Tower"

# ----------------------------
# Wave End Logic
# ----------------------------
func _check_wave_end() -> void:
	if not spawning_wave or game_over or game_won:
		return

	if wave_spawning_done and alive_enemies <= 0:
		spawning_wave = false
		if wave >= MAX_WAVES:
			_trigger_game_won()
		else:
			prompt_label.text = "Press SPACE to start wave"


# TOWER BUTTONS
func _on_basic_tower_button_pressed() -> void:
	selected_tower = TowerType.BASIC
	update_ui()

func _on_heavy_tower_button_pressed() -> void:
	selected_tower = TowerType.HEAVY
	update_ui()
