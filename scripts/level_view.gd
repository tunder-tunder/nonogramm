extends Control

signal level_completed()
signal back_to_menu_pressed()
signal next_level_requested()

var level_data: LevelData
var player_grid: Array = []  # Состояние игрока: 0 - пусто, 1 - закрашено, 2 - помечено крестиком
var cell_size: int = 60
var grid_container: GridContainer
var theme_resource: Theme

# Debug flag
var DEBUG_MODE: bool = true

@onready var row_hints_container: VBoxContainer = $RowHintsContainer
@onready var col_hints_container: HBoxContainer = $ColHintsContainer
@onready var main_grid_container: GridContainer = $MainGridContainer
@onready var level_label: Label = $LevelLabel
@onready var check_button: Button = $CheckButton
@onready var back_button: Button = $BackButton
@onready var victory_banner: Panel = $VictoryBanner
@onready var victory_vbox: VBoxContainer = $VictoryBanner/VictoryVBox
@onready var victory_message: Label = $VictoryBanner/VictoryVBox/VictoryMessage
@onready var victory_buttons_container: HBoxContainer = $VictoryBanner/VictoryVBox/VictoryButtonsContainer
@onready var menu_button: Button = $VictoryBanner/VictoryVBox/VictoryButtonsContainer/MenuButton
@onready var next_level_button: Button = $VictoryBanner/VictoryVBox/VictoryButtonsContainer/NextLevelButton

func _debug_print(msg: String):
	if DEBUG_MODE:
		print("[LevelView DEBUG] ", msg)

func _ready():
	_debug_print("_ready() called")
	
	# Загружаем тему
	theme_resource = load("res://NonogramTheme.tres")
	
	_debug_print("Theme loaded: %s" % str(theme_resource != null))
	
	# Проверяем что тема загрузилась корректно
	if not theme_resource:
		push_error("Failed to load NonogramTheme.tres!")
		return
	
	# Проверяем наличие стилей в теме (используем кастомные стили)
	_debug_print("Checking styles in theme...")
	var has_empty = theme_resource.has_stylebox("custom_empty", "Button")
	var has_filled = theme_resource.has_stylebox("custom_filled", "Button")
	var has_cross = theme_resource.has_stylebox("custom_cross", "Button")
	_debug_print("  empty: %s" % str(has_empty))
	_debug_print("  filled: %s" % str(has_filled))
	_debug_print("  cross: %s" % str(has_cross))
	
	# Применяем тему ко всем кнопкам сцены
	_apply_theme_to_buttons()
	
	back_button.connect("pressed", _on_back_pressed)
	check_button.connect("pressed", _on_check_pressed)
	
	# Подключаем кнопки баннера победы
	if menu_button:
		menu_button.connect("pressed", _on_menu_pressed)
	if next_level_button:
		next_level_button.connect("pressed", _on_next_level_pressed)
	
	# Скрываем баннер победы при старте
	if victory_banner:
		victory_banner.visible = false
		victory_banner.custom_minimum_size = Vector2(400, 150)
		victory_message.autowrap_mode = TextServer.AUTOWRAP_WORD
		victory_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		victory_message.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		if victory_buttons_container:
			victory_buttons_container.visible = false
		
		victory_banner.gui_input.connect(_on_banner_click)

func set_level_data(data: LevelData):
	level_data = data
	level_label.text = data.level_name
	
	player_grid = []
	for y in range(data.grid_size):
		var row = []
		for x in range(data.grid_size):
			row.append(0)
		player_grid.append(row)
	
	_create_grid_ui()
	# Инициализируем визуальное состояние ячеек после создания сетки
	_update_grid_visuals()

