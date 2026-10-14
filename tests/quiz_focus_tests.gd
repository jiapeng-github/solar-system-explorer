extends SceneTree
var app
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func screen(): return app._body.get_node("ProgressPage")
func settle() -> void:
	for i in range(4): await process_frame
func press_key(code: Key, shift := false) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	event.shift_pressed = shift
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)
func run() -> void:
	create_timer(90).timeout.connect(func(): quit(2))
	root.size = Vector2i(1280,800)
	app = load("res://scenes/main.tscn").instantiate()
	app.progress.path = "res://work/quiz-focus-state.json"
	app.quality.path = "res://work/quiz-focus-quality.cfg"
	app.audio.path = "res://work/quiz_focus_tests-audio.cfg"
	app.progress.reset_progress()
	for id in ["mercury","venus","earth","mars","jupiter","saturn","uranus","neptune"]: app.progress.visit(id)
	app.progress.record_comparison("rotation:earth:mars")
	app.progress.record_comparison("size:earth:jupiter")
	root.add_child(app)
	app.audio.set_enabled(false,false)
	app.navigate("progress")
	await settle()
	var opener: Button = screen().task_buttons[1]
	opener.grab_focus()
	screen().open_quiz(1)
	await settle()
	var overlay = screen().quiz
	var targets: Array = overlay._focus_targets
	check(targets.size() == 4,"Question exposes close, two options and return controls")
	for target in targets:
		check(target.custom_minimum_size.x >= 44 and target.custom_minimum_size.y >= 44,"Answer controls have a usable touch target")
	targets.back().grab_focus()
	press_key(KEY_TAB)
	await settle()
	check(root.gui_get_focus_owner() == targets.front(),"Tab wraps inside answer card")
	press_key(KEY_TAB,true)
	await settle()
	check(root.gui_get_focus_owner() == targets.back(),"Shift-Tab wraps inside answer card")
	opener.grab_focus()
	check(overlay.is_ancestor_of(root.gui_get_focus_owner()),"Background control cannot keep focus while card is open")
	overlay.dismiss()
	check(root.gui_get_focus_owner() == opener,"Closing restores the triggering task button")
	app.progress.complete_task("rocky")
	app.navigate("progress")
	await settle()
	opener = screen().task_buttons[0]
	opener.grab_focus()
	screen().open_quiz(0)
	await settle()
	check(screen().answer_buttons.is_empty(),"Completed task shows a review card")
	check(screen().quiz.is_ancestor_of(root.gui_get_focus_owner()),"Completed card receives keyboard focus")
	press_key(KEY_ESCAPE)
	await settle()
	check(not screen().quiz.visible and root.gui_get_focus_owner() == opener,"Escape closes completed card and restores focus")
	opener = screen().task_buttons[1]
	opener.grab_focus()
	screen().open_quiz(1)
	var previous_overlay: WeakRef = weakref(screen().quiz)
	screen().answer_buttons[0].pressed.emit()
	await settle()
	check(previous_overlay.get_ref() == null,"Answer submission safely releases the previous card")
	check(screen().quiz.visible and screen().quiz.is_ancestor_of(root.gui_get_focus_owner()),"Rebuilt wrong-answer card retains focus inside")
	screen().quiz.dismiss()
	check(is_instance_valid(root.gui_get_focus_owner()) and screen().is_ancestor_of(root.gui_get_focus_owner()),"Rebuilt card closes to a surviving page control")
	screen().task_buttons[1].grab_focus()
	screen().open_quiz(1)
	screen().answer_buttons[1].pressed.emit()
	await settle()
	check(screen().answer_buttons.is_empty() and screen().quiz.is_ancestor_of(root.gui_get_focus_owner()),"Correct-answer review receives focus after page rebuild")
	screen().quiz.dismiss()
	check(is_instance_valid(root.gui_get_focus_owner()) and screen().is_ancestor_of(root.gui_get_focus_owner()),"Correct-answer close never restores a freed node")
	app.queue_free()
	await process_frame
	await create_timer(.1).timeout
	for path in ["res://work/quiz-focus-state.json","res://work/quiz-focus-state.json.bak","res://work/quiz-focus-quality.cfg"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("PASS: quiz focus containment, keyboard dismissal, touch targets and safe page rebuild" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
