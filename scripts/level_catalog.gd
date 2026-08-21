extends RefCounted
class_name LevelCatalog

const LEVELS_PER_CHAPTER := 10
const LEVEL_TEMPLATE_PATH := "res://levels/solutions/level_%02d.txt"

const CHAPTERS := [
	{"title": "Лес светлячков", "subtitle": "Тихие тропы", "icon": "🌿", "companion_names": "Лесные друзья", "companion_paths": ["res://assets/companions/chapter_01_a.png", "res://assets/companions/chapter_01_b.png"], "gallery_path": "res://assets/gallery/chapter_01.png", "color": Color("75b798"), "reward": "Ночной пикник"},
	{"title": "Медовая деревня", "subtitle": "Тёплые крыши", "icon": "🍯", "companion_names": "Медовые друзья", "companion_paths": ["res://assets/companions/chapter_02_a.png", "res://assets/companions/chapter_02_b.png"], "gallery_path": "res://assets/gallery/chapter_02.png", "color": Color("e6ad5c"), "reward": "Праздник фонарей"},
	{"title": "Облачный порт", "subtitle": "Выше ветра", "icon": "☁️", "companion_names": "Небесные друзья", "companion_paths": ["res://assets/companions/chapter_03_a.png", "res://assets/companions/chapter_03_b.png"], "gallery_path": "res://assets/gallery/chapter_03.png", "color": Color("70aee8"), "reward": "Полёт над городом"},
	{"title": "Сад созвездий", "subtitle": "Цветы и звёзды", "icon": "🌙", "companion_names": "Звёздные друзья", "companion_paths": ["res://assets/companions/chapter_04_a.png", "res://assets/companions/chapter_04_b.png"], "gallery_path": "res://assets/gallery/chapter_04.png", "color": Color("9d83d7"), "reward": "Звёздный сад"},
	{"title": "Хрустальный берег", "subtitle": "Последнее путешествие", "icon": "💎", "companion_names": "Морские друзья", "companion_paths": ["res://assets/companions/chapter_05_a.png", "res://assets/companions/chapter_05_b.png"], "gallery_path": "res://assets/gallery/chapter_05.png", "color": Color("55c4c7"), "reward": "Рассвет у моря"}
]

static func create_levels() -> Array[LevelData]:
	var result: Array[LevelData] = []
	for chapter in range(CHAPTERS.size()):
		for level in range(LEVELS_PER_CHAPTER):
			var global_index := chapter * LEVELS_PER_CHAPTER + level
			var data := LevelData.new()
			data.chapter_index = chapter
			data.level_index = level
			data.level_name = "Глава %d · Уровень %d" % [chapter + 1, level + 1]
			data.grid_size = _get_grid_size(global_index)
			data.preview_color = CHAPTERS[chapter].color
			data.solution = _load_solution(global_index, data.grid_size)
			result.append(data)
	return result

static func _get_grid_size(global_index: int) -> int:
	# Levels 1–5 are 5×5. Every following group of five grows by 5,
	# so each chapter advances through two clearly defined grid sizes.
	return 5 + ceili(float(maxi(global_index - 4, 0)) / 5.0) * 5

static func _load_solution(global_index: int, size: int) -> Array:
	var path := LEVEL_TEMPLATE_PATH % (global_index + 1)
	if not FileAccess.file_exists(path):
		push_error("Level solution template is missing: %s" % path)
		return _empty_solution(size)

	var template_text := FileAccess.get_file_as_string(path).trim_suffix("\n").trim_suffix("\r")
	var lines := template_text.split("\n")
	if lines.size() != size:
		push_error("%s has %d rows, expected %d" % [path, lines.size(), size])
		return _empty_solution(size)

	var solution := []
	for row_index in range(size):
		var text := lines[row_index].trim_suffix("\r")
		if text.length() != size:
			push_error("%s row %d has %d cells, expected %d" % [path, row_index + 1, text.length(), size])
			return _empty_solution(size)

		var row := []
		for cell in text:
			if cell != "." and cell != "#":
				push_error("%s contains '%s'; use only '.' and '#'" % [path, cell])
				return _empty_solution(size)
			row.append(1 if cell == "#" else 0)
		solution.append(row)
	return solution

static func _empty_solution(size: int) -> Array:
	var solution := []
	for y in range(size):
		var row := []
		row.resize(size)
		row.fill(0)
		solution.append(row)
	return solution
