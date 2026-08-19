extends Control

signal level_selected(level_index: int)
signal back_to_menu_pressed

func _ready():
	$VBoxContainer/Level1Button.connect("pressed", _on_level1_pressed)
	$VBoxContainer/Level2Button.connect("pressed", _on_level2_pressed)
	$VBoxContainer/BackButton.connect("pressed", _on_back_pressed)

func _on_level1_pressed():
	level_selected.emit(0)  # Индекс первого уровня

func _on_level2_pressed():
	level_selected.emit(1)  # Индекс второго уровня

func _on_back_pressed():
	back_to_menu_pressed.emit()
