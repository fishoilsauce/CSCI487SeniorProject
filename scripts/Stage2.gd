extends Node2D

# ----------------------------
# Constants / Config
# ----------------------------
const BUILDABLE_ATLAS := Vector2i(6, 1)
const TOWER_COST := 5
const HEAVY_TOWER_COST := 8
const MAX_WAVES := 4

@export var wave_1_enemies: int = 6
@export var wave_2_enemies: int = 8
@export var wave_3_enemies: int = 6
@export var spawn_interval: float = 0.6

# ----------------------------
# Scene References
# ----------------------------
@onready var enemy_paths: Array[Path2D] = [
	$EnemyPathA,
	$EnemyPathB
]
@onready var grid: TileMap = $Grid
@onready var preview: Sprite2D = $PlacementPreview

@onready var money_label: Label = $UI/MoneyLabel
@onready var health_label: Label = $UI/HealthLabel
@onready var wave_label: Label = $UI/WaveLabel
@onready var prompt_label: Label = $UI/PromptLabel
@onready var enemies_label: Label = $UI/EnemiesLabel

@onready var basic_tower_button: Button = $UI/TowerPanel/VBoxContainer/BasicTowerButton
@onready var heavy_tower_button: Button = $UI/TowerPanel/VBoxContainer/HeavyTowerButton
@onready var selected_tower_label: Label = $UI/TowerPanel/VBoxContainer/SelectedTowerLabel

@onready var reset_button: Button = $UI/ResetButton

# Popup UI
@onready var tower_popup: Panel = $UI/TowerPopup
@onready var tower_title_label: Label = $UI/TowerPopup/VBoxContainer/TowerTitleLabel
@onready var tower_stats_label: Label = $UI/TowerPopup/VBoxContainer/TowerStatsLabel
@onready var tower_path_label: Label = $UI/TowerPopup/VBoxContainer/TowerPathLabel
@onready var damage_upgrade_button: Button = $UI/TowerPopup/VBoxContainer/HBoxContainer/DamageUpgradeButton
@onready var speed_upgrade_button: Button = $UI/TowerPopup/VBoxContainer/HBoxContainer/SpeedUpgradeButton
@onready var sell_tower_button: Button = $UI/TowerPopup/VBoxContainer/HBoxContainer2/SellTowerButton
@onready var close_popup_button: Button = $UI/TowerPopup/VBoxContainer/HBoxContainer2/ClosePopupButton

@onready var end_game_popup: Panel = $UI/EndGamePopup
@onready var end_game_label: Label = $UI/EndGamePopup/VBoxContainer/EndGameLabel
@onready var end_game_message: Label = $UI/EndGamePopup/VBoxContainer/EndGameMessageLabel

@onready var restart_button: Button = $UI/EndGamePopup/VBoxContainer/HBoxContainer/RestartButton
@onready var next_stage_button: Button = $UI/EndGamePopup/VBoxContainer/HBoxContainer/NextStageButton
@onready var main_menu_button: Button = $UI/EndGamePopup/VBoxContainer/HBoxContainer/MainMenuButton

# ----------------------------
# Packed Scenes
# ----------------------------
var enemy_runner_scene: PackedScene = preload("res://scenes/enemies/EnemyRunner.tscn")
var tank_enemy_runner_scene: PackedScene = preload("res://scenes/enemies/TankEnemyRunner.tscn")
var boss_enemy_runner_scene: PackedScene = preload("res://scenes/enemies/BossEnemyRunner.tscn")
var tower_scene: PackedScene = preload("res://scenes/towers/Tower.tscn")
var heavy_tower_scene: PackedScene = preload("res://scenes/towers/HeavyTower.tscn")

# ----------------------------
# Game State
# ----------------------------
var occupied := {}
var money: int = 50
var health: int = 20
var wave: int = 0

var game_over: bool = false
var game_won: bool = false

var spawning_wave: bool = false
var wave_spawning_done: bool = false
var alive_enemies: int = 0

enum TowerType { NONE, BASIC, HEAVY }
var selected_tower: TowerType = TowerType.NONE

var selected_placed_tower: Node2D = null
var selected_placed_tower_cell: Vector2i = Vector2i.ZERO

# ----------------------------
# Lifecycle
# ----------------------------
func _ready() -> void:
	basic_tower_button.pressed.connect(_on_basic_tower_button_pressed)
	heavy_tower_button.pressed.connect(_on_heavy_tower_button_pressed)
	reset_button.pressed.connect(_on_reset_button_pressed)

	sell_tower_button.pressed.connect(_on_sell_tower_button_pressed)
	damage_upgrade_button.pressed.connect(_on_damage_upgrade_button_pressed)
	speed_upgrade_button.pressed.connect(_on_speed_upgrade_button_pressed)
	close_popup_button.pressed.connect(_on_close_popup_button_pressed)

	restart_button.pressed.connect(_on_restart_button_pressed)
	next_stage_button.pressed.connect(_on_next_stage_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)

	tower_popup.visible = false
	end_game_popup.visible = false
	preview.visible = false

	update_ui()
	prompt_label.text = "Press SPACE to start wave!"

