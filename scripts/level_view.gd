extends Control

signal level_completed()
signal back_to_menu_pressed()

var level_data: LevelData
var player_grid: Array = []  # Состояние игрока: 0 - пусто, 1 - закрашено, 2 - помечено крестиком (опционально)
var cell_size: int = 60
var start_offset: Vector2 = Vector2(20, 20)

@onready var grid_container: Control = $GridContainer
@onready var level_label: Label = $LevelLabel
@onready var check_button: Button = $CheckButton
@onready var back_button: Button = $BackButton

func _ready():
	back_button.connect("pressed", _on_back_pressed)
	check_button.connect("pressed", _on_check_pressed)

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
			button.connect("pressed", _on_cell_pressed.bind(x, y))
			grid_container.add_child(button)
	
	_update_grid_visuals()

func _on_cell_pressed(x: int, y: int):
	# Циклическое переключение: 0 -> 1 -> 0 (упрощенно: только закрашивание/снятие)
	if player_grid[y][x] == 0:
		player_grid[y][x] = 1
	else:
		player_grid[y][x] = 0
	
	_update_grid_visuals()

func _update_grid_visuals():
	for y in range(level_data.grid_size):
		for x in range(level_data.grid_size):
			var button = grid_container.get_node("Cell_%d_%d" % [x, y])
			if player_grid[y][x] == 1:
				button.color = Color(0.2, 0.6, 1.0)  # Синий цвет для закрашенных
				button.text = ""
			else:
				button.color = Color(0.8, 0.8, 0.8)  # Серый для пустых
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
	else:
		level_label.text = "Неверно, попробуйте еще раз!"

func _on_back_pressed():
	back_to_menu_pressed.emit()
