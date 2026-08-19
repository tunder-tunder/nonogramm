extends Node

var current_scene: Node = null
var current_level_index: int = 0
var level_resources: Array = []

func _ready():
        # Предзагружаем все уровни
        level_resources = [
                preload("res://levels/level_1.tres"),
                preload("res://levels/level_2.tres")
        ]

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
                level_select_scene.connect("level_selected", load_level_by_index)

        # Кнопка назад в меню (если есть)
        if level_select_scene.has_signal("back_to_menu_pressed"):
                level_select_scene.connect("back_to_menu_pressed", load_main_menu)

func load_level_by_index(index: int):
        current_level_index = index
        if index >= 0 and index < level_resources.size():
                load_level(level_resources[index])
        else:
                print("Уровень с индексом ", index, " не найден!")
                load_main_menu()

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
        
        if level_scene.has_signal("next_level_requested"):
                level_scene.connect("next_level_requested", _on_next_level_requested)

func _on_level_completed():
        # Сигнал победы - ничего не делаем, ждем действий игрока через баннер
        pass

func _on_next_level_requested():
        # Переходим на следующий уровень
        var next_index = current_level_index + 1
        if has_level(next_index):
                load_level_by_index(next_index)
        else:
                # Если уровни закончились, возвращаемся в меню выбора уровней
                load_level_select()

func get_current_level_index() -> int:
        return current_level_index

func get_level(index: int) -> Resource:
        if index >= 0 and index < level_resources.size():
                return level_resources[index]
        return null

func has_level(index: int) -> bool:
        return index >= 0 and index < level_resources.size()
