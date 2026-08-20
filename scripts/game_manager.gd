extends Node

signal scene_changed(new_scene: Node)

var current_scene: Node = null
var unlocked_gallery_levels: int = 0
var levels: Array[LevelData] = [
	preload("res://levels/level_1.tres"),
	preload("res://levels/level_2.tres")
]

func _ready():
	load_main_menu()

func load_main_menu():
	_clear_current_scene()
	var main_menu_scene = preload("res://scenes/main_menu.tscn").instantiate()
	add_child(main_menu_scene)
	current_scene = main_menu_scene
	if main_menu_scene.has_signal("start_game_pressed"):
		main_menu_scene.connect("start_game_pressed", load_level_select)
	if main_menu_scene.has_signal("settings_pressed"):
		main_menu_scene.connect("settings_pressed", load_settings_menu)
	if main_menu_scene.has_signal("gallery_pressed"):
		main_menu_scene.connect("gallery_pressed", load_gallery_menu)
	if main_menu_scene.has_signal("exit_pressed"):
		main_menu_scene.connect("exit_pressed", quit_game)

func load_settings_menu():
	_clear_current_scene()
	var settings_scene = preload("res://scenes/settings_menu.tscn").instantiate()
	add_child(settings_scene)
	current_scene = settings_scene
	if settings_scene.has_signal("back_to_menu_pressed"):
		settings_scene.connect("back_to_menu_pressed", load_main_menu)

func load_gallery_menu():
	_clear_current_scene()
	var gallery_scene = preload("res://scenes/gallery_menu.tscn").instantiate()
	add_child(gallery_scene)
	current_scene = gallery_scene
	if gallery_scene.has_signal("back_to_menu_pressed"):
		gallery_scene.connect("back_to_menu_pressed", load_main_menu)

func load_level_select():
	_clear_current_scene()
	var level_select_scene = preload("res://scenes/level_select.tscn").instantiate()
	add_child(level_select_scene)
	current_scene = level_select_scene
	if level_select_scene.has_signal("level_selected"):
		level_select_scene.connect("level_selected", load_level)
	if level_select_scene.has_signal("back_to_menu_pressed"):
		level_select_scene.connect("back_to_menu_pressed", Callable(self, "load_main_menu"))

func load_level(level_data: Resource):
	_clear_current_scene()
	var level_scene = preload("res://scenes/level.tscn").instantiate()
	add_child(level_scene)
	current_scene = level_scene
	if level_scene.has_method("set_level_data"):
		level_scene.set_level_data(level_data)
	if level_scene.has_signal("level_completed"):
		level_scene.connect("level_completed", _on_level_completed)
	if level_scene.has_signal("back_to_menu_pressed"):
		level_scene.connect("back_to_menu_pressed", load_main_menu)
	if level_scene.has_signal("level_select_pressed"):
		level_scene.connect("level_select_pressed", load_level_select)
	if level_scene.has_signal("next_level_pressed"):
		level_scene.connect("next_level_pressed", _on_next_level_pressed)

func _on_level_completed():
	print("[Nonogram Debug] Level completion signal received")

func _on_next_level_pressed(completed_level: LevelData):
	var current_index = levels.find(completed_level)
	var next_index = 0 if current_index == -1 else (current_index + 1) % levels.size()
	load_level(levels[next_index])

func _clear_current_scene():
	if current_scene:
		current_scene.queue_free()
		current_scene = null
		
func quit_game():
		get_tree().quit()
