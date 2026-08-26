extends Control

signal start_game_pressed
signal settings_pressed
signal gallery_pressed
signal exit_pressed

var progress: SaveData
var buttons: Array[Button] = []
var pointers: Array[Label] = []

@onready var start_button: Button = $Layout/Actions/StartRow/StartButton
@onready var gallery_button: Button = $Layout/Actions/GalleryRow/GalleryButton
@onready var settings_button: Button = $Layout/Actions/SettingsRow/SettingsButton
@onready var exit_button: Button = $Layout/Actions/ExitRow/ExitButton
@onready var progress_label: Label = $Layout/ProgressCard/ProgressLabel

func configure(save_data: SaveData) -> void:
	progress = save_data

func _ready() -> void:
	buttons = [start_button, gallery_button, settings_button, exit_button]
	pointers = [$Layout/Actions/StartRow/Pointer, $Layout/Actions/GalleryRow/Pointer, $Layout/Actions/SettingsRow/Pointer, $Layout/Actions/ExitRow/Pointer]
	start_button.pressed.connect(start_game_pressed.emit)
	gallery_button.pressed.connect(gallery_pressed.emit)
	settings_button.pressed.connect(settings_pressed.emit)
	exit_button.pressed.connect(exit_pressed.emit)
	for index in range(buttons.size()):
		buttons[index].focus_entered.connect(_select_item.bind(index))
		buttons[index].mouse_entered.connect(_select_item.bind(index))
	_select_item(0)
	start_button.grab_focus()
	if progress:
		var has_progress := not progress.completed.is_empty() or not progress.drafts.is_empty() or progress.last_chapter > 0 or progress.last_level > 0
		start_button.text = "Продолжить" if has_progress else "Новая игра"
		progress_label.text = "Глава %d  ·  уровень %d" % [progress.last_chapter + 1, progress.last_level + 1] if has_progress else "Начать путешествие"

func _select_item(selected: int) -> void:
	for index in range(buttons.size()):
		var active := index == selected
		pointers[index].visible = active
		var normal_color := Color("fff7ed") if active else Color("3b1730")
		var hover_color := Color("fffdf8") if active else Color("53213f")
		var pressed_color := Color("f3e7db") if active else Color("281020")
		buttons[index].custom_minimum_size = Vector2(0, 54)
		buttons[index].add_theme_stylebox_override("normal", _button_style(normal_color))
		buttons[index].add_theme_stylebox_override("focus", _button_style(normal_color))
		buttons[index].add_theme_stylebox_override("hover", _button_style(hover_color))
		buttons[index].add_theme_stylebox_override("pressed", _button_style(pressed_color))
		var text_color := Color("3b1730") if active else Color("fffaf4")
		buttons[index].add_theme_color_override("font_color", text_color)
		buttons[index].add_theme_color_override("font_focus_color", text_color)
		buttons[index].add_theme_color_override("font_hover_color", text_color)
		buttons[index].add_theme_color_override("font_pressed_color", text_color)

func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	return style
