extends Control

const PATTERN := [
	"..##..##..",
	".########.",
	"##########",
	"##########",
	".########.",
	"..######..",
	"...####...",
	"....##...."
]

var time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var cell: float = clampf(minf((size.x - 150.0) / 10.0, (size.y - 125.0) / 8.0), 15.0, 34.0)
	var gap: float = maxf(3.0, cell * 0.16)
	var grid_size := Vector2(PATTERN[0].length(), PATTERN.size()) * (cell + gap) - Vector2(gap, gap)
	var origin := (size - grid_size) * 0.5 + Vector2(0.0, sin(time * 1.6) * 3.0)

	var shadow := Rect2(origin - Vector2(30, 25) + Vector2(0, 7), grid_size + Vector2(60, 50))
	draw_style_box(_card_style(Color(0.08, 0.1, 0.13, 0.1)), shadow)
	var card := Rect2(origin - Vector2(30, 25), grid_size + Vector2(60, 50))
	draw_style_box(_card_style(Color("fffdf8")), card)

	for y in range(PATTERN.size()):
		for x in range(PATTERN[y].length()):
			var rect := Rect2(origin + Vector2(x, y) * (cell + gap), Vector2(cell, cell))
			var filled: bool = PATTERN[y].substr(x, 1) == "#"
			var color := Color("bd3f70") if filled else Color("e8e4dc")
			draw_rect(rect, color, true)

	# Небольшие подсказки превращают иллюстрацию в узнаваемую нонограмму.
	var clue_color := Color("737780")
	for y in range(PATTERN.size()):
		draw_circle(origin + Vector2(-15, y * (cell + gap) + cell * 0.5), 2.2, clue_color)
	for x in range(PATTERN[0].length()):
		draw_circle(origin + Vector2(x * (cell + gap) + cell * 0.5, -14), 2.2, clue_color)

func _card_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	return style
