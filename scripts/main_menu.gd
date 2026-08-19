extends Control

signal start_game_pressed

func _ready():
	$VBoxContainer/StartButton.connect("pressed", _on_start_button_pressed)

func _on_start_button_pressed():
	start_game_pressed.emit()
