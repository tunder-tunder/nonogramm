extends Control

signal back_to_menu_pressed

const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]

@onready var resolution_option: OptionButton = $Panel/VBoxContainer/ResolutionOption
@onready var fullscreen_check: CheckBox = $Panel/VBoxContainer/FullscreenCheck
@onready var apply_button: Button = $Panel/VBoxContainer/ApplyButton
@onready var back_button: Button = $Panel/VBoxContainer/BackButton
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel

func _ready():
	_populate_resolutions()
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	apply_button.connect("pressed", _on_apply_pressed)
	back_button.connect("pressed", _on_back_pressed)

func _populate_resolutions():
	resolution_option.clear()
	var current_size = DisplayServer.window_get_size()
	var selected_index = 0
	for index in range(RESOLUTIONS.size()):
		var size = RESOLUTIONS[index]
		resolution_option.add_item("%d × %d" % [size.x, size.y], index)
		if size == current_size:
			selected_index = index
	resolution_option.select(selected_index)

func _on_apply_pressed():
	var size = RESOLUTIONS[resolution_option.selected]
	if fullscreen_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(size)
		DisplayServer.window_set_position((DisplayServer.screen_get_size() - size) / 2)
	status_label.text = "Применено: %d × %d" % [size.x, size.y]
	print("[Nonogram Debug] Settings applied: %s fullscreen=%s" % [status_label.text, fullscreen_check.button_pressed])

func _on_back_pressed():
	back_to_menu_pressed.emit()
