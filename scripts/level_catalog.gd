extends RefCounted
class_name LevelCatalog

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
		for level in range(10):
			var data := LevelData.new()
			data.chapter_index = chapter
			data.level_index = level
			data.level_name = "Глава %d · Уровень %d" % [chapter + 1, level + 1]
			data.grid_size = 5
			data.preview_color = CHAPTERS[chapter].color
			data.solution = _make_solution(chapter, level)
			result.append(data)
	return result

static func _make_solution(chapter: int, level: int) -> Array:
	var grid := []
	for y in range(5):
		var row := []
		for x in range(5):
			# Each card has a stable, recognizable thumbnail and a valid puzzle.
			var seed: int = (x * 11 + y * 7 + level * 5 + chapter * 3) % 13
			var filled := seed < 5
			if level % 3 == 0:
				filled = x == y or x + y == 4
			elif level % 3 == 1:
				filled = (x + chapter) % 4 == 0 or y == (level + chapter) % 5
			row.append(1 if filled else 0)
		grid.append(row)
	return grid
