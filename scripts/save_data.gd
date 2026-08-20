extends RefCounted
class_name SaveData

const SAVE_PATH := "user://progress.json"

var completed: Dictionary = {}
var drafts: Dictionary = {}
var elapsed_times: Dictionary = {}
var completion_times: Dictionary = {}
var last_chapter := 0
var last_level := 0

func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		completed = parsed.get("completed", {})
		drafts = parsed.get("drafts", {})
		elapsed_times = parsed.get("elapsed_times", {})
		completion_times = parsed.get("completion_times", {})
		last_chapter = clampi(int(parsed.get("last_chapter", 0)), 0, 4)
		last_level = clampi(int(parsed.get("last_level", 0)), 0, 9)

func save_to_disk() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("Could not write progress save")
		return
	file.store_string(JSON.stringify({
		"completed": completed,
		"drafts": drafts,
		"elapsed_times": elapsed_times,
		"completion_times": completion_times,
		"last_chapter": last_chapter,
		"last_level": last_level
	}))

func mark_completed(data: LevelData, elapsed_seconds: float = 0.0) -> void:
	completed[data.get_id()] = true
	drafts.erase(data.get_id())
	elapsed_times.erase(data.get_id())
	completion_times[data.get_id()] = elapsed_seconds
	last_chapter = data.chapter_index
	last_level = mini(data.level_index + 1, 9)
	if data.level_index == 9 and data.chapter_index < 4:
		last_chapter = data.chapter_index + 1
		last_level = 0
	save_to_disk()

func save_draft(data: LevelData, grid: Array, elapsed_seconds: float = -1.0) -> void:
	# Keep an independent snapshot so later cell edits cannot mutate the preview in memory.
	drafts[data.get_id()] = grid.duplicate(true)
	if elapsed_seconds >= 0.0:
		elapsed_times[data.get_id()] = elapsed_seconds
	last_chapter = data.chapter_index
	last_level = data.level_index
	save_to_disk()

func get_draft(data: LevelData) -> Array:
	var draft = drafts.get(data.get_id(), [])
	if not draft is Array or draft.size() != data.grid_size:
		return []
	for row in draft:
		if not row is Array or row.size() != data.grid_size:
			return []
	return draft.duplicate(true)

func get_elapsed_time(data: LevelData) -> float:
	return float(elapsed_times.get(data.get_id(), 0.0))

func get_completion_time(data: LevelData) -> float:
	return float(completion_times.get(data.get_id(), 0.0))

func is_completed(chapter: int, level: int) -> bool:
	return completed.has("%d:%d" % [chapter, level])

func is_chapter_unlocked(chapter: int) -> bool:
	return chapter == 0 or is_chapter_completed(chapter - 1)

func is_level_unlocked(chapter: int, level: int) -> bool:
	if not is_chapter_unlocked(chapter):
		return false
	return level == 0 or is_completed(chapter, level - 1)

func is_chapter_completed(chapter: int) -> bool:
	for level in range(10):
		if not is_completed(chapter, level):
			return false
	return true

func completed_in_chapter(chapter: int) -> int:
	var count := 0
	for level in range(10):
		if is_completed(chapter, level):
			count += 1
	return count

func reset_progress() -> void:
	completed.clear()
	drafts.clear()
	elapsed_times.clear()
	completion_times.clear()
	last_chapter = 0
	last_level = 0
	if FileAccess.file_exists(SAVE_PATH):
		var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		if error != OK:
			push_error("Could not remove progress save: %s" % error_string(error))

static func format_time(seconds: float) -> String:
	var total := maxi(0, floori(seconds))
	var hours := floori(float(total) / 3600.0)
	var minutes := floori(float(total % 3600) / 60.0)
	var secs := total % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs] if hours > 0 else "%02d:%02d" % [minutes, secs]
