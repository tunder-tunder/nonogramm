extends Control

signal level_selected(level_data: Resource)
signal back_to_menu_pressed

var levels: Array[LevelData] = []
var progress: SaveData
var selected_chapter := 0

@onready var chapter_tabs: HBoxContainer = $Margin/Page/ChapterTabs
@onready var chapter_title: Label = $Margin/Page/ChapterHeader/HeaderMargin/HeaderRow/Copy/ChapterTitle
@onready var chapter_subtitle: Label = $Margin/Page/ChapterHeader/HeaderMargin/HeaderRow/Copy/ChapterSubtitle
@onready var chapter_icon: Label = $Margin/Page/ChapterHeader/HeaderMargin/HeaderRow/ChapterIcon
@onready var progress_label: Label = $Margin/Page/ChapterHeader/HeaderMargin/HeaderRow/Progress
@onready var level_grid: GridContainer = $Margin/Page/LevelGrid
@onready var continue_button: Button = $Margin/Page/Footer/ContinueButton

func configure(all_levels: Array[LevelData], save_data: SaveData) -> void:
	levels = all_levels
	progress = save_data
	selected_chapter = progress.last_chapter

func _ready() -> void:
	$Margin/Page/TopBar/BackButton.pressed.connect(back_to_menu_pressed.emit)
	continue_button.pressed.connect(_continue_game)
	_build_chapter_tabs()
	_show_chapter(selected_chapter)

func _build_chapter_tabs() -> void:
	for child in chapter_tabs.get_children():
		child.queue_free()
	for index in range(LevelCatalog.CHAPTERS.size()):
		var info: Dictionary = LevelCatalog.CHAPTERS[index]
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 54)
		button.text = "%s  %d" % [info.icon, index + 1] if progress.is_chapter_unlocked(index) else "🔒  %d" % (index + 1)
		button.disabled = not progress.is_chapter_unlocked(index)
		button.tooltip_text = info.title
		button.pressed.connect(_show_chapter.bind(index))
		chapter_tabs.add_child(button)

func _show_chapter(chapter: int) -> void:
	selected_chapter = chapter
	var info: Dictionary = LevelCatalog.CHAPTERS[chapter]
	chapter_title.text = "ГЛАВА %d · %s" % [chapter + 1, info.title]
	chapter_subtitle.text = "%s  •  Компаньоны %s %s" % [info.subtitle, info.companion, info.companion_alt]
	chapter_icon.text = info.icon
	var completed := progress.completed_in_chapter(chapter)
	progress_label.text = "%d / 10\nЗАВЕРШЕНО" % completed
	continue_button.text = "Продолжить · уровень %d" % [progress.last_level + 1] if chapter == progress.last_chapter else "Играть главу"
	_rebuild_levels()

func _rebuild_levels() -> void:
	for child in level_grid.get_children():
		child.queue_free()
	for level_index in range(10):
		level_grid.add_child(_create_level_card(level_index))

func _create_level_card(level_index: int) -> Control:
	var unlocked := progress.is_level_unlocked(selected_chapter, level_index)
	var completed := progress.is_completed(selected_chapter, level_index)
	var button := Button.new()
	button.custom_minimum_size = Vector2(190, 170)
	button.disabled = not unlocked
	button.tooltip_text = "Продолжить уровень %d" % (level_index + 1) if unlocked else "Сначала пройдите предыдущий уровень"
	button.pressed.connect(_select_level.bind(level_index))

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	content.add_theme_constant_override("separation", 7)
	button.add_child(content)

	var number := Label.new()
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.text = "УРОВЕНЬ %02d" % (level_index + 1)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(number)

	var preview := GridContainer.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.columns = 5
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var data := _get_level(selected_chapter, level_index)
	var draft := progress.get_draft(data)
	for y in range(5):
		for x in range(5):
			var cell := ColorRect.new()
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cell.custom_minimum_size = Vector2(15, 15)
			var value := 0
			if draft.size() == data.grid_size and draft[y] is Array and draft[y].size() == data.grid_size:
				value = int(draft[y][x])
			cell.color = data.preview_color if value == 1 else (Color("9ba7bd") if value == 2 else Color("eef1f7"))
			preview.add_child(cell)
	content.add_child(preview)

	var status := Label.new()
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.text = "✓ ПРОЙДЕН" if completed else ("ДОСТУПЕН" if unlocked else "🔒 ЗАКРЫТ")
	status.modulate = Color("4e9d78") if completed else Color("778097")
	content.add_child(status)
	return button

func _continue_game() -> void:
	var target := progress.last_level if selected_chapter == progress.last_chapter else 0
	if not progress.is_level_unlocked(selected_chapter, target):
		target = 0
	_select_level(target)

func _select_level(level_index: int) -> void:
	level_selected.emit(_get_level(selected_chapter, level_index))

func _get_level(chapter: int, level: int) -> LevelData:
	return levels[chapter * 10 + level]