func _create_grid_ui():
    for child in main_grid_container.get_children():
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
            button.set_meta("cell_x", x)
            button.set_meta("cell_y", y)
            
            # Применяем начальный стиль (empty) сразу при создании
            if theme_resource:
                var empty_style = theme_resource.get_stylebox("custom_empty", "Button")
                if empty_style:
                    _debug_print("Creating cell (%d,%d) with empty style" % [x, y])
                    button.add_theme_stylebox_override("normal", empty_style.duplicate())
                    button.add_theme_stylebox_override("hover", empty_style.duplicate())
                    button.add_theme_stylebox_override("pressed", empty_style.duplicate())
                    button.add_theme_stylebox_override("disabled", empty_style.duplicate())
                    button.add_theme_stylebox_override("focused", empty_style.duplicate())
                else:
                    _debug_print("WARNING: empty style not found in theme!")
            
            button.focus_mode = Control.FOCUS_NONE
            button.text = ""
            
            button.gui_input.connect(Callable(self, "_on_cell_gui_input").bind(x, y))
            grid_container.add_child(button)
    
    main_grid_container.add_child(grid_container)
    _debug_print("Grid UI created with %dx%d cells" % [level_data.grid_size, level_data.grid_size])

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

func _on_cell_gui_input(event: InputEvent, x: int, y: int):
    if event is InputEventMouseButton and event.pressed:
        get_viewport().set_input_as_handled()
        
        var current_state = player_grid[y][x]
        _debug_print("_on_cell_gui_input button=%s x=%d y=%d current_state=%d" % 
            ["LEFT" if event.button_index == MOUSE_BUTTON_LEFT else "RIGHT" if event.button_index == MOUSE_BUTTON_RIGHT else "OTHER", x, y, current_state])
        
        if event.button_index == MOUSE_BUTTON_LEFT:
            if current_state == 0:
                player_grid[y][x] = 1
                _debug_print("  LKM: state 0 -> 1 (filled)")
            elif current_state == 1:
                player_grid[y][x] = 0
                _debug_print("  LKM: state 1 -> 0 (empty)")
            elif current_state == 2:
                player_grid[y][x] = 1
                _debug_print("  LKM: state 2 -> 1 (filled)")
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            if current_state == 0:
                player_grid[y][x] = 2
                _debug_print("  PKM: state 0 -> 2 (cross)")
            elif current_state == 2:
                player_grid[y][x] = 0
                _debug_print("  PKM: state 2 -> 0 (empty)")
            elif current_state == 1:
                player_grid[y][x] = 2
                _debug_print("  PKM: state 1 -> 2 (cross)")
        
        # Принудительно обновляем стили кнопки сразу после изменения состояния
        _update_single_cell(x, y)

func _update_single_cell(x: int, y: int):
    var button = get_button(x, y)
    if not button:
        return
    
    _debug_print("_update_single_cell(%d, %d) state=%d" % [x, y, player_grid[y][x]])
    
    # Полностью очищаем все переопределения стилей и цветов
    button.remove_theme_stylebox_override("normal")
    button.remove_theme_stylebox_override("hover")
    button.remove_theme_stylebox_override("pressed")
    button.remove_theme_stylebox_override("disabled")
    button.remove_theme_stylebox_override("focused")
    button.remove_theme_color_override("font_color")
    button.remove_theme_font_size_override("font_size")
    
    var style: StyleBox
    if player_grid[y][x] == 0:
        style = theme_resource.get_stylebox("custom_empty", "Button")
        button.text = ""
        _debug_print("  Applying empty style")
    elif player_grid[y][x] == 1:
        style = theme_resource.get_stylebox("custom_filled", "Button")
        button.text = ""
        _debug_print("  Applying filled style (blue)")
    elif player_grid[y][x] == 2:
        style = theme_resource.get_stylebox("custom_cross", "Button")
        # Не устанавливаем текст для крестика, чтобы не растягивать ячейку
        button.text = ""
        _debug_print("  Applying cross style (blue)")
    
    if style:
        _debug_print("  Style found: %s" % str(style))
        button.add_theme_stylebox_override("normal", style.duplicate())
        button.add_theme_stylebox_override("hover", style.duplicate())
        button.add_theme_stylebox_override("pressed", style.duplicate())
        button.add_theme_stylebox_override("disabled", style.duplicate())
        button.add_theme_stylebox_override("focused", style.duplicate())
    else:
        _debug_print("  ERROR: Style is null!")
    
    # Принудительно обновляем кнопку
    button.queue_redraw()

