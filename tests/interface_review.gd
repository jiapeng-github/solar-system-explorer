extends SceneTree
var app
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	for i in range(16): await process_frame
func shot(name: String) -> void:
	await settle()
	RenderingServer.force_draw(false)
	await process_frame
	root.get_texture().get_image().save_png("res://work/audit-v021-"+name+".png")
func run() -> void:
	create_timer(240).timeout.connect(func(): quit(2))
	app = load("res://scenes/main.tscn").instantiate()
	app.progress.path = "res://work/interface-progress.json"
	app.quality.path = "res://work/interface-quality.cfg"
	app.audio.path = "res://work/interface_review-audio.cfg"
	app.progress.reset_progress()
	root.add_child(app)
	app.audio.set_enabled(false,false)
	for dimensions in [Vector2i(1280,800),Vector2i(1280,720),Vector2i(800,1100),Vector2i(390,844)]:
		root.size = dimensions
		await settle()
		for destination in ["home","explore","close","day","year","seasons","size","distance","rotation","period","knowledge","progress"]:
			match destination:
				"day","year","seasons": app._open_lesson(destination)
				"size","distance","rotation","period": app._compare_mode = destination; app.navigate("compare")
				"close": app.navigate("explore"); app.world.select_body(2,true)
				_: app.navigate(destination)
			if destination == "explore": app.world.reset_view()
			await settle()
			app._body_scroll.scroll_vertical = 0
			await shot(destination+"-"+str(dimensions.x)+"x"+str(dimensions.y))
			if app._body.size.x > app._body_scroll.size.x+1: failures.append(destination+" width overflow "+str(dimensions))
			if dimensions.x > 900 and destination != "knowledge" and app._body.get_global_rect().end.y > app._body_scroll.get_global_rect().end.y+2: failures.append(destination+" height overflow "+str(dimensions))
			if dimensions.x < 700:
				app._body_scroll.scroll_vertical = int(app._body.size.y)
				await shot(destination+"-phone-bottom")
		app._show_sources()
		await shot("sources-"+str(dimensions.x))
		if app._sources.card.get_rect().end.y > app._sources.size.y: failures.append("sources vertical overflow")
		app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		if app._sources.visible: failures.append("Back failed to dismiss sources")
		app._reset_dialog.popup_centered()
		await shot("reset-"+str(dimensions.x))
		app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		if app._reset_dialog.visible: failures.append("Back failed to dismiss reset")
	app.navigate("progress")
	var progress_page = app._body.get_node("ProgressPage")
	progress_page.open_quiz(0)
	app._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	if app.page != "progress" or progress_page.quiz.visible: failures.append("Android back must close quiz before leaving page")
	app.navigate("explore")
	app.world.set_region("outer")
	app.world.select_body(5,true)
	app._reset_learning()
	if app.world.selected_index != 2 or app.world.region != "all" or not app.progress.data.visited.is_empty(): failures.append("Reset must synchronize Earth selection without visiting")
	app.navigate("explore")
	if app.selected_index != app.world.selected_index: failures.append("Selection mismatch after reset")
	print("PASS: all pages fit reviewed layouts" if failures.is_empty() else str(failures))
	app.queue_free()
	await process_frame
	await create_timer(0.1).timeout
	for path in ["res://work/interface-progress.json","res://work/interface-progress.json.bak","res://work/interface-quality.cfg"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	quit(0 if failures.is_empty() else 1)