# ----------------------------
# Input
# ----------------------------
func _unhandled_input(event: InputEvent) -> void:
	if game_over or game_won:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var cell: Vector2i = grid.local_to_map(grid.to_local(mouse_pos))

		if occupied.has(cell):
			select_placed_tower(occupied[cell], cell)
			return

		clear_placed_tower_selection()

		match selected_tower:
			TowerType.BASIC:
				place_tower_at_mouse(tower_scene, TOWER_COST)
			TowerType.HEAVY:
				place_tower_at_mouse(heavy_tower_scene, HEAVY_TOWER_COST)
			TowerType.NONE:
				return

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

	if grid.get_cell_source_id(0, cell) == -1:
		return

	var atlas: Vector2i = grid.get_cell_atlas_coords(0, cell)
	if atlas != BUILDABLE_ATLAS:
		return

	if occupied.has(cell):
		return

	if money < tower_cost:
		return

	money -= tower_cost
	update_ui()

	var tower := tower_scene_to_place.instantiate() as Node2D
	add_child(tower)
	tower.global_position = grid.to_global(grid.map_to_local(cell))
	tower.cost = tower_cost

	occupied[cell] = tower
	AudioManager.play_place_tower()

func select_placed_tower(tower: Node2D, cell: Vector2i) -> void:
	if selected_placed_tower != null and selected_placed_tower.has_method("set_selected"):
		selected_placed_tower.set_selected(false)

	selected_placed_tower = tower
	selected_placed_tower_cell = cell

	if selected_placed_tower.has_method("set_selected"):
		selected_placed_tower.set_selected(true)

	tower_popup.visible = true
	update_tower_popup()

func clear_placed_tower_selection() -> void:
	if selected_placed_tower != null and selected_placed_tower.has_method("set_selected"):
		selected_placed_tower.set_selected(false)

	selected_placed_tower = null
	selected_placed_tower_cell = Vector2i.ZERO
	tower_popup.visible = false

func update_tower_popup() -> void:
	if selected_placed_tower == null:
		tower_popup.visible = false
		return

	tower_title_label.text = str(selected_placed_tower.tower_name)
	tower_stats_label.text = selected_placed_tower.get_stats_text()
	tower_path_label.text = selected_placed_tower.get_path_text()

	var damage_cost: int = int(selected_placed_tower.get_damage_upgrade_cost())
	var speed_cost: int = int(selected_placed_tower.get_speed_upgrade_cost())

	if damage_cost >= 0:
		damage_upgrade_button.text = "Damage ($%d)" % damage_cost
		damage_upgrade_button.disabled = money < damage_cost
	else:
		damage_upgrade_button.text = "Damage (Locked)"
		damage_upgrade_button.disabled = true

	if speed_cost >= 0:
		speed_upgrade_button.text = "Speed ($%d)" % speed_cost
		speed_upgrade_button.disabled = money < speed_cost
	else:
		speed_upgrade_button.text = "Speed (Locked)"
		speed_upgrade_button.disabled = true

func _on_sell_tower_button_pressed() -> void:
	if selected_placed_tower == null:
		return

	AudioManager.play_click()

	var refund: int = int(selected_placed_tower.get_sell_value())
	money += refund

	occupied.erase(selected_placed_tower_cell)
	selected_placed_tower.queue_free()

	clear_placed_tower_selection()
	update_ui()

func _on_damage_upgrade_button_pressed() -> void:
	if selected_placed_tower == null:
		return

	var cost: int = int(selected_placed_tower.get_damage_upgrade_cost())
	if cost < 0 or money < cost:
		return

	money -= cost
	selected_placed_tower.upgrade_damage()
	AudioManager.play_upgrade()

	update_ui()
	update_tower_popup()

func _on_speed_upgrade_button_pressed() -> void:
	if selected_placed_tower == null:
		return

	var cost: int = int(selected_placed_tower.get_speed_upgrade_cost())
	if cost < 0 or money < cost:
		return

	money -= cost
	selected_placed_tower.upgrade_speed()
	AudioManager.play_upgrade()

	update_ui()
	update_tower_popup()

func _on_close_popup_button_pressed() -> void:
	AudioManager.play_click()
	clear_placed_tower_selection()

