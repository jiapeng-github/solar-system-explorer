extends SceneTree
var app
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func screen(): return app._body.get_node("ProgressPage")
func frames() -> void:
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	for i in range(14): await process_frame
func shot(name: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	await process_frame
	root.get_texture().get_image().save_png("res://work/progress-v014-"+name+".png")
func run() -> void:
	create_timer(90).timeout.connect(func(): quit(2))
	root.size = Vector2i(1584,992)
	app = load("res://scenes/main.tscn").instantiate()
	app.progress.path = "res://work/progress-test-state.json"
	app.quality.path = "res://work/progress-test-quality.cfg"
	app.audio.path = "res://work/progress_tests-audio.cfg"
	app.progress.reset_progress()
	for id in ["mercury","venus","earth"]: app.progress.visit(id)
	app.progress.complete("day")
	root.add_child(app)
	app.audio.set_enabled(false,false)
	app.navigate("progress")
	check(screen().recommendation.planet == "mars","Recommends missing rocky planet")
	check(screen().planet_buttons[2].visited and screen().planet_buttons[3].recommended,"Planet badges use actual records")
	await shot("reference")
	screen().recommended_button.pressed.emit()
	check(app.page == "explore" and app.selected_index == 3,"Recommendation opens Mars")
	app.progress.visit("mars")
	app.navigate("progress")
	check(screen().recommendation.kind == "task","All rocky planets recommend comparison")
	screen().recommended_button.pressed.emit()
	check(app.page == "compare" and app._compare_mode == "rotation","Comparison recommendation opens correct mode")
	app.progress.record_comparison("rotation:earth:mars")
	app.navigate("progress")
	check(screen().recommendation.kind == "quiz","Comparison completed recommends quiz")
	screen().recommended_button.pressed.emit()
	check(screen().quiz.visible and screen().answer_buttons.size() == 2,"Quiz is available")
	screen().answer_buttons[1].pressed.emit()
	check(not app.progress.data.tasks.has("rocky") and app._task_feedback.has("rocky"),"Wrong answer gives feedback without completion")
	screen().task_buttons[0].pressed.emit()
	screen().answer_buttons[0].pressed.emit()
	check(app.progress.data.tasks.has("rocky"),"Correct answer completes task")
	check(screen().recommendation.planet == "jupiter","Next unfinished task recommends Jupiter")
	screen().task_buttons[0].pressed.emit()
	check(screen().quiz.visible and screen().answer_buttons.is_empty(),"Completed task shows review")
	screen().quiz.hide()
	screen().reset_button.pressed.emit()
	check(app._reset_dialog.visible and app.progress.data.tasks.has("rocky"),"Reset opens confirmation without changing records")
	app._reset_dialog.hide()
	for i in range(3):
		app.navigate("progress")
		screen().lesson_buttons[i].pressed.emit()
		check(app._lab_mode == ["day","year","seasons"][i],"Experiment opens correctly")
	app.progress.reset_progress()
	for id in ["mercury","venus","earth"]: app.progress.visit(id)
	app.progress.complete("day")
	app._task_feedback.clear()
	app.navigate("progress")
	for dimensions in [Vector2i(1584,992),Vector2i(1280,800),Vector2i(1280,720),Vector2i(390,844)]:
		root.size = dimensions
		await shot(str(dimensions.x)+"x"+str(dimensions.y))
		check(app._body.size.x <= app._body_scroll.size.x+1,"Width fits "+str(dimensions))
		if dimensions.x > 900: check(app._body.get_global_rect().end.y <= app._body_scroll.get_global_rect().end.y+2,"First screen fits "+str(dimensions))
	app.progress.reset_progress()
	app.navigate("progress")
	check(screen().recommendation.planet == "mercury","Empty progress starts with Mercury")
	for id in ["mercury","venus","earth","mars","jupiter","saturn","uranus","neptune"]: app.progress.visit(id)
	for id in ["rocky","giants"]: app.progress.complete_task(id)
	app.navigate("progress")
	check(screen().recommendation.kind == "lesson","Completed tasks recommend unfinished lesson")
	for id in ["day","year","seasons"]: app.progress.complete(id)
	app.navigate("progress")
	check(screen().recommendation.title == "全部学习目标已完成","All complete offers revisit")
	app._reset_dialog.confirmed.emit()
	check(app.progress.data.visited.is_empty() and app.progress.data.lessons.is_empty() and app.progress.data.tasks.is_empty(),"Confirmed reset clears records")
	print("PASS: progress recommendations, planet status, experiments, quiz gates, review, reset and layouts" if failures.is_empty() else str(failures))
	app.queue_free()
	await process_frame
	await create_timer(.1).timeout
	quit(0 if failures.is_empty() else 1)
