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
@onready var background: ColorRect = $Background

func configure(all_levels: Array[LevelData], save_data: SaveData, chapter_index: int) -> void:
	levels = all_levels
	progress = save_data
	selected_chapter = chapter_index

func _ready() -> void:
	$Margin/Page/TopBar/BackButton.pressed.connect(back_to_menu_pressed.emit)
	continue_button.pressed.connect(_continue_game)
	_show_chapter(selected_chapter)

func _build_chapter_tabs() -> void:
	for child in chapter_tabs.get_children():
		chapter_tabs.remove_child(child)
		child.queue_free()
	for index in range(LevelCatalog.CHAPTERS.size()):
		var info: Dictionary = LevelCatalog.CHAPTERS[index]
		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 44)
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
	chapter_subtitle.text = "%s  •  выберите уровень" % info.subtitle
	chapter_icon.text = info.icon
	var secondary: Color = info.get("secondary_color", info.color.lightened(0.28))
	background.color = secondary.darkened(0.08)
	chapter_header.add_theme_stylebox_override("panel", _make_style(Color("fffaf2"), info.color, 1, 10))
	chapter_title.add_theme_color_override("font_color", info.color.darkened(0.18))
	chapter_subtitle.add_theme_color_override("font_color", Color("555b65"))
	_style_chapter_tabs()
	var completed := progress.completed_in_chapter(chapter)
	progress_label.text = "%d / 10" % completed
	progress_label.add_theme_color_override("font_color", info.color.darkened(0.12))
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
	button.custom_minimum_size = Vector2(190, 174)
	button.disabled = not unlocked
	button.tooltip_text = "Продолжить уровень %d" % (level_index + 1) if unlocked else "Сначала пройдите предыдущий уровень"
	button.pressed.connect(_select_level.bind(level_index))
	var chapter_color: Color = LevelCatalog.CHAPTERS[selected_chapter].color
	var secondary: Color = LevelCatalog.CHAPTERS[selected_chapter].get("secondary_color", chapter_color.lightened(0.35))
	var card_color := Color("fffaf2") if unlocked else Color("ded8d5")
	button.add_theme_stylebox_override("normal", _make_style(card_color, secondary.lightened(0.18), 1, 12))
	button.add_theme_stylebox_override("hover", _make_style(secondary.lightened(0.55), chapter_color, 2, 12))
	button.add_theme_stylebox_override("pressed", _make_style(secondary.lightened(0.4), chapter_color.darkened(0.12), 2, 12))
	button.add_theme_stylebox_override("disabled", _make_style(Color("ececea"), Color("d5d5d2"), 1, 12))

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
	number.add_theme_color_override("font_color", chapter_color.darkened(0.12) if unlocked else Color("8791a5"))
	number.add_theme_font_size_override("font_size", 16)
	content.add_child(number)

	var preview := LevelPreview.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.custom_minimum_size = Vector2(98, 98)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var draft := progress.get_draft(data)
	var preview_grid := data.solution if completed else draft
	preview.configure(data.grid_size, preview_grid, data.preview_color)
	content.add_child(preview)

	var status := Label.new()
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var completion_time := progress.get_completion_time(data)
	status.text = ("✓ ПРОЙДЕН · %s" % SaveData.format_time(completion_time) if completion_time > 0.0 else "✓ ПРОЙДЕН") if completed else ("ДОСТУПЕН" if unlocked else "🔒 ЗАКРЫТ")
	status.add_theme_color_override("font_color", Color("318463") if completed else (Color("53627b") if unlocked else Color("8791a5")))
	status.add_theme_font_size_override("font_size", 12)
	content.add_child(status)
	return button

func _style_chapter_tabs() -> void:
	var accent: Color = LevelCatalog.CHAPTERS[selected_chapter].color
	for child in chapter_tabs.get_children():
		if not child is Button:
			continue
		var chapter_index := int(child.get_meta("chapter_index", -1))
		var info: Dictionary = LevelCatalog.CHAPTERS[chapter_index]
		var unlocked := progress.is_chapter_unlocked(chapter_index)
		if chapter_index == selected_chapter:
			child.text = "%s  Глава %d · %s" % [info.icon, chapter_index + 1, info.title]
			child.add_theme_color_override("font_color", Color.WHITE)
			child.add_theme_stylebox_override("normal", _make_style(Color("3b1730"), accent, 2, 10))
		else:
			child.text = "%s  %d" % [info.icon, chapter_index + 1] if unlocked else "🔒  %d" % (chapter_index + 1)
			child.add_theme_color_override("font_color", Color("24314d"))
			child.add_theme_stylebox_override("normal", _make_style(Color("fffaf2"), Color("3b1730"), 1, 10))

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
