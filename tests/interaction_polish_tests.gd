extends SceneTree

const STATE_PATH := "res://work/interaction-polish-progress.json"
const QUALITY_PATH := "res://work/interaction-polish-quality.cfg"
const AUDIO_PATH := "res://work/interaction-polish-audio.cfg"
var app
var failures: Array[String] = []
var heard: Array[String] = []
var _master_was_muted := false

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for i in range(10): await process_frame

func press_key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)

func activate(button: BaseButton) -> void:
	button.grab_focus()
	# A real activation exercises BaseButton's toggle behavior before pressed.
	# Emitting pressed alone would miss the selected-thumbnail regression.
	press_key(KEY_SPACE)

func find_button(node: Node, caption: String) -> Button:
	if node is Button and node.text == caption: return node
	for child in node.get_children():
		var found := find_button(child,caption)
		if found != null: return found
	return null

func remove_test_files() -> void:
	for path in [STATE_PATH,QUALITY_PATH,AUDIO_PATH]:
		for suffix in ["",".tmp",".bak",".corrupt"]:
			if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)

func run() -> void:
	create_timer(90).timeout.connect(func(): quit(2))
	remove_test_files()
	_master_was_muted = AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0,true)
	# Keep sound events observable without allowing the test to make sound.
	var config := ConfigFile.new()
	config.set_value("audio","enabled",false)
	config.save(AUDIO_PATH)
	root.size = Vector2i(1280,800)
	app = load("res://scenes/main.tscn").instantiate()
	app.progress.path = STATE_PATH
	app.quality.path = QUALITY_PATH
	app.audio.path = AUDIO_PATH
	app.progress.reset_progress()
	app.audio.cue_played.connect(func(cue: String): heard.append(cue))
	root.add_child(app)
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	app.set_process(false)
	app.audio.set_enabled(true,false)
	await settle()
	heard.clear()
	app.audio._last_played.clear()
	app.navigate("explore")
	await settle()
	app.world.set_process(false)
	check(app.selected_index == 2 and app.progress.data.visited.is_empty(),"Overview starts at Earth without an automatic visit")
	activate(app._planet_buttons[2])
	await settle()
	check(app.progress.data.visited == ["earth"],"First explicit click on default Earth records its visit")
	check(app._planet_buttons[2].button_pressed,"First Earth click keeps its thumbnail selected")
	check(heard == ["select"],"First explicit Earth visit gives one selection cue")
	heard.clear()
	app.audio._last_played.clear()
	activate(app._planet_buttons[2])
	await settle()
	check(app._planet_buttons[2].button_pressed,"Repeated selected-thumbnail activation keeps the selection border")
	check(app.progress.data.visited == ["earth"],"Repeated selection never duplicates progress")
	check(heard.is_empty(),"Repeated unchanged selection stays silent")
	activate(app._planet_buttons[5])
	await settle()
	check(app.selected_index == 5 and app._planet_buttons[5].button_pressed and not app._planet_buttons[2].button_pressed,"Changing selection leaves exactly the new thumbnail selected")
	activate(app._planet_buttons[5])
	await settle()
	check(app._planet_buttons[5].button_pressed,"Repeated non-default selection also retains its border")

	app._open_lesson("day")
	await settle()
	app._change_angle(180)
	app._set_playing(true)
	app._slider.grab_focus()
	press_key(KEY_RIGHT)
	check(not app._playing,"Keyboard adjustment pauses daylight playback")
	check(app._angle > 180,"Keyboard adjustment changes the daylight angle")
	var adjusted_angle: float = app._angle
	app._process(1.0)
	check(is_equal_approx(app._angle,adjusted_angle),"A later animation frame does not overwrite the manual daylight angle")

	root.size = Vector2i(390,844)
	await settle()
	app._open_lesson("seasons")
	await settle()
	app._body_scroll.scroll_vertical = 100000
	await settle()
	check(app._body_scroll.scroll_vertical > 0,"Portrait experiment has a scrollable lower section")
	app._open_lesson("year")
	await settle()
	check(app._body_scroll.scroll_vertical == 0,"Switching experiments starts the new experiment at its heading")
	app._body_scroll.scroll_vertical = 160
	await settle()
	var saved_scroll: int = app._body_scroll.scroll_vertical
	check(saved_scroll > 0,"Year experiment can retain a meaningful portrait scroll position")
	app.navigate("home")
	await settle()
	app.navigate("lab")
	await settle()
	check(app._lab_mode == "year" and absi(app._body_scroll.scroll_vertical-saved_scroll) <= 1,"Returning to the same experiment preserves its scroll position")
	app._open_lesson("day")
	await settle()
	check(app._body_scroll.scroll_vertical == 0,"A second experiment switch also resets the incoming scroll position")

	app.selected_index = 2
	app.navigate("knowledge")
	await settle()
	check(app._nav_buttons.explore.button_pressed,"Knowledge cards retain the Explore navigation highlight")
	for destination in ["home","lab","compare","progress"]:
		check(not app._nav_buttons[destination].button_pressed,"Knowledge cards do not select unrelated navigation: "+destination)
	var earth_compare := find_button(app._body,"与木星比较")
	check(earth_compare != null,"Earth knowledge card offers comparison with Jupiter")
	if earth_compare != null:
		activate(earth_compare)
		await settle()
		check(app.page == "compare" and app._compare_first == 2 and app._compare_second == 4,"Earth's comparison action opens Earth and Jupiter")
	app.selected_index = 5
	app.navigate("knowledge")
	await settle()
	var saturn_compare := find_button(app._body,"与地球比较")
	check(saturn_compare != null,"Other knowledge cards still offer comparison with Earth")
	if saturn_compare != null:
		activate(saturn_compare)
		await settle()
		check(app.page == "compare" and app._compare_first == 2 and app._compare_second == 5,"Saturn's comparison action retains Earth and Saturn")

	for via_compare in [false,true]:
		app._history.clear()
		app.navigate("home",false)
		app.navigate("explore")
		app.navigate("knowledge")
		if via_compare: app._compare_with_earth()
		await settle()
		var return_button := find_button(app._body,"←  返回探索" if via_compare else "返回行星探索")
		activate(return_button)
		await settle()
		check(app.page == "explore" and app._history == ["home"],"Explicit return consumes the knowledge/comparison route")
		app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		check(app.page == "home","Android back after explicit return does not reopen the page just left")
	app.queue_free()
	await process_frame
	await create_timer(.1).timeout
	remove_test_files()
	AudioServer.set_bus_mute(0,_master_was_muted)
	print("PASS: actual thumbnail activation, default Earth visit, daylight keyboard pause, independent experiment scrolling and knowledge navigation" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
