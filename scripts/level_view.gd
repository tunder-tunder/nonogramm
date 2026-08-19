extends Control

signal level_completed()
signal back_to_menu_pressed()

var level_data: LevelData
var player_grid: Array = []  # Состояние игрока: 0 - пусто, 1 - закрашено, 2 - помечено крестиком
var cell_size: int = 60

@onready var row_hints_container: VBoxContainer = $RowHintsContainer
@onready var col_hints_container: HBoxContainer = $ColHintsContainer
@onready var main_grid_container: GridContainer = $MainGridContainer
@onready var level_label: Label = $LevelLabel
@onready var check_button: Button = $CheckButton
@onready var back_button: Button = $BackButton
@onready var victory_banner: Panel = $VictoryBanner

# Цвета с высоким контрастом
const COLOR_FILLED = Color(0.0, 0.0, 0.0)      # Черный для закрашенных ЛКМ
const COLOR_EMPTY = Color(1.0, 1.0, 1.0)       # Белый для пустых
const COLOR_CROSS = Color(0.0, 0.5, 1.0)       # Синий для отмеченных ПКМ
const COLOR_GRID_BORDER = Color(0.0, 0.0, 0.0) # Черные границы

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

func _create_grid_ui():
	# Очищаем предыдущие элементы
	for child in main_grid_container.get_children():
		child.queue_free()
	for child in row_hints_container.get_children():
		child.queue_free()
	for child in col_hints_container.get_children():
		child.queue_free()
	
	# Создаем подсказки для столбцов (сверху)
	var col_hints = _calculate_col_hints()
	for x in range(level_data.grid_size):
		var hint_label = Label.new()
		hint_label.text = "\n".join(col_hints[x])
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		hint_label.custom_minimum_size = Vector2(cell_size, 60)
		col_hints_container.add_child(hint_label)
	
	# Пустой угол над подсказками строк
	var corner = Control.new()
	corner.custom_minimum_size = Vector2(60, 60)
	main_grid_container.add_child(corner)
	
	# Добавляем контейнер для подсказок столбцов
	main_grid_container.add_child(col_hints_container)
	
	# Создаем подсказки для строк (слева) и клетки сетки
	var row_hints = _calculate_row_hints()
	for y in range(level_data.grid_size):
		# Подсказка для строки
		var hint_label = Label.new()
		hint_label.text = " ".join(row_hints[y])
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint_label.custom_minimum_size = Vector2(60, cell_size)
		row_hints_container.add_child(hint_label)
		
		# Контейнер для клеток строки
		var row_container = HBoxContainer.new()
		for x in range(level_data.grid_size):
			var button = Button.new()
			button.custom_minimum_size = Vector2(cell_size, cell_size)
			button.name = "Cell_%d_%d" % [x, y]
			button.set_meta("cell_x", x)
			button.set_meta("cell_y", y)
			button.connect("pressed", _on_cell_left_clicked.bind(x, y))
			button.connect("gui_input", _on_cell_gui_input.bind(x, y))
			row_container.add_child(button)
		
		# Добавляем подсказку строки и клетки в основную сетку
		main_grid_container.add_child(row_hints_container.get_child(y))
		main_grid_container.add_child(row_container)
	
	_update_grid_visuals()

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

func _on_cell_gui_input(event: InputEvent, x: int, y: int):
	# Правый клик: постановка синего крестика
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
			var button = get_button(x, y)
			if button:
				if player_grid[y][x] == 1:
					# Закрашенная клетка - черный цвет (ЛКМ)
					button.self_modulate = COLOR_FILLED
					button.text = ""
				elif player_grid[y][x] == 2:
					# Крестик - синий цвет (ПКМ)
					button.self_modulate = COLOR_CROSS
					button.text = "✕"
				else:
					# Пустая клетка - белый цвет
					button.self_modulate = COLOR_EMPTY
					button.text = ""

func get_button(x: int, y: int) -> Button:
	# Находим кнопку по координатам x, y
	for child in main_grid_container.get_children():
		if child is HBoxContainer:
			for button in child.get_children():
				if button is Button and button.has_meta("cell_x"):
					if button.get_meta("cell_x") == x and button.get_meta("cell_y") == y:
						return button
	return null

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
