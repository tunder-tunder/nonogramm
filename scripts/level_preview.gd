extends Control
class_name LevelPreview

var grid_size := 3
var draft: Array = []
var fill_color := Color("6f8cff")

func configure(size_value: int, draft_value: Array, color_value: Color) -> void:
	grid_size = maxi(size_value, 1)
	draft = draft_value.duplicate(true)
	fill_color = color_value
	queue_redraw()

func _draw() -> void:
	var side := minf(size.x, size.y)
	var origin := (size - Vector2(side, side)) * 0.5
	var cell := side / float(grid_size)
	draw_rect(Rect2(origin, Vector2(side, side)), Color("f5f7fb"), true)
	var has_valid_draft := draft.size() == grid_size
	for y in range(grid_size):
		for x in range(grid_size):
			var value := 0
			if has_valid_draft and draft[y] is Array and draft[y].size() == grid_size:
				value = int(draft[y][x])
			var rect := Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell))
			if value == 1:
				draw_rect(rect, fill_color, true)
			elif value == 2:
				if cell >= 4.0:
					draw_line(rect.position + Vector2(1, 1), rect.end - Vector2(1, 1), Color("69758d"), maxf(1.0, cell * 0.12))
					draw_line(Vector2(rect.end.x - 1, rect.position.y + 1), Vector2(rect.position.x + 1, rect.end.y - 1), Color("69758d"), maxf(1.0, cell * 0.12))
				else:
					draw_rect(rect, Color("9ba5b8"), true)
	if cell >= 3.0:
		for line in range(grid_size + 1):
			var offset := float(line) * cell
			draw_line(origin + Vector2(offset, 0), origin + Vector2(offset, side), Color("d2d8e4"), 1.0)
			draw_line(origin + Vector2(0, offset), origin + Vector2(side, offset), Color("d2d8e4"), 1.0)
	draw_rect(Rect2(origin, Vector2(side, side)), Color("aeb8ca"), false, 1.0)
