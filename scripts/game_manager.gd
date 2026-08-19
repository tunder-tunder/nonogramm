extends Node

var current_scene: Node = null

func _ready():
	# Создаем главное меню при старте
	load_main_menu()

func load_main_menu():
	if current_scene:
		current_scene.queue_free()
	
	var main_menu_scene = preload("res://scenes/main_menu.tscn").instantiate()
	add_child(main_menu_scene)
	current_scene = main_menu_scene
	
	# Подключаемся к сигналу начала игры
	if main_menu_scene.has_signal("start_game_pressed"):
		main_menu_scene.connect("start_game_pressed", load_level_select)

func load_level_select():
	if current_scene:
		current_scene.queue_free()
	
	var level_select_scene = preload("res://scenes/level_select.tscn").instantiate()
	add_child(level_select_scene)
	current_scene = level_select_scene
	
	# Подключаемся к сигналу выбора уровня
	if level_select_scene.has_signal("level_selected"):
		level_select_scene.connect("level_selected", load_level)
	
	# Кнопка назад в меню (если есть)
	if level_select_scene.has_signal("back_to_menu_pressed"):
		level_select_scene.connect("back_to_menu_pressed", load_main_menu)

func load_level(level_data: Resource):
	if current_scene:
		current_scene.queue_free()
	
	var level_scene = preload("res://scenes/level.tscn").instantiate()
	add_child(level_scene)
	current_scene = level_scene
	
	# Передаем данные уровня
	if level_scene.has_method("set_level_data"):
		level_scene.set_level_data(level_data)
	
	# Сигналы завершения уровня
	if level_scene.has_signal("level_completed"):
		level_scene.connect("level_completed", _on_level_completed)
	
	if level_scene.has_signal("back_to_menu_pressed"):
		level_scene.connect("back_to_menu_pressed", load_main_menu)

func _on_level_completed():
	# После победы переходим на следующий уровень или в меню выбора
	load_level_select()
