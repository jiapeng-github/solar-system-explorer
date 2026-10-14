extends RefCounted
var path := "user://progress.json"
var data := {"schema_version": 1, "selected": "earth", "visited": [], "lessons": [], "tasks": [], "comparisons": []}
var error_message := ""

func load_progress() -> void:
	data = {"schema_version":1,"selected":"earth","visited":[],"lessons":[],"tasks":[],"comparisons":[]}
	error_message = ""
	if not FileAccess.file_exists(path):
		return
	var parser := JSON.new()
	var parse_error := parser.parse(FileAccess.get_file_as_string(path))
	var parsed = parser.data if parse_error == OK else null
	if not parsed is Dictionary or parsed.get("schema_version") != 1 or not parsed.get("visited") is Array or not parsed.get("lessons") is Array or not parsed.get("selected") is String:
		DirAccess.copy_absolute(path, path + ".corrupt")
		error_message = "学习记录无法读取，已保留备份并恢复默认记录。"
		return
	data = parsed
	for field in ["tasks","comparisons"]:
		if not data.get(field) is Array: data[field] = []
	for field in ["visited","lessons","tasks","comparisons"]:
		var unique: Array = []
		for value in data[field]:
			if value is String and not unique.has(value): unique.append(value)
		data[field] = unique

func visit(body_id: String) -> void:
	data.selected = body_id
	if not data.visited.has(body_id):
		data.visited.append(body_id)
	save_progress()

func complete(lesson_id: String) -> void:
	if data.lessons.has(lesson_id):
		# Retry an earlier failed write, but do not rewrite completed lessons on every visit.
		if not error_message.is_empty(): save_progress()
		return
	data.lessons.append(lesson_id)
	save_progress()

func save_progress() -> void:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error_message = "记录保存失败，本次仍可继续探索。"
		return
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		error_message = "记录保存失败，本次仍可继续探索。"
		return
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		error_message = "记录保存失败，本次仍可继续探索。"
		return
	error_message = ""

func record_comparison(key: String) -> void:
	if data.comparisons.has(key): return
	data.comparisons.append(key)
	save_progress()

func complete_task(id: String) -> void:
	if data.tasks.has(id): return
	data.tasks.append(id)
	save_progress()

func reset_progress() -> void:
	data = {"schema_version":1,"selected":"earth","visited":[],"lessons":[],"tasks":[],"comparisons":[]}
	save_progress()
