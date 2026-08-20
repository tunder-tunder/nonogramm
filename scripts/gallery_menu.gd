extends Control

signal back_to_menu_pressed

var unlocked_levels: Array[int] = []

@onready var grid: GridContainer = $Panel/VBoxContainer/GalleryGrid
@onready var back_button: Button = $Panel/VBoxContainer/BackButton

func _ready():
	back_button.connect("pressed", _on_back_pressed)
	_refresh_gallery()

func set_unlocked_levels(levels: Array[int]):
	unlocked_levels = levels.duplicate()
	if is_node_ready():
		_refresh_gallery()

func _refresh_gallery():
	for child in grid.get_children():
		child.queue_free()
	_add_gallery_card(0, "🏆", "Буква T")
	_add_gallery_card(1, "🏠", "Домик")

func _add_gallery_card(level_index: int, icon: String, title: String):
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 180)
	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)

	var image_label = Label.new()
	image_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	image_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	image_label.add_theme_font_size_override("font_size", 54)
	image_label.text = icon if unlocked_levels.has(level_index) else "🔒"
	box.add_child(image_label)

	var title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.text = title if unlocked_levels.has(level_index) else "Откроется после решения"
	box.add_child(title_label)
	grid.add_child(panel)

func _on_back_pressed():
	back_to_menu_pressed.emit()
