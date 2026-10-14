extends SceneTree
const Store = preload("res://scripts/progress_store.gd")
const SeasonsLab = preload("res://scripts/ui/seasons_lab.gd")
const STORE_PATH := "res://work/storage-regression-progress.json"
const LAB_PATH := "res://work/storage-regression-seasons.json"
var failures: Array[String] = []

class CountingStore:
	extends "res://scripts/progress_store.gd"
	var writes := 0
	func save_progress() -> void:
		writes += 1
		super.save_progress()

func _initialize() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	create_timer(30).timeout.connect(func(): quit(2))
	for path in [STORE_PATH,LAB_PATH]:
		for suffix in ["",".tmp",".corrupt"]: DirAccess.remove_absolute(path+suffix)
	var store := CountingStore.new()
	store.path = STORE_PATH
	store.reset_progress()
	store.complete("day")
	var before := store.writes
	store.complete("day")
	check(store.writes == before,"Completed lesson does not rewrite the same record")
	store.data.selected = "mars"
	store.save_progress()
	var original := FileAccess.get_file_as_string(STORE_PATH)
	# Occupy only this isolated test's temporary path, leaving its last good record intact.
	check(DirAccess.make_dir_absolute(STORE_PATH+".tmp") == OK,"Prepare a blocked temporary path")
	store.data.selected = "venus"
	store.save_progress()
	check(not store.error_message.is_empty(),"Failed write reports an error")
	check(FileAccess.get_file_as_string(STORE_PATH) == original,"Failed write preserves the previous complete record")
	DirAccess.remove_absolute(STORE_PATH+".tmp")
	store.save_progress()
	check(store.error_message.is_empty(),"A successful retry clears the earlier save error")
	var restored = Store.new()
	restored.path = STORE_PATH
	restored.load_progress()
	check(restored.data.selected == "venus","A successful retry persists the latest state")
	var broken := FileAccess.open(STORE_PATH,FileAccess.WRITE)
	broken.store_string("broken record")
	broken.close()
	store.load_progress()
	check(store.data.selected == "earth" and store.data.lessons.is_empty(),"Reloading corrupt data restores defaults even on a reused store")
	check(not store.error_message.is_empty() and FileAccess.file_exists(STORE_PATH+".corrupt"),"Corrupt input is backed up and reported")
	store.reset_progress()
	check(store.error_message.is_empty(),"Successful reset clears a recovered-record warning")

	var lab_store := CountingStore.new()
	lab_store.path = LAB_PATH
	lab_store.reset_progress()
	var holder := Control.new()
	holder.size = Vector2(1280,800)
	root.add_child(holder)
	var lab = SeasonsLab.new()
	lab.store = lab_store
	holder.add_child(lab)
	lab.state.visited = [0,1,2]
	lab.state.contrast = true
	lab.state.answer = 0
	before = lab_store.writes
	lab.slider.drag_started.emit()
	for value in range(91,271): lab.slider.value = value
	check(lab_store.writes == before,"Dragging and crossing the completion point performs no synchronous writes")
	check(lab_store.data.seasons.angle == 270 and lab_store.data.lessons.has("seasons"),"Dragging keeps current state and completion available in memory")
	lab.slider.drag_ended.emit(true)
	check(lab_store.writes == before+1,"Releasing the slider persists the drag in one write")
	restored.path = LAB_PATH
	restored.load_progress()
	check(restored.data.seasons.angle == 270 and restored.data.lessons.has("seasons"),"Released drag preserves both the final angle and completion")
	before = lab_store.writes
	for i in range(10): lab.update_display()
	check(lab_store.writes == before,"Refreshing completed experiment does not rewrite progress")
	lab.slider.drag_started.emit()
	lab.slider.value = 185
	check(lab_store.writes == before,"A new drag is batched again")
	lab._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(lab_store.writes == before+1 and not lab._slider_dragging,"Forced lifecycle save flushes an interrupted drag and releases batching")
	restored.load_progress()
	check(restored.data.seasons.angle == 185,"Forced lifecycle save includes the latest slider position")
	lab._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not lab._foreground,"Seasons stays inactive when focus returns during suspension")
	lab._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(lab._foreground and not lab.playing,"Seasons resumes without restarting a paused experiment")
	before = lab_store.writes
	lab.slider.value = 186
	check(lab_store.writes == before+1,"Input after an interrupted drag can save normally")
	holder.queue_free()
	await process_frame
	print("PASS: idempotent completion, save failure recovery, corrupt reload and batched seasons persistence" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
