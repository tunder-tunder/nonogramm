extends Control

signal level_completed(elapsed_seconds: float)
signal back_to_menu_pressed()
signal next_level_pressed(current_level: LevelData)
signal level_select_pressed()

var level_data: LevelData
var progress: SaveData
var player_grid: Array = []  # 0 - пусто, 1 - закрашено, 2 - крестик
var cell_size: int = 60
var grid_container: GridContainer
var cell_buttons: Array = []
var cell_style_cache: Dictionary = {}
var row_hint_labels: Array = []
var col_hint_labels: Array = []
var elapsed_seconds := 0.0
var autosave_accumulator := 0.0
var level_running := false
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
@onready var companion_one: Control = $CompanionLane/CompanionOne
@onready var companion_two: Control = $CompanionLane/CompanionTwo
@onready var companion_one_texture: TextureRect = $CompanionLane/CompanionOne/Texture
@onready var companion_two_texture: TextureRect = $CompanionLane/CompanionTwo/Texture
@onready var timer_label: Label = $InfoBanner/InfoRow/TimerLabel
@onready var size_label: Label = $InfoBanner/InfoRow/SizeLabel
@onready var victory_message: Label = $VictoryBanner/VictoryMessage
var companion_time := 0.0

const COLOR_FILLED = Color(0.12, 0.38, 0.85)       # Синий для ЛКМ
const COLOR_EMPTY = Color.WHITE                    # Белая нейтральная клетка
const COLOR_CROSS = Color(0.12, 0.38, 0.85)        # Синий крестик для ПКМ
const COLOR_GRID_BORDER = Color("dfe4eb")
const COLOR_GRID_GROUP = Color("c9d0da")
const COLOR_GRID_MAJOR_GROUP = Color("aeb8c6")
const COLOR_HINT = Color("26364d")
const COLOR_HINT_SOLVED = Color("8b96a6")

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
	if level_running:
		elapsed_seconds += delta
		autosave_accumulator += delta
		timer_label.text = "ВРЕМЯ  %s" % SaveData.format_time(elapsed_seconds)
		if autosave_accumulator >= 5.0 and progress:
			autosave_accumulator = 0.0
			progress.save_draft(level_data, player_grid, elapsed_seconds)

func configure(data: LevelData, save_data: SaveData) -> void:
	progress = save_data
	set_level_data(data)

func set_level_data(data: LevelData):
	level_data = data
	level_label.text = "%s  ·  %d×%d" % [data.level_name, data.grid_size, data.grid_size]
	cell_size = clampi(floori(440.0 / float(data.grid_size)), 8, 60)
	elapsed_seconds = progress.get_elapsed_time(data) if progress else 0.0
	autosave_accumulator = 0.0
	level_running = not (progress and progress.is_completed(data.chapter_index, data.level_index))
	timer_label.text = "ВРЕМЯ  %s" % SaveData.format_time(elapsed_seconds)
	size_label.text = "ПОЛЕ  %d × %d  ·  %d КЛЕТОК" % [data.grid_size, data.grid_size, data.grid_size * data.grid_size]
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
	_load_companion(companion_one_texture, $CompanionLane/CompanionOne/Placeholder, chapter.companion_paths[0])
	_load_companion(companion_two_texture, $CompanionLane/CompanionTwo/Placeholder, chapter.companion_paths[1])
	$CompanionLane/ChapterName.text = "%s · компаньоны главы" % chapter.title
	_create_grid_ui()
	_log_debug("Loaded %s (%dx%d)" % [data.level_name, data.grid_size, data.grid_size])

func _load_companion(target: TextureRect, placeholder: Label, path: String) -> void:
	if ResourceLoader.exists(path, "Texture2D"):
		target.texture = load(path)
		target.visible = true
		placeholder.visible = false
	else:
		target.texture = null
		target.visible = false
		placeholder.visible = true

