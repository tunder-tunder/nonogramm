extends Control

signal level_selected(level_data: Resource)
signal back_to_menu_pressed

var levels: Array[LevelData] = []
var progress: SaveData
var selected_chapter := 0

@onready var chapter_tabs: HBoxContainer = $Margin/Page/ChapterTabs
@onready var chapter_header: PanelContainer = $Margin/Page/ChapterHeader
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
		chapter_tabs.remove_child(child)
		child.queue_free()
	for index in range(LevelCatalog.CHAPTERS.size()):
		var info: Dictionary = LevelCatalog.CHAPTERS[index]
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 54)
		button.text = "%s  %d" % [info.icon, index + 1] if progress.is_chapter_unlocked(index) else "🔒  %d" % (index + 1)
		button.disabled = not progress.is_chapter_unlocked(index)
		button.tooltip_text = info.title
		button.set_meta("chapter_index", index)
		button.add_theme_color_override("font_color", Color("24314d"))
		button.add_theme_color_override("font_hover_color", Color("17213a"))
		button.add_theme_color_override("font_disabled_color", Color("8791a5"))
		button.add_theme_stylebox_override("normal", _make_style(Color("ffffff"), Color("d9dfeb"), 1, 12))
		button.add_theme_stylebox_override("hover", _make_style(Color("edf3ff"), info.color, 2, 12))
		button.add_theme_stylebox_override("disabled", _make_style(Color("e7eaf1"), Color("d4d9e3"), 1, 12))
		button.pressed.connect(_show_chapter.bind(index))
		chapter_tabs.add_child(button)

func _show_chapter(chapter: int) -> void:
	selected_chapter = chapter
	var info: Dictionary = LevelCatalog.CHAPTERS[chapter]
	chapter_title.text = "ГЛАВА %d · %s" % [chapter + 1, info.title]
	chapter_subtitle.text = "%s  •  %s" % [info.subtitle, info.companion_names]
	chapter_icon.text = info.icon
	chapter_header.add_theme_stylebox_override("panel", _make_style(info.color.darkened(0.35), info.color.lightened(0.12), 2, 18))
	_style_chapter_tabs()
	var completed := progress.completed_in_chapter(chapter)
	progress_label.text = "%d / 10\nЗАВЕРШЕНО" % completed
	continue_button.text = "Продолжить · уровень %d" % [progress.last_level + 1] if chapter == progress.last_chapter else "Играть главу"
	_rebuild_levels()

func _rebuild_levels() -> void:
	for child in level_grid.get_children():
		level_grid.remove_child(child)
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
	var chapter_color: Color = LevelCatalog.CHAPTERS[selected_chapter].color
	var card_color := Color("ffffff") if unlocked else Color("e7eaf0")
	button.add_theme_stylebox_override("normal", _make_style(card_color, chapter_color.lightened(0.35), 2, 16))
	button.add_theme_stylebox_override("hover", _make_style(Color("f7faff"), chapter_color, 3, 16))
	button.add_theme_stylebox_override("pressed", _make_style(Color("edf3ff"), chapter_color.darkened(0.12), 3, 16))
	button.add_theme_stylebox_override("disabled", _make_style(Color("e7eaf0"), Color("cdd3de"), 1, 16))

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	content.add_theme_constant_override("separation", 7)
	button.add_child(content)
	var data := _get_level(selected_chapter, level_index)

	var number := Label.new()
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.text = "УРОВЕНЬ %02d  ·  %d×%d" % [level_index + 1, data.grid_size, data.grid_size]
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.add_theme_color_override("font_color", Color("24314d") if unlocked else Color("8791a5"))
	number.add_theme_font_size_override("font_size", 16)
	content.add_child(number)

	var preview := LevelPreview.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.custom_minimum_size = Vector2(94, 94)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var draft := progress.get_draft(data)
	preview.configure(data.grid_size, draft, data.preview_color)
	content.add_child(preview)

	var status := Label.new()
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.text = "✓ ПРОЙДЕН" if completed else ("ДОСТУПЕН" if unlocked else "🔒 ЗАКРЫТ")
	status.add_theme_color_override("font_color", Color("318463") if completed else (Color("53627b") if unlocked else Color("8791a5")))
	content.add_child(status)
	return button

func _style_chapter_tabs() -> void:
	var accent: Color = LevelCatalog.CHAPTERS[selected_chapter].color
	for child in chapter_tabs.get_children():
		if child is Button and child.get_meta("chapter_index", -1) == selected_chapter:
			child.add_theme_color_override("font_color", Color.WHITE)
			child.add_theme_stylebox_override("normal", _make_style(accent.darkened(0.18), accent, 2, 12))
		else:
			child.add_theme_color_override("font_color", Color("24314d"))
			child.add_theme_stylebox_override("normal", _make_style(Color("ffffff"), Color("d9dfeb"), 1, 12))

func _make_style(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style

func _continue_game() -> void:
	var target := progress.last_level if selected_chapter == progress.last_chapter else 0
	if not progress.is_level_unlocked(selected_chapter, target):
		target = 0
	_select_level(target)

func _select_level(level_index: int) -> void:
	level_selected.emit(_get_level(selected_chapter, level_index))

func _get_level(chapter: int, level: int) -> LevelData:
	return levels[chapter * 10 + level]
