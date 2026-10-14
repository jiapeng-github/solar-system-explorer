extends SceneTree
var app
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func page(): return app._body.get_node("ProgressPage")
func shot(name: String) -> void:
	for i in range(20): await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	root.get_texture().get_image().save_png("res://work/quiz-v015-"+name+".png")
func run() -> void:
	create_timer(90).timeout.connect(func(): quit(2))
	root.size = Vector2i(1584,992)
	app = load("res://scenes/main.tscn").instantiate()
	app.progress.path = "res://work/quiz-state.json"
	app.quality.path = "res://work/quiz-quality.cfg"
	app.audio.path = "res://work/quiz_tests-audio.cfg"
	app.progress.reset_progress()
	for id in ["mercury","venus","earth","mars","jupiter","saturn","uranus","neptune"]: app.progress.visit(id)
	app.progress.record_comparison("rotation:earth:mars")
	app.progress.record_comparison("size:earth:jupiter")
	root.add_child(app)
	app.audio.set_enabled(false,false)
	for task in range(2):
		app.navigate("progress")
		page().open_quiz(task)
		await shot("task-"+str(task))
		check(page().quiz.card.size.y < 650,"Task card compact")
		page().answer_buttons[1-task].pressed.emit()
		await shot("wrong-"+str(task))
		check(page().quiz.visible and page().answer_buttons.size() == 2,"Wrong answer keeps question open")
		page().answer_buttons[task].pressed.emit()
		await shot("correct-"+str(task))
		check(page().quiz.visible and page().answer_buttons.is_empty(),"Correct answer shows review")
		page().quiz.dismiss()
		check(not page().quiz.visible,"Close works")
	app.progress.reset_progress()
	app.navigate("progress")
	for dimensions in [Vector2i(1280,720),Vector2i(390,844),Vector2i(844,390)]:
		root.size = dimensions
		page().open_quiz(1)
		await shot("layout-"+str(dimensions.x))
		var overlay = page().quiz
		check(overlay.card.position.x >= 0 and overlay.card.position.y >= 0,"Card in viewport")
		check(overlay.card.get_rect().end.y <= overlay.size.y,"Bottom stays visible")
		check(overlay.content.size.x <= overlay.scroll.size.x+1,"Options fit width")
	page().quiz.dismiss()
	root.size = Vector2i(1584,992)
	app._open_lesson("day")
	app._answer_question("地球公转")
	await shot("day-wrong")
	check(app._answer_buttons[1].text.begins_with("↻"),"Wrong day answer does not show checkmark")
	app._answer_question("地球自转")
	check(app.progress.data.lessons.has("day"),"Day completes correctly")
	app._open_lesson("seasons")
	var lab = app._body.get_child(0)
	# Locate the seasons screen without relying on its generated node name.
	for node in app._body.get_children():
		if node.has_method("set_step"): lab = node
	lab.set_step(2)
	lab.answer(1)
	await shot("seasons-wrong")
	check(not app.progress.data.lessons.has("seasons"),"Wrong seasons answer cannot complete")
	app.queue_free()
	await process_frame
	for path in ["res://work/quiz-state.json","res://work/quiz-state.json.bak","res://work/quiz-quality.cfg"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	print("PASS: task answers, retained feedback, review, dismissal, responsive overlays and experiment answer states" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