func _create_grid_ui():
	for child in main_grid_container.get_children():
		child.queue_free()
	for child in row_hints_container.get_children():
		child.queue_free()
	for child in col_hints_container.get_children():
		child.queue_free()

	grid_container = GridContainer.new()
	grid_container.columns = level_data.grid_size + 1
	grid_container.add_theme_constant_override("h_separation", 0)
	grid_container.add_theme_constant_override("v_separation", 0)
	cell_buttons = []
	cell_style_cache.clear()
	row_hint_labels = []
	col_hint_labels = []
	var hint_size := 76
	var hint_font_size := clampi(cell_size - 1, 7, 16)

	var corner = Control.new()
	corner.custom_minimum_size = Vector2(hint_size, hint_size)
	grid_container.add_child(corner)

	var col_hints = _calculate_col_hints()
	for x in range(level_data.grid_size):
		var hint_box := VBoxContainer.new()
		hint_box.custom_minimum_size = Vector2(cell_size, hint_size)
		hint_box.alignment = BoxContainer.ALIGNMENT_END
		hint_box.add_theme_constant_override("separation", 0)
		var labels: Array[Label] = []
		for clue in col_hints[x]:
			var hint_label := _create_hint_label(clue, hint_font_size, true)
			hint_box.add_child(hint_label)
			labels.append(hint_label)
		grid_container.add_child(hint_box)
		col_hint_labels.append(labels)

	var row_hints = _calculate_row_hints()
	for y in range(level_data.grid_size):
		var hint_box := HBoxContainer.new()
		hint_box.custom_minimum_size = Vector2(hint_size, cell_size)
		hint_box.alignment = BoxContainer.ALIGNMENT_END
		hint_box.add_theme_constant_override("separation", 3)
		var labels: Array[Label] = []
		for clue in row_hints[y]:
			var hint_label := _create_hint_label(clue, hint_font_size, false)
			hint_box.add_child(hint_label)
			labels.append(hint_label)
		grid_container.add_child(hint_box)
		row_hint_labels.append(labels)
		var button_row: Array[Button] = []
		for x in range(level_data.grid_size):
			var button := Button.new()
			button.custom_minimum_size = Vector2(cell_size, cell_size)
			button.name = "Cell_%d_%d" % [x, y]
			button.focus_mode = Control.FOCUS_NONE
			button.set_meta("cell_x", x)
			button.set_meta("cell_y", y)
			button.connect("gui_input", _on_cell_gui_input.bind(x, y))
			grid_container.add_child(button)
			button_row.append(button)
		cell_buttons.append(button_row)

	main_grid_container.add_child(grid_container)
	_update_grid_visuals()
	_update_all_hint_states()

func _create_hint_label(text: String, font_size: int, column_hint: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if column_hint else HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(cell_size if column_hint else 0, font_size + 1 if column_hint else cell_size)
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", COLOR_HINT)
	return label

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
		var row_action: bool = event.button_index == MOUSE_BUTTON_LEFT and bool(event.shift_pressed)
		if row_action:
			_toggle_full_row(y)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			player_grid[y][x] = 0 if player_grid[y][x] == 1 else 1
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			player_grid[y][x] = 0 if player_grid[y][x] == 2 else 2
		else:
			return
		if not row_action:
			_update_cell_visual(x, y)
		_update_hint_states(y, x)
		if progress:
			progress.save_draft(level_data, player_grid, elapsed_seconds)
		_log_debug("Cell (%d,%d) -> %d" % [x, y, player_grid[y][x]])

func _update_grid_visuals():
	for y in range(level_data.grid_size):
		for x in range(level_data.grid_size):
			_update_cell_visual(x, y)

func _toggle_full_row(y: int) -> void:
	var all_filled := true
	for x in range(level_data.grid_size):
		if player_grid[y][x] != 1:
			all_filled = false
			break
	var new_value := 0 if all_filled else 1
	for x in range(level_data.grid_size):
		player_grid[y][x] = new_value
		_update_cell_visual(x, y)
	_update_all_hint_states()

func _update_cell_visual(x: int, y: int) -> void:
	var button := get_button(x, y)
	if not button:
		return
	button.text = ""
	button.add_theme_color_override("font_color", COLOR_CROSS)
	button.add_theme_color_override("font_hover_color", COLOR_CROSS)
	button.add_theme_color_override("font_pressed_color", COLOR_CROSS)
	button.add_theme_font_size_override("font_size", clampi(cell_size - 1, 7, 18))
	if player_grid[y][x] == 1:
		_apply_cell_style(button, COLOR_FILLED, x, y)
	elif player_grid[y][x] == 2:
		_apply_cell_style(button, COLOR_EMPTY, x, y)
		button.text = "✕" if cell_size >= 12 else "·"
	else:
		_apply_cell_style(button, COLOR_EMPTY, x, y)

func _apply_cell_style(button: Button, fill_color: Color, x: int, y: int):
	var right_group := 2 if (x + 1) % 10 == 0 else (1 if (x + 1) % 5 == 0 else 0)
	var bottom_group := 2 if (y + 1) % 10 == 0 else (1 if (y + 1) % 5 == 0 else 0)
	var key := "%d:%d:%d" % [1 if fill_color == COLOR_FILLED else 0, right_group, bottom_group]
	if not cell_style_cache.has(key):
		cell_style_cache[key] = _create_cell_style(fill_color, right_group, bottom_group)
	var style: StyleBoxFlat = cell_style_cache[key]
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)

