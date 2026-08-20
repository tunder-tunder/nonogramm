extends Control

signal start_game_pressed
signal settings_pressed
signal gallery_pressed
signal exit_pressed

var progress: SaveData

func configure(save_data: SaveData) -> void:
	progress = save_data

func _ready():
	$Hero/Margin/Layout/Actions/StartButton.connect("pressed", _on_start_button_pressed)
	$Hero/Margin/Layout/Actions/SettingsButton.connect("pressed", _on_settings_button_pressed)
	$Hero/Margin/Layout/Actions/GalleryButton.connect("pressed", _on_gallery_button_pressed)
	$Hero/Margin/Layout/Actions/ExitButton.connect("pressed", _on_exit_button_pressed)
	if progress:
		var chapter := progress.last_chapter + 1
		var level := progress.last_level + 1
		$Hero/Margin/Layout/Intro/ProgressCard/ProgressLabel.text = "Продолжить: глава %d  ·  уровень %d" % [chapter, level]

func _on_start_button_pressed():
	start_game_pressed.emit()

func _on_settings_button_pressed():
	settings_pressed.emit()

func _on_gallery_button_pressed():
	gallery_pressed.emit()

func _on_exit_button_pressed():
	exit_pressed.emit()
