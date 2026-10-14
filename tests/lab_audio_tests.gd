extends SceneTree
const Sound = preload("res://scripts/ui_audio.gd")
const Store = preload("res://scripts/progress_store.gd")
var failures: Array[String] = []
var heard: Array[String] = []
var audio
var holder: Control
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func button_named(node: Node, text: String) -> Button:
	if node is Button and node.text == text: return node
	for child in node.get_children():
		var found := button_named(child,text)
		if found != null: return found
	return null
func expect(cues: Array, message: String) -> void:
	for i in range(3): await process_frame
	check(heard == cues,message+": "+str(heard))
	heard.clear()
	audio._last_played.clear()
func run() -> void:
	create_timer(45).timeout.connect(func(): quit(2))
	audio = Sound.new()
	audio.path = "res://work/lab-audio-test.cfg"
	audio.cue_played.connect(func(cue): heard.append(cue))
	root.add_child(audio)
	audio.enabled = true
	audio.foreground = true
	holder = Control.new()
	holder.size = Vector2(1280,800)
	root.add_child(holder)
	var year = preload("res://scripts/ui/year_lab.gd").new()
	holder.add_child(year)
	year.update_state(0,false,false)
	await expect([],"Year initialization is silent")
	year.play_button.pressed.emit()
	await expect(["toggle_on"],"Year play feedback")
	year.update_state(90,true,false)
	year.play_button.pressed.emit()
	await expect(["toggle_off"],"Year pause feedback")
	year.update_state(0,false,false)
	button_named(year,"↻ 重置").pressed.emit()
	await expect([],"Unchanged year reset is silent")
	year.update_state(90,false,false)
	button_named(year,"↻ 重置").pressed.emit()
	await expect(["reset"],"Year reset feedback")
	button_named(year,"公转与一年").pressed.emit()
	await expect([],"Current experiment tab is silent")
	button_named(year,"自转与昼夜").pressed.emit()
	await expect(["select"],"Other experiment tab selects")
	var year_ref: WeakRef = weakref(year)
	year.angle_changed.connect(func(value):
		var target = year_ref.get_ref()
		if is_instance_valid(target): target.update_state(value,false,value >= 360)
	)
	button_named(year,"一年").pressed.emit()
	await expect(["complete"],"Year final tick replaces adjust with completion")
	button_named(year,"一年").pressed.emit()
	await expect([],"Repeated final tick is silent")
	year.slider.value = 120
	await expect([],"Programmatic year slider update is silent")
	year.queue_free()
	await process_frame
	var store = Store.new()
	store.path = "res://work/lab-audio-test-progress.json"
	store.reset_progress()
	var seasons = preload("res://scripts/ui/seasons_lab.gd").new()
	seasons.store = store
	holder.add_child(seasons)
	await expect([],"Seasons restore is silent")
	seasons.set_south(true)
	await expect([],"Programmatic hemisphere change is silent")
	seasons.hemi_buttons[0].pressed.emit()
	await expect(["select"],"Hemisphere selection feedback")
	seasons.hemi_buttons[0].pressed.emit()
	await expect([],"Repeated hemisphere selection is silent")
	seasons.answer(1,true)
	await expect(["retry"],"Wrong answer has retry feedback")
	seasons.answer(1,true)
	await expect([],"Repeated submitted answer is silent")
	seasons.answer(0,true)
	await expect(["correct"],"Correct answer without observations is not completion")
	seasons.set_tilt(0,true)
	await expect(["select"],"Contrast changes tilt and step with one cue")
	seasons.set_tilt(23.4,true)
	await expect(["select"],"Restore tilt selection")
	for angle in [0,180]: seasons.set_angle(angle,true)
	await expect([],"Programmatic observations remain silent")
	seasons.slider.drag_started.emit()
	seasons.slider.value = 270
	await expect([],"Dragging does not sound before release")
	seasons.slider.drag_ended.emit(true)
	await expect(["complete"],"Final observation release replaces adjust with completion")
	check(store.data.lessons.has("seasons"),"Completed seasons record persisted")
	seasons.answer(1,true)
	await expect(["retry"],"Changed answer still gives feedback after completion")
	seasons.answer(0,true)
	await expect(["correct"],"Previously completed lesson does not repeat reward")
	seasons.set_step(0)
	seasons.set_step(0,true)
	await expect([],"Already in observation is silent")
	seasons.set_step(2,true)
	await expect(["select"],"Enter verification feedback")
	seasons.set_step(0,true)
	await expect(["back"],"Return from verification feedback")
	seasons.reset(true)
	await expect(["reset"],"Seasons reset feedback")
	seasons.reset(true)
	await expect([],"Unchanged seasons reset silent")
	seasons.set_playing(true,true)
	await expect(["toggle_on"],"Seasons user playback starts")
	seasons.set_step(seasons.state.step,true)
	seasons.set_tilt(seasons.state.tilt,true)
	seasons.set_south(seasons.state.south,true)
	seasons.answer(seasons.state.answer,true)
	check(seasons.playing,"Current selections do not implicitly pause playback")
	await expect([],"Current selections remain silent during playback")
	seasons._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await expect([],"Background pause silent")
	check(not seasons.playing,"Background pause stops playback")
	seasons._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await expect([],"Foreground resume does not replay audio")
	seasons.set_playing(true,true)
	await expect(["toggle_on"],"Playback restarts before Android pause")
	seasons._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(not seasons.playing and not seasons._foreground,"Android pause stops playback and clears foreground")
	await expect([],"Android pause is silent")
	seasons._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(seasons._foreground and not seasons.playing,"Android resume does not restart playback")
	await expect([],"Android resume does not replay audio")
	seasons.queue_free()
	await process_frame
	store.reset_progress()
	store.data.seasons = {"angle":180.0,"tilt":23.4,"south":false,"step":0,"answer":0,"contrast":true,"visited":[0,1,2]}
	seasons = preload("res://scripts/ui/seasons_lab.gd").new()
	seasons.store = store
	holder.add_child(seasons)
	seasons.set_playing(true,true)
	await expect(["toggle_on"],"Playback completion fixture starts")
	seasons._process(4)
	await expect(["complete"],"User playback newly completing observations gives one reward")
	seasons._process(1)
	await expect([],"Continued playback never repeats completion")
	print("PASS: lab audio user boundaries, silence, slider release, first completion and repeat guards" if failures.is_empty() else str(failures))
	audio.set_foreground(false)
	await create_timer(0.05).timeout
	holder.queue_free()
	audio.queue_free()
	year = null
	seasons = null
	store = null
	for i in range(2): await process_frame
	# Give the mixer time to release the long-lived music playback after freeing.
	await create_timer(0.1).timeout
	quit(0 if failures.is_empty() else 1)
