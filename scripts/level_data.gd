extends Resource
class_name LevelData

@export var level_name: String = "Level 1"
@export var grid_size: int = 5
@export var chapter_index: int = 0
@export var level_index: int = 0
@export var preview_color: Color = Color("6f8cff")
# 2D массив: 1 - закрашенная клетка, 0 - пустая
@export var solution: Array = []

func _init():
	# Пример решения для уровня 1: простой крестик или буква T
	# Пусть будет буква "T"
	if solution.is_empty():
		solution = [
			[1, 1, 1, 1, 1],
			[0, 0, 1, 0, 0],
			[0, 0, 1, 0, 0],
			[0, 0, 1, 0, 0],
			[0, 0, 1, 0, 0]
		]

func get_id() -> String:
	return "%d:%d" % [chapter_index, level_index]
