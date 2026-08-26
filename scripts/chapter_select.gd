extends Control

signal chapter_selected(chapter_index: int)
signal back_to_menu_pressed

var progress: SaveData

@onready var chapter_grid: GridContainer = $Margin/Page/ChapterGrid

func configure(save_data: SaveData) -> void:
	progress = save_data

func _ready() -> void:
	$Margin/Page/TopBar/BackButton.pressed.connect(back_to_menu_pressed.emit)
	_build_chapters()

func _build_chapters() -> void:
	for child in chapter_grid.get_children():
		child.queue_free()
	for chapter in range(LevelCatalog.CHAPTERS.size()):
		chapter_grid.add_child(_create_chapter_card(chapter))

func _create_chapter_card(chapter: int) -> Button:
	var info: Dictionary = LevelCatalog.CHAPTERS[chapter]
	var unlocked := progress.is_chapter_unlocked(chapter)
	var completed := progress.completed_in_chapter(chapter)
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 390)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = not unlocked
	button.tooltip_text = "Открыть главу" if unlocked else "Сначала завершите предыдущую главу"
	button.add_theme_stylebox_override("normal", _card_style(Color("fffaf2"), info.color, 1))
	button.add_theme_stylebox_override("hover", _card_style(Color("fffdf8"), info.color, 3))
	button.add_theme_stylebox_override("pressed", _card_style(info.secondary_color.lightened(0.42), info.color, 3))
	button.add_theme_stylebox_override("disabled", _card_style(Color("d9d2d1"), Color("8b7c82"), 1))
	button.pressed.connect(chapter_selected.emit.bind(chapter))

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 22)
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 16)
	button.add_child(content)

	var number := Label.new()
	number.text = "ГЛАВА %02d" % (chapter + 1)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.add_theme_color_override("font_color", info.color if unlocked else Color("756d70"))
	number.add_theme_font_size_override("font_size", 13)
	content.add_child(number)

	var icon := Label.new()
	icon.text = info.icon if unlocked else "🔒"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 58)
	content.add_child(icon)

	var title := Label.new()
	title.text = info.title if unlocked else "Закрыто"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", Color("20141b") if unlocked else Color("756d70"))
	title.add_theme_font_size_override("font_size", 22)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = info.subtitle if unlocked else "Завершите предыдущую главу"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("665b61"))
	subtitle.add_theme_font_size_override("font_size", 13)
	content.add_child(subtitle)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 14)
	bar.max_value = 10
	bar.value = completed
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _bar_style(Color("e6dedb")))
	bar.add_theme_stylebox_override("fill", _bar_style(info.color))
	content.add_child(bar)

	var progress_label := Label.new()
	progress_label.text = "%d / 10 уровней" % completed if unlocked else "Недоступно"
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_color_override("font_color", info.color if unlocked else Color("756d70"))
	progress_label.add_theme_font_size_override("font_size", 14)
	content.add_child(progress_label)
	return button

func _card_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(12)
	return style

func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(7)
	return style
