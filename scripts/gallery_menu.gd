extends Control

signal back_to_menu_pressed

var progress: SaveData
var current_page := 0
const ITEMS_PER_PAGE := 2
@onready var grid: GridContainer = $Panel/VBoxContainer/GalleryGrid
@onready var previous_button: Button = $Panel/VBoxContainer/Pagination/PreviousButton
@onready var next_button: Button = $Panel/VBoxContainer/Pagination/NextButton
@onready var page_label: Label = $Panel/VBoxContainer/Pagination/PageLabel

func configure(save_data: SaveData) -> void:
	progress = save_data

func _ready() -> void:
	$Panel/VBoxContainer/BackButton.pressed.connect(back_to_menu_pressed.emit)
	previous_button.pressed.connect(_change_page.bind(-1))
	next_button.pressed.connect(_change_page.bind(1))
	_refresh_gallery()

func _refresh_gallery() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var first := current_page * ITEMS_PER_PAGE
	var last := mini(first + ITEMS_PER_PAGE, LevelCatalog.CHAPTERS.size())
	for chapter in range(first, last):
		_add_gallery_card(chapter)
	var page_count := ceili(float(LevelCatalog.CHAPTERS.size()) / ITEMS_PER_PAGE)
	page_label.text = "%d  /  %d" % [current_page + 1, page_count]
	previous_button.disabled = current_page == 0
	next_button.disabled = current_page >= page_count - 1

func _change_page(direction: int) -> void:
	var page_count := ceili(float(LevelCatalog.CHAPTERS.size()) / ITEMS_PER_PAGE)
	current_page = clampi(current_page + direction, 0, page_count - 1)
	_refresh_gallery()

func _add_gallery_card(chapter: int) -> void:
	var info: Dictionary = LevelCatalog.CHAPTERS[chapter]
	var unlocked := progress.is_chapter_completed(chapter)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 350)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var accent: Color = info.color
	panel.add_theme_stylebox_override("panel", _make_card_style(accent, unlocked))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var chapter_label := Label.new()
	chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_label.text = "ГЛАВА %02d" % (chapter + 1)
	chapter_label.add_theme_color_override("font_color", Color("d7deef") if unlocked else Color("98a2b7"))
	chapter_label.add_theme_font_size_override("font_size", 14)
	box.add_child(chapter_label)
	var image := Label.new()
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	image.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	image.add_theme_font_size_override("font_size", 82)
	image.add_theme_color_override("font_color", Color.WHITE if unlocked else Color("8d97ab"))
	image.text = "✦  %s  ✦\n%s" % [info.icon, info.companion] if unlocked else "🔒\n?"
	box.add_child(image)
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE if unlocked else Color("c1c7d4"))
	title.text = info.reward if unlocked else "Тайна главы %d" % (chapter + 1)
	box.add_child(title)
	var hint := Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "ОТКРЫТО" if unlocked else "%d / 10 уровней" % progress.completed_in_chapter(chapter)
	hint.add_theme_color_override("font_color", accent.lightened(0.35) if unlocked else Color("8791a5"))
	box.add_child(hint)
	grid.add_child(panel)

func _make_card_style(accent: Color, unlocked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = accent.darkened(0.58) if unlocked else Color("222a3b")
	style.border_color = accent if unlocked else Color("485166")
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.content_margin_left = 28
	style.content_margin_top = 24
	style.content_margin_right = 28
	style.content_margin_bottom = 24
	return style
