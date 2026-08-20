extends Control

signal level_selected(level_data: Resource)
signal back_to_menu_pressed

var levels: Array[LevelData] = [
	preload("res://levels/level_1.tres"),
	preload("res://levels/level_2.tres")
]

func _ready():
	$VBoxContainer/Level1Button.connect("pressed", _on_level_pressed.bind(0))
	$VBoxContainer/Level2Button.connect("pressed", _on_level_pressed.bind(1))
	$VBoxContainer/BackButton.connect("pressed", _on_back_pressed)

func _on_level_pressed(index: int):
	level_selected.emit(levels[index])

func _on_back_pressed():
	back_to_menu_pressed.emit()
