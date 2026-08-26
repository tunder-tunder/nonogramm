extends RefCounted
class_name LevelCatalog

const LEVELS_PER_CHAPTER := 10
const LEVEL_TEMPLATE_PATH := "res://levels/solutions/level_%02d.txt"
const OFFICE_LEVEL_NAMES := [
	"Входящие", "Кофе-брейк", "Рабочее место", "Важный звонок", "Документы",
	"Деловая встреча", "Копия готова", "Поздний вечер", "Расчёты", "Перерыв"
]
const LEVEL_SIZES := [
	[5, 5, 10, 10, 10, 10, 10, 10, 10, 10],
	[10, 10, 10, 10, 10, 15, 15, 15, 15, 15],
	[15, 15, 15, 15, 15, 20, 20, 20, 20, 20],
	[20, 20, 20, 20, 20, 25, 25, 25, 25, 25],
	[25, 25, 30, 30, 30, 30, 30, 30, 30, 30]
]

const CHAPTERS := [
	{"title": "Розовый офис", "subtitle": "Корпоративные будни", "icon": "💼", "companion_names": "Офисные друзья", "companion_paths": ["res://assets/companions/chapter_01_a.png", "res://assets/companions/chapter_01_b.png"], "gallery_path": "res://assets/gallery/chapter_01.png", "color": Color("5b3a2e"), "secondary_color": Color("e8a6d2"), "background_color": Color("fff4fb"), "reward": "Пятничный кофе"},
	{"title": "Медовая деревня", "subtitle": "Тёплые крыши", "icon": "🍯", "companion_names": "Медовые друзья", "companion_paths": ["res://assets/companions/chapter_02_a.png", "res://assets/companions/chapter_02_b.png"], "gallery_path": "res://assets/gallery/chapter_02.png", "color": Color("9a5b20"), "secondary_color": Color("efbd69"), "background_color": Color("fff8e8"), "reward": "Праздник фонарей"},
	{"title": "Облачный порт", "subtitle": "Выше ветра", "icon": "☁️", "companion_names": "Небесные друзья", "companion_paths": ["res://assets/companions/chapter_03_a.png", "res://assets/companions/chapter_03_b.png"], "gallery_path": "res://assets/gallery/chapter_03.png", "color": Color("28668f"), "secondary_color": Color("8bc9ea"), "background_color": Color("effaff"), "reward": "Полёт над городом"},
	{"title": "Сад созвездий", "subtitle": "Цветы и звёзды", "icon": "🌙", "companion_names": "Звёздные друзья", "companion_paths": ["res://assets/companions/chapter_04_a.png", "res://assets/companions/chapter_04_b.png"], "gallery_path": "res://assets/gallery/chapter_04.png", "color": Color("59438f"), "secondary_color": Color("b49ce6"), "background_color": Color("f7f2ff"), "reward": "Звёздный сад"},
	{"title": "Хрустальный берег", "subtitle": "Последнее путешествие", "icon": "💎", "companion_names": "Морские друзья", "companion_paths": ["res://assets/companions/chapter_05_a.png", "res://assets/companions/chapter_05_b.png"], "gallery_path": "res://assets/gallery/chapter_05.png", "color": Color("247b80"), "secondary_color": Color("79d7d4"), "background_color": Color("effdfb"), "reward": "Рассвет у моря"}
]

static func create_levels() -> Array[LevelData]:
	var result: Array[LevelData] = []
	for chapter in range(CHAPTERS.size()):
		for level in range(LEVELS_PER_CHAPTER):
			var global_index := chapter * LEVELS_PER_CHAPTER + level
			var data := LevelData.new()
			data.chapter_index = chapter
			data.level_index = level
			data.level_name = OFFICE_LEVEL_NAMES[level] if chapter == 0 else "Глава %d · Уровень %d" % [chapter + 1, level + 1]
			data.grid_size = _get_grid_size(global_index)
			data.preview_color = CHAPTERS[chapter].color
			data.solution = _load_solution(global_index, data.grid_size)
			result.append(data)
	return result

static func _get_grid_size(global_index: int) -> int:
	var chapter := floori(float(global_index) / float(LEVELS_PER_CHAPTER))
	var level := global_index % LEVELS_PER_CHAPTER
	return LEVEL_SIZES[chapter][level]

static func _load_solution(global_index: int, size: int) -> Array:
	var path := LEVEL_TEMPLATE_PATH % (global_index + 1)
	if not FileAccess.file_exists(path):
		push_error("Level solution template is missing: %s" % path)
		return _empty_solution(size)

	var template_text := FileAccess.get_file_as_string(path).trim_suffix("\n").trim_suffix("\r")
	var lines: Array[String] = []
	for raw_line in template_text.split("\n"):
		var candidate := raw_line.trim_suffix("\r")
		if candidate.length() == size and _is_solution_row(candidate):
			lines.append(candidate)
	if lines.size() < size:
		push_error("%s has %d valid rows, expected %d" % [path, lines.size(), size])
		return _empty_solution(size)
	if lines.size() > size:
		# Keep the loader usable after editor merge artifacts or stale appended
		# rows: select a centered square and report the repair without aborting.
		push_warning("%s has %d valid rows, using the centered %d" % [path, lines.size(), size])
		var first_row := floori(float(lines.size() - size) / 2.0)
		lines = lines.slice(first_row, first_row + size)

	var solution := []
	for row_index in range(size):
		var text := lines[row_index]
		var row := []
		for cell in text:
			row.append(1 if cell == "#" else 0)
		solution.append(row)
	return solution

static func _is_solution_row(text: String) -> bool:
	for cell in text:
		if cell != "." and cell != "#":
			return false
	return true

static func _empty_solution(size: int) -> Array:
	var solution := []
	for y in range(size):
		var row := []
		row.resize(size)
		row.fill(0)
		solution.append(row)
	return solution