# ----------------------------
# Waves / Spawning
# ----------------------------
func start_wave() -> void:
	spawning_wave = true
	wave_spawning_done = false

	wave += 1
	prompt_label.text = "Wave in progress..."
	update_ui()

	if wave == 4:
		AudioManager.play_boss_spawn()
	else:
		AudioManager.play_wave_start()

	if wave == 1:
		for i in range(enemies_per_wave):
			if game_over or game_won:
				return
			spawn_enemy(enemy_runner_scene)
			await get_tree().create_timer(spawn_interval).timeout

	elif wave == 2:
		for i in range(enemies_per_wave):
			if game_over or game_won:
				return
			if i % 3 == 2:
				spawn_enemy(tank_enemy_runner_scene)
			else:
				spawn_enemy(enemy_runner_scene)
			await get_tree().create_timer(spawn_interval).timeout

	elif wave == 3:
		for i in range(enemies_per_wave):
			if game_over or game_won:
				return
			spawn_enemy(tank_enemy_runner_scene)
			await get_tree().create_timer(spawn_interval).timeout

	elif wave == 4:
		prompt_label.text = "FINAL EXAM APPROACHING..."
		update_ui()

		await get_tree().create_timer(1.0).timeout
		spawn_enemy(boss_enemy_runner_scene)

	wave_spawning_done = true
	_check_wave_end()

func spawn_enemy(enemy_scene: PackedScene) -> void:
	var runner := enemy_scene.instantiate()
	runner.progress = 0.0
	var selected_path = enemy_paths.pick_random()
	selected_path.add_child(runner)

	runner.connect("leaked", Callable(self, "_on_enemy_leaked"))

	var enemy = runner.get_node("Enemy")
	enemy.died.connect(_on_enemy_died)

	alive_enemies += 1
	update_ui()

# ----------------------------
# Events
# ----------------------------
func _on_enemy_died(reward_amount: int) -> void:
	if game_over or game_won:
		return

	if alive_enemies <= 0:
		return

	money += reward_amount
	alive_enemies = max(alive_enemies - 1, 0)

	update_ui()
	_check_wave_end()

func _on_enemy_leaked(leak_damage: int) -> void:
	if game_over or game_won:
		return

	if alive_enemies <= 0:
		return

	health -= leak_damage
	if health < 0:
		health = 0

	AudioManager.play_hurt()

	alive_enemies = max(alive_enemies - 1, 0)

	update_ui()

	if health == 0:
		_trigger_game_over()
		return

	_check_wave_end()

func _trigger_game_over() -> void:
	game_over = true
	spawning_wave = false

	AudioManager.play_lose()

	end_game_label.text = "GAME OVER"
	end_game_message.text = "You ran out of health!"

	end_game_popup.visible = true

	next_stage_button.disabled = true
	next_stage_button.visible = false

func _trigger_game_won() -> void:
	game_won = true
	spawning_wave = false

	AudioManager.play_win()

	end_game_label.text = "YOU WIN!"
	end_game_message.text = "You passed the final exam!"

	end_game_popup.visible = true

	next_stage_button.disabled = false
	next_stage_button.visible = true

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

	if selected_placed_tower != null:
		update_tower_popup()

func _on_reset_button_pressed() -> void:
	AudioManager.play_click()
	get_tree().reload_current_scene()

func _process(_delta: float) -> void:
	update_preview()

func update_preview() -> void:
	if selected_tower == TowerType.NONE:
		preview.visible = false
		return

	preview.visible = true

	var mouse_pos: Vector2 = get_global_mouse_position()
	var cell: Vector2i = grid.local_to_map(grid.to_local(mouse_pos))
	var world_pos: Vector2 = grid.to_global(grid.map_to_local(cell))

	preview.global_position = world_pos

	var valid := true

	if grid.get_cell_source_id(0, cell) == -1:
		valid = false
	if grid.get_cell_atlas_coords(0, cell) != BUILDABLE_ATLAS:
		valid = false
	if occupied.has(cell):
		valid = false

	if valid:
		preview.modulate = Color(0, 1, 0, 0.5)
	else:
		preview.modulate = Color(1, 0, 0, 0.5)

func _on_restart_button_pressed() -> void:
	AudioManager.play_click()
	get_tree().reload_current_scene()

func _on_next_stage_button_pressed() -> void:
	print("Next stage not implemented yet")

func _on_main_menu_button_pressed() -> void:
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://scenes/main/TitleScreen.tscn")
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
			prompt_label.text = "Press SPACE to start wave!"

# ----------------------------
# Tower Buttons
# ----------------------------
func _on_basic_tower_button_pressed() -> void:
	AudioManager.play_click()
	selected_tower = TowerType.BASIC
	update_ui()

func _on_heavy_tower_button_pressed() -> void:
	AudioManager.play_click()
	selected_tower = TowerType.HEAVY
	update_ui()
