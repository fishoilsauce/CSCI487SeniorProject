extends Control

@onready var skip_button: Button = $VBoxContainer/SkipButton

func _ready() -> void:
	skip_button.pressed.connect(_on_skip_pressed)

func _on_skip_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _unhandled_input(event):
	if event.is_pressed():
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
