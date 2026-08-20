extends Control

signal level_completed()
signal back_to_menu_pressed()
signal next_level_pressed(current_level: LevelData)
signal level_select_pressed()

var level_data: LevelData
var progress: SaveData
var player_grid: Array = []  # 0 - пусто, 1 - закрашено, 2 - крестик
var cell_size: int = 60
var grid_container: GridContainer
var _debug_enabled := OS.is_debug_build()

@onready var row_hints_container: VBoxContainer = $RowHintsContainer
@onready var col_hints_container: HBoxContainer = $ColHintsContainer
@onready var main_grid_container: GridContainer = $MainGridContainer
@onready var level_label: Label = $LevelLabel
@onready var check_button: Button = $CheckButton
@onready var back_button: Button = $BackButton
@onready var victory_banner: Panel = $VictoryBanner
@onready var victory_level_select_button: Button = $VictoryBanner/VictoryActions/LevelSelectButton
@onready var victory_next_button: Button = $VictoryBanner/VictoryActions/NextLevelButton
@onready var debug_label: Label = $DebugLabel
@onready var companion_one: Label = $CompanionLane/CompanionOne
@onready var companion_two: Label = $CompanionLane/CompanionTwo
var companion_time := 0.0

const COLOR_FILLED = Color(0.12, 0.38, 0.85)       # Синий для ЛКМ
const COLOR_EMPTY = Color.WHITE                    # Белая нейтральная клетка
const COLOR_CROSS = Color(0.12, 0.38, 0.85)        # Синий крестик для ПКМ
const COLOR_GRID_BORDER = Color(0.12, 0.38, 0.85)

func _ready():
	back_button.connect("pressed", _on_back_pressed)
	check_button.connect("pressed", _on_check_pressed)
	victory_level_select_button.connect("pressed", _on_level_select_pressed)
	victory_next_button.connect("pressed", _on_next_level_pressed)
	victory_banner.visible = false
	debug_label.visible = _debug_enabled
	_log_debug("Level view ready")

func _process(delta: float) -> void:
	companion_time += delta
	companion_one.position.x = fmod(companion_time * 48.0, maxf(size.x - 90.0, 1.0))
	companion_two.position.x = fmod(companion_time * 35.0 + size.x * 0.45, maxf(size.x - 90.0, 1.0))
	companion_one.position.y = 7.0 + absf(sin(companion_time * 4.2)) * -10.0
	companion_two.position.y = 8.0 + absf(sin(companion_time * 3.5 + 1.0)) * -8.0

func configure(data: LevelData, save_data: SaveData) -> void:
	progress = save_data
	set_level_data(data)

func set_level_data(data: LevelData):
	level_data = data
	level_label.text = data.level_name
	check_button.disabled = false
	victory_banner.visible = false
	_validate_level_data()
	player_grid = []
	for y in range(data.grid_size):
		var row = []
		for x in range(data.grid_size):
			row.append(0)
		player_grid.append(row)
	var draft := progress.get_draft(data) if progress else []
	if draft.size() == data.grid_size:
		player_grid = draft
	var chapter: Dictionary = LevelCatalog.CHAPTERS[data.chapter_index]
	companion_one.text = chapter.companion
	companion_two.text = chapter.companion_alt
	$CompanionLane/ChapterName.text = "%s · компаньоны главы" % chapter.title
	_create_grid_ui()
	_log_debug("Loaded %s (%dx%d)" % [data.level_name, data.grid_size, data.grid_size])

func _create_grid_ui():
	for child in main_grid_container.get_children():
		child.queue_free()
	for child in row_hints_container.get_children():
		child.queue_free()
	for child in col_hints_container.get_children():
		child.queue_free()

	grid_container = GridContainer.new()
	grid_container.columns = level_data.grid_size + 1

	var corner = Control.new()
	corner.custom_minimum_size = Vector2(60, 60)
	grid_container.add_child(corner)

	var col_hints = _calculate_col_hints()
	for x in range(level_data.grid_size):
		var hint_label = Label.new()
		hint_label.text = "\n".join(col_hints[x])
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		hint_label.custom_minimum_size = Vector2(cell_size, 60)
		grid_container.add_child(hint_label)

	var row_hints = _calculate_row_hints()
	for y in range(level_data.grid_size):
		var hint_label = Label.new()
		hint_label.text = " ".join(row_hints[y])
		hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint_label.custom_minimum_size = Vector2(60, cell_size)
		grid_container.add_child(hint_label)
		for x in range(level_data.grid_size):
			var button = Button.new()
			button.custom_minimum_size = Vector2(cell_size, cell_size)
			button.name = "Cell_%d_%d" % [x, y]
			button.focus_mode = Control.FOCUS_NONE
			button.set_meta("cell_x", x)
			button.set_meta("cell_y", y)
			button.connect("gui_input", _on_cell_gui_input.bind(x, y))
			grid_container.add_child(button)

	main_grid_container.add_child(grid_container)
	_update_grid_visuals()

