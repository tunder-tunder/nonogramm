extends Control

signal start_game_pressed
signal settings_pressed
signal gallery_pressed
signal exit_pressed

func _ready():
	$VBoxContainer/StartButton.connect("pressed", _on_start_button_pressed)
	$VBoxContainer/SettingsButton.connect("pressed", _on_settings_button_pressed)
	$VBoxContainer/GalleryButton.connect("pressed", _on_gallery_button_pressed)
	$VBoxContainer/ExitButton.connect("pressed", _on_exit_button_pressed)

func _on_start_button_pressed():
	start_game_pressed.emit()

func _on_settings_button_pressed():
	settings_pressed.emit()

func _on_gallery_button_pressed():
	gallery_pressed.emit()

func _on_exit_button_pressed():
	exit_pressed.emit()
