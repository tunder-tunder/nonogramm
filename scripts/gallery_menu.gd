extends Control

signal back_to_menu_pressed

var progress: SaveData
@onready var grid: GridContainer = $Panel/VBoxContainer/GalleryGrid

func configure(save_data: SaveData) -> void:
	progress = save_data

func _ready() -> void:
	$Panel/VBoxContainer/BackButton.pressed.connect(back_to_menu_pressed.emit)
	_refresh_gallery()

func _refresh_gallery() -> void:
	for child in grid.get_children():
		child.queue_free()
	for chapter in range(LevelCatalog.CHAPTERS.size()):
		_add_gallery_card(chapter)

func _add_gallery_card(chapter: int) -> void:
	var info: Dictionary = LevelCatalog.CHAPTERS[chapter]
	var unlocked := progress.is_chapter_completed(chapter)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 205)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	var image := Label.new()
	image.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	image.add_theme_font_size_override("font_size", 48)
	image.text = "%s ✨" % info.icon if unlocked else "🔒"
	box.add_child(image)
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = info.reward if unlocked else "Иллюстрация главы %d" % (chapter + 1)
	box.add_child(title)
	var hint := Label.new()
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "ОТКРЫТО" if unlocked else "%d / 10 уровней" % progress.completed_in_chapter(chapter)
	hint.modulate = Color("4e9d78") if unlocked else Color("778097")
	box.add_child(hint)
	grid.add_child(panel)