func _calculate_row_hints() -> Array:
	var hints = []
	for y in range(level_data.grid_size):
		var row_hint = []
		var count = 0
		for x in range(level_data.grid_size):
			if level_data.solution[y][x] == 1:
				count += 1
			elif count > 0:
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
			elif count > 0:
				col_hint.append(str(count))
				count = 0
		if count > 0:
			col_hint.append(str(count))
		if col_hint.is_empty():
			col_hint.append("0")
		hints.append(col_hint)
	return hints

func _on_cell_gui_input(event: InputEvent, x: int, y: int):
	if event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		if event.button_index == MOUSE_BUTTON_LEFT:
			player_grid[y][x] = 0 if player_grid[y][x] == 1 else 1
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			player_grid[y][x] = 0 if player_grid[y][x] == 2 else 2
		else:
			return
		_update_grid_visuals()
		if progress:
			progress.save_draft(level_data, player_grid)
		_log_debug("Cell (%d,%d) -> %d" % [x, y, player_grid[y][x]])

func _update_grid_visuals():
	for y in range(level_data.grid_size):
		for x in range(level_data.grid_size):
			var button = get_button(x, y)
			if button:
				button.text = ""
				button.add_theme_color_override("font_color", COLOR_CROSS)
				button.add_theme_color_override("font_hover_color", COLOR_CROSS)
				button.add_theme_color_override("font_pressed_color", COLOR_CROSS)
				if player_grid[y][x] == 1:
					_apply_cell_style(button, COLOR_FILLED)
				elif player_grid[y][x] == 2:
					_apply_cell_style(button, COLOR_EMPTY)
					button.text = "✕"
				else:
					_apply_cell_style(button, COLOR_EMPTY)

func _apply_cell_style(button: Button, fill_color: Color):
	var style = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = COLOR_GRID_BORDER
	style.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)

func get_button(x: int, y: int) -> Button:
	if not grid_container:
		return null
	for child in grid_container.get_children():
		if child is Button and child.has_meta("cell_x") and child.get_meta("cell_x") == x and child.get_meta("cell_y") == y:
			return child
	return null

func _on_check_pressed():
	_check_solution()

func _check_solution():
	var is_correct = true
	for y in range(level_data.grid_size):
		for x in range(level_data.grid_size):
			var expected = level_data.solution[y][x]
			var actual = 1 if player_grid[y][x] == 1 else 0
			if actual != expected:
				is_correct = false
				_log_debug("Mismatch at (%d,%d): expected %d, actual %d" % [x, y, expected, actual])
				break
		if not is_correct:
			break
	if is_correct:
		level_label.text = "Победа! Уровень пройден!"
		level_completed.emit()
		check_button.disabled = true
		victory_banner.visible = true
		_log_debug("Level completed: %s" % level_data.level_name)
	else:
		level_label.text = "Неверно, попробуйте еще раз!"

func _on_back_pressed():
	back_to_menu_pressed.emit()

func _on_level_select_pressed():
	level_select_pressed.emit()

func _on_next_level_pressed():
	next_level_pressed.emit(level_data)

func _validate_level_data():
	if not level_data:
		push_error("LevelData is missing")
		return
	if level_data.solution.size() != level_data.grid_size:
		push_warning("%s has %d rows, expected %d" % [level_data.level_name, level_data.solution.size(), level_data.grid_size])
	for y in range(level_data.solution.size()):
		if level_data.solution[y].size() != level_data.grid_size:
			push_warning("%s row %d has %d columns, expected %d" % [level_data.level_name, y, level_data.solution[y].size(), level_data.grid_size])

func _log_debug(message: String):
	if not _debug_enabled:
		return
	var text = "[Nonogram Debug] %s" % message
	print(text)
	if debug_label:
		debug_label.text = text
