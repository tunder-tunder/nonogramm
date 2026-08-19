extends Control

signal level_selected(level_data: Resource)
signal back_to_menu_pressed

var level_1_data: LevelData
var level_2_data: LevelData

func _ready():
	# Загружаем данные уровней из ресурсов
	level_1_data = preload("res://levels/level_1.tres")
	level_2_data = preload("res://levels/level_2.tres")
	
	$VBoxContainer/Level1Button.connect("pressed", _on_level1_pressed)
	$VBoxContainer/Level2Button.connect("pressed", _on_level2_pressed)
	$VBoxContainer/BackButton.connect("pressed", _on_back_pressed)

func _on_level1_pressed():
	level_selected.emit(level_1_data)

func _on_level2_pressed():
	level_selected.emit(level_2_data)

func _on_back_pressed():
	back_to_menu_pressed.emit()
