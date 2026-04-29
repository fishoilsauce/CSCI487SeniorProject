extends Node

var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

var boss_spawn_sound: AudioStream = preload("res://Assets/sounds/bossSpawn.wav")
var click_sound: AudioStream = preload("res://Assets/sounds/click.wav")
var enemy_death_sound: AudioStream = preload("res://Assets/sounds/enemyDeath.wav")
var hurt_sound: AudioStream = preload("res://Assets/sounds/hurt.wav")
var lose_sound: AudioStream = preload("res://Assets/sounds/lose.wav")
var place_tower_sound: AudioStream = preload("res://Assets/sounds/placeTower.wav")
var tower_shoot_sound: AudioStream = preload("res://Assets/sounds/towerShoot.wav")
var upgrade_sound: AudioStream = preload("res://Assets/sounds/upgrade.wav")
var wave_start_sound: AudioStream = preload("res://Assets/sounds/waveStart.wav")
var win_sound: AudioStream = preload("res://Assets/sounds/win.wav")

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	sfx_player.volume_db = -6

	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.volume_db = -12

func play_sound(sound: AudioStream) -> void:
	if sound == null:
		return

	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = sound
	player.volume_db = -6
	player.play()
	player.finished.connect(player.queue_free)

func play_click() -> void:
	play_sound(click_sound)

func play_boss_spawn() -> void:
	play_sound(boss_spawn_sound)

func play_enemy_death() -> void:
	play_sound(enemy_death_sound)

func play_hurt() -> void:
	play_sound(hurt_sound)

func play_lose() -> void:
	play_sound(lose_sound)

func play_place_tower() -> void:
	play_sound(place_tower_sound)

func play_tower_shoot() -> void:
	play_sound(tower_shoot_sound)

func play_upgrade() -> void:
	play_sound(upgrade_sound)

func play_wave_start() -> void:
	play_sound(wave_start_sound)

func play_win() -> void:
	play_sound(win_sound)
