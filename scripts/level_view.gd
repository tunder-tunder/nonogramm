extends Control

signal level_completed()
signal back_to_menu_pressed()

var level_data: LevelData
var player_grid: Array = []  # Состояние игрока: 0 - пусто, 1 - закрашено, 2 - помечено крестиком
var cell_size: int = 60
var start_offset: Vector2 = Vector2(80, 80)  # Смещение для размещения подсказок
var hint_font_size: int = 16

@onready var grid_container: Control = $GridContainer
@onready var level_label: Label = $LevelLabel
@onready var check_button: Button = $CheckButton
@onready var back_button: Button = $BackButton
@onready var victory_banner: Control = $VictoryBanner  # Баннер победы

# Цвета с высоким контрастом
const COLOR_FILLED = Color(0.0, 0.0, 0.0)  # Черный для закрашенных
const COLOR_EMPTY = Color(1.0, 1.0, 1.0)   # Белый для пустых
const COLOR_CROSS = Color(0.8, 0.8, 0.8)   # Серый для крестика
const COLOR_GRID_BORDER = Color(0.0, 0.0, 0.0)  # Черные границы

func _ready():
	back_button.connect("pressed", _on_back_pressed)
	check_button.connect("pressed", _on_check_pressed)
	# Скрываем баннер победы при старте
	if victory_banner:
		victory_banner.visible = false

func set_level_data(data: LevelData):
	level_data = data
	level_label.text = data.level_name
	
	# Инициализация сетки игрока (все пустые)
	player_grid = []
	for y in range(data.grid_size):
		var row = []
		for x in range(data.grid_size):
			row.append(0)
		player_grid.append(row)
	
	_create_grid_ui()
	_create_hints()

func _create_grid_ui():
	# Очищаем предыдущую сетку
	for child in grid_container.get_children():
		child.queue_free()
	
	grid_container.custom_minimum_size = Vector2(
		level_data.grid_size * cell_size + 40,
		level_data.grid_size * cell_size + 40
	)
	
	# Создаем клетки
	for y in range(level_data.grid_size):
		for x in range(level_data.grid_size):
			var button = Button.new()
			button.set_anchors_preset(Control.PRESET_TOP_LEFT)
			button.position = Vector2(start_offset.x + x * cell_size + 5, start_offset.y + y * cell_size + 5)
			button.size = Vector2(cell_size - 10, cell_size - 10)
			button.name = "Cell_%d_%d" % [x, y]
			button.connect("pressed", _on_cell_left_clicked.bind(x, y))
			button.connect("gui_input", _on_cell_gui_input.bind(x, y))
			grid_container.add_child(button)
	
	_update_grid_visuals()

func _create_hints():
	# Создаем подсказки для строк (слева) и столбцов (сверху)
	var row_hints = _calculate_row_hints()
	var col_hints = _calculate_col_hints()
	
	# Подсказки для столбцов (сверху)
	for x in range(level_data.grid_size):
		var label = Label.new()
		label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		label.position = Vector2(start_offset.x + x * cell_size + 10, 10)
		label.size = Vector2(cell_size - 20, 60)
		label.name = "ColHint_%d" % x
		label.text = "\n".join(col_hints[x])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.add_theme_font_size_override("font_size", hint_font_size)
		grid_container.add_child(label)
	
	# Подсказки для строк (слева)
	for y in range(level_data.grid_size):
		var label = Label.new()
		label.set_anchors_preset(Control.PRESET_TOP_LEFT)
		label.position = Vector2(10, start_offset.y + y * cell_size + 10)
		label.size = Vector2(60, cell_size - 20)
		label.name = "RowHint_%d" % y
		label.text = " ".join(row_hints[y])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", hint_font_size)
		grid_container.add_child(label)

func _calculate_row_hints() -> Array:
	var hints = []
	for y in range(level_data.grid_size):
		var row_hint = []
		var count = 0
		for x in range(level_data.grid_size):
			if level_data.solution[y][x] == 1:
				count += 1
			else:
				if count > 0:
					row_hint.append(str(count))
					count = 0
		if count > 0:
			row_hint.append(str(count))
		if row_hint.is_empty():
			row_hint.append("0")
		hints.append(row_hint)
	return hints

func _calculate_col_hints() -> Array:
	var hints = []
	for x in range(level_data.grid_size):
		var col_hint = []
		var count = 0
		for y in range(level_data.grid_size):
			if level_data.solution[y][x] == 1:
				count += 1
			else:
				if count > 0:
					col_hint.append(str(count))
					count = 0
		if count > 0:
			col_hint.append(str(count))
		if col_hint.is_empty():
			col_hint.append("0")
		hints.append(col_hint)
	return hints

func _on_cell_left_clicked(x: int, y: int):
	# Левый клик: закрашивание (0 -> 1 -> 0)
	if player_grid[y][x] == 2:
		player_grid[y][x] = 0
	elif player_grid[y][x] == 0:
		player_grid[y][x] = 1
	else:
		player_grid[y][x] = 0
	
	_update_grid_visuals()

func _on_cell_gui_input(x: int, y: int, event: InputEvent):
	# Правый клик: постановка крестика
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		get_viewport().set_input_as_handled()
		if player_grid[y][x] == 0:
			player_grid[y][x] = 2
		elif player_grid[y][x] == 2:
			player_grid[y][x] = 0
		_update_grid_visuals()

func _update_grid_visuals():
	for y in range(level_data.grid_size):
		for x in range(level_data.grid_size):
			var button = grid_container.get_node("Cell_%d_%d" % [x, y])
			if player_grid[y][x] == 1:
				# Закрашенная клетка - черный цвет
				button.self_modulate = COLOR_FILLED
				button.text = ""
			elif player_grid[y][x] == 2:
				# Крестик - серый фон с символом X
				button.self_modulate = COLOR_CROSS
				button.text = "✕"
			else:
				# Пустая клетка - белый цвет
				button.self_modulate = COLOR_EMPTY
				button.text = ""

func _on_check_pressed():
	_check_solution()

func _check_solution():
	var is_correct = true
	for y in range(level_data.grid_size):
		for x in range(level_data.grid_size):
			if player_grid[y][x] != level_data.solution[y][x]:
				is_correct = false
				break
		if not is_correct:
			break
	
	if is_correct:
		level_label.text = "Победа! Уровень пройден!"
		level_completed.emit()
		# Блокируем кнопки после победы
		check_button.disabled = true
		back_button.disabled = false
		# Показываем баннер победы
		if victory_banner:
			victory_banner.visible = true
	else:
		level_label.text = "Неверно, попробуйте еще раз!"

func _on_back_pressed():
	back_to_menu_pressed.emit()
