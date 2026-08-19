extends Control

signal level_selected(level_data: Resource)
signal back_to_menu_pressed

@export var level_1_data: LevelData

func _ready():
	# Создаем данные уровня 1 программно, если не заданы в инспекторе
	if not level_1_data:
		level_1_data = LevelData.new()
		level_1_data.level_name = "Уровень 1: Буква T"
	
	$VBoxContainer/Level1Button.connect("pressed", _on_level1_pressed)
	$VBoxContainer/BackButton.connect("pressed", _on_back_pressed)

func _on_level1_pressed():
	level_selected.emit(level_1_data)

func _on_back_pressed():
	back_to_menu_pressed.emit()