func _create_cell_style(fill_color: Color, right_group: int, bottom_group: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = COLOR_GRID_MAJOR_GROUP if right_group == 2 or bottom_group == 2 else (COLOR_GRID_GROUP if right_group == 1 or bottom_group == 1 else COLOR_GRID_BORDER)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 3 if right_group == 2 else (2 if right_group == 1 else 1)
	style.border_width_bottom = 3 if bottom_group == 2 else (2 if bottom_group == 1 else 1)
	return style

func _update_hint_states(row: int, column: int) -> void:
	_update_row_hint_states(row)
	_update_column_hint_states(column)

func _update_all_hint_states() -> void:
	for index in range(level_data.grid_size):
		_update_row_hint_states(index)
		_update_column_hint_states(index)

func _set_hint_solved(label: Label, solved: bool) -> void:
	label.add_theme_color_override("font_color", COLOR_HINT_SOLVED if solved else COLOR_HINT)
	label.modulate.a = 0.72 if solved else 1.0

func _update_row_hint_states(row: int) -> void:
	var expected := _get_runs(level_data.solution[row])
	var actual_values := []
	for value in player_grid[row]:
		actual_values.append(1 if value == 1 else 0)
	var actual := _get_runs(actual_values)
	if expected.is_empty():
		_set_hint_solved(row_hint_labels[row][0], actual.is_empty())
		return
	for index in range(row_hint_labels[row].size()):
		_set_hint_solved(row_hint_labels[row][index], index < expected.size() and actual.has(expected[index]))

func _update_column_hint_states(column: int) -> void:
	var expected_values := []
	var actual_values := []
	for row in range(level_data.grid_size):
		expected_values.append(level_data.solution[row][column])
		actual_values.append(1 if player_grid[row][column] == 1 else 0)
	var expected := _get_runs(expected_values)
	var actual := _get_runs(actual_values)
	if expected.is_empty():
		_set_hint_solved(col_hint_labels[column][0], actual.is_empty())
		return
	for index in range(col_hint_labels[column].size()):
		_set_hint_solved(col_hint_labels[column][index], index < expected.size() and actual.has(expected[index]))

func _get_runs(values: Array) -> Array:
	var runs := []
	var start := -1
	for index in range(values.size() + 1):
		var filled := index < values.size() and int(values[index]) == 1
		if filled and start == -1:
			start = index
		elif not filled and start != -1:
			runs.append(Vector2i(start, index - start))
			start = -1
	return runs

func get_button(x: int, y: int) -> Button:
	if y < 0 or y >= cell_buttons.size() or x < 0 or x >= cell_buttons[y].size():
		return null
	return cell_buttons[y][x]

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
		level_running = false
		level_label.text = "Победа! Уровень пройден!"
		victory_message.text = "🎉 Поздравляем! 🎉\nВы решили поле %d×%d за %s" % [level_data.grid_size, level_data.grid_size, SaveData.format_time(elapsed_seconds)]
		level_completed.emit(elapsed_seconds)
		check_button.disabled = true
		victory_banner.visible = true
		_log_debug("Level completed: %s" % level_data.level_name)
	else:
		level_label.text = "Неверно, попробуйте еще раз!"

func _on_back_pressed():
	if progress and level_data and not progress.is_completed(level_data.chapter_index, level_data.level_index):
		progress.save_draft(level_data, player_grid, elapsed_seconds)
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