func _update_grid_visuals():
    for y in range(level_data.grid_size):
        for x in range(level_data.grid_size):
            var button = get_button(x, y)
            if button:
                # Полностью очищаем все переопределения стилей и цветов
                button.remove_theme_stylebox_override("normal")
                button.remove_theme_stylebox_override("hover")
                button.remove_theme_stylebox_override("pressed")
                button.remove_theme_stylebox_override("disabled")
                button.remove_theme_stylebox_override("focused")
                button.remove_theme_color_override("font_color")
                button.remove_theme_font_size_override("font_size")
                
                var style: StyleBox
                if player_grid[y][x] == 0:
                    style = theme_resource.get_stylebox("custom_empty", "Button")
                    button.text = ""
                elif player_grid[y][x] == 1:
                    style = theme_resource.get_stylebox("custom_filled", "Button")
                    button.text = ""
                elif player_grid[y][x] == 2:
                    style = theme_resource.get_stylebox("custom_cross", "Button")
                    # Не устанавливаем текст для крестика, чтобы не растягивать ячейку
                    button.text = ""
                
                if style:
                    button.add_theme_stylebox_override("normal", style.duplicate())
                    button.add_theme_stylebox_override("hover", style.duplicate())
                    button.add_theme_stylebox_override("pressed", style.duplicate())
                    button.add_theme_stylebox_override("disabled", style.duplicate())
                    button.add_theme_stylebox_override("focused", style.duplicate())
                
                # Принудительно обновляем кнопку
                button.queue_redraw()

func get_button(x: int, y: int) -> Button:
	if not grid_container:
		return null
	
	for child in grid_container.get_children():
		if child is Button and child.has_meta("cell_x"):
			if child.get_meta("cell_x") == x and child.get_meta("cell_y") == y:
				return child
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
		check_button.disabled = true
		back_button.disabled = false
		show_victory_banner()
		# Блокируем взаимодействие с сеткой после победы
		_set_grid_interaction(false)
	else:
		level_label.text = "Неверно, попробуйте еще раз!"

func show_victory_banner():
	if victory_banner:
		victory_banner.visible = true
		victory_banner.z_index = 100
		
		if victory_buttons_container:
			victory_buttons_container.visible = false
		
		if victory_message:
			victory_message.text = "Победа!\n(Кликните, чтобы продолжить)"

func _on_banner_click(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if victory_buttons_container and not victory_buttons_container.visible:
			victory_buttons_container.visible = true
			if victory_message:
				victory_message.text = "Поздравляем!\nВы решили головоломку!"
			# Применяем тему к появившимся кнопкам
			_apply_theme_to_buttons()

func _on_menu_pressed():
	back_to_menu_pressed.emit()

func _on_next_level_pressed():
	next_level_requested.emit()

func _on_back_pressed():
	back_to_menu_pressed.emit()

func _set_grid_interaction(enabled: bool):
	if not grid_container:
		return
	
	for child in grid_container.get_children():
		if child is Button and child.has_meta("cell_x"):
			child.disabled = not enabled

func _apply_theme_to_buttons():
	if not theme_resource:
		return
	
	_debug_print("_apply_theme_to_buttons() called")
	
	# Применяем к кнопкам управления
	var ui_buttons = [check_button, back_button, menu_button, next_level_button]
	for btn in ui_buttons:
		if btn and theme_resource.has_stylebox("custom_empty", "Button"):
			var style = theme_resource.get_stylebox("custom_empty", "Button")
			if style:
				_debug_print("  Applying theme to button: %s" % btn.name)
				btn.add_theme_stylebox_override("normal", style)
				btn.add_theme_stylebox_override("hover", style)
				btn.add_theme_stylebox_override("pressed", style)
