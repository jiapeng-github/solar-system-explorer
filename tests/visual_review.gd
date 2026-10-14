extends SceneTree
var app
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	for i in range(60):
		if app.page == "explore": app.world.camera._process(1.0/60)
		await process_frame
func shot(name: String) -> void:
	await settle()
	RenderingServer.force_draw(false)
	await process_frame
	root.get_texture().get_image().save_png("res://work/"+name+".png")
func run() -> void:
	create_timer(60).timeout.connect(func() -> void: quit(2))
	app = load("res://scenes/main.tscn").instantiate()
	app.progress.path = "res://work/visual-review-progress.json"
	app.quality.path = "res://work/visual-review-settings.cfg"
	app.audio.path = "res://work/visual_review-audio.cfg"
	root.add_child(app)
	app.audio.set_enabled(false,false)
	app._set_quality(1)
	for dimensions in [Vector2i(1280,800),Vector2i(1280,720)]:
		root.size = dimensions
		await settle()
		for page in ["explore","home","lab","compare"]:
			app.navigate(page)
			if page == "explore": app.world.select_body(2,true)
			if page == "lab": app._open_lesson("day"); app._reset_lesson()
			if page == "compare": app._choose_comparison(0,2); app._choose_comparison(1,4)
			await shot(page+"-v08-"+str(dimensions.y))
			if app._body.get_global_rect().end.y > app._body_scroll.get_global_rect().end.y+2:
				failures.append(page+" overflows "+str(dimensions))
	for mode in ["size","distance","rotation","period"]:
		app._compare_mode = mode
		app.navigate("compare")
		await shot("compare-v09-"+mode)
		if app._body.get_global_rect().end.y > app._body_scroll.get_global_rect().end.y+2:
			failures.append("compare "+mode+" overflows 1280x720")
	app._compare_mode = "size"
	root.size = Vector2i(390,844)
	await settle()
	for page in ["home","lab","compare","knowledge","progress"]:
		app.navigate(page)
		await shot(page+"-v08-phone")
		if app.size.x > root.content_scale_size.x+1 or app._body.size.x > app._body_scroll.size.x+1: failures.append(page+" horizontal phone overflow")
	print("PASS: four tablet pages fit at 1280x800 / 1280x720; five phone layouts fit width" if failures.is_empty() else str(failures))
	app.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
