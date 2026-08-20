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
			var global_index := chapter * 10 + level
			var data := LevelData.new()
			data.chapter_index = chapter
			data.level_index = level
			data.level_name = "Глава %d · Уровень %d" % [chapter + 1, level + 1]
			# Smooth campaign curve: 3×3 on the first puzzle, 50×50 on the last.
			data.grid_size = roundi(3.0 + float(global_index) * 47.0 / 49.0)
			data.preview_color = CHAPTERS[chapter].color
			data.solution = _make_solution(data.grid_size, global_index)
			result.append(data)
	return result

static func _make_solution(size: int, global_index: int) -> Array:
	var grid := []
	var center := float(size - 1) / 2.0
	var thickness := 0 if global_index < 12 else (1 if global_index < 35 else 2)
	var pattern := global_index % 5
	for y in range(size):
		var row := []
		for x in range(size):
			var filled := false
			match pattern:
				0: # X — two short runs at most, suitable for the introductory puzzle.
					filled = abs(x - y) <= thickness or abs((x + y) - (size - 1)) <= thickness
				1: # Plus.
					filled = abs(float(x) - center) <= thickness or abs(float(y) - center) <= thickness
				2: # Hollow frame with a growing inset.
					var inset := maxi(1, floori(float(size) / 6.0))
					filled = ((x == inset or x == size - inset - 1) and y >= inset and y < size - inset) or ((y == inset or y == size - inset - 1) and x >= inset and x < size - inset)
				3: # Filled diamond keeps hints readable even on a 50×50 grid.
					filled = abs(float(x) - center) + abs(float(y) - center) <= center * 0.72
				4: # Two offset blocks introduce a second run later in the campaign.
					var block := maxi(1, floori(float(size) / 4.0))
					filled = (x >= 1 and x < 1 + block and y >= 1 and y < 1 + block) or (x >= size - block - 1 and x < size - 1 and y >= size - block - 1 and y < size - 1)
			row.append(1 if filled else 0)
		grid.append(row)
	return grid
