extends SceneTree
var app
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func frames() -> void:
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	for i in range(14): await process_frame
func shot(name: String) -> void:
	await frames()
	RenderingServer.force_draw(false)
	await process_frame
	root.get_texture().get_image().save_png("res://work/year-v012-"+name+".png")
func run() -> void:
	create_timer(90).timeout.connect(func(): quit(2))
	root.size = Vector2i(1584,992)
	app = load("res://scenes/main.tscn").instantiate()
	app.progress.path = "res://work/year-test-progress.json"
	app.quality.path = "res://work/year-test-quality.cfg"
	app.audio.path = "res://work/year_tests-audio.cfg"
	app.progress.reset_progress()
	root.add_child(app)
	app.audio.set_enabled(false,false)
	app._open_lesson("year")
	await frames()
	var lab = app._year_lab
	check(lab.next_button.disabled,"Next experiment locked before completion")
	app._change_angle(90)
	check(lab.percent.text == "25%" and lab.elapsed.text == "约 91 天","Quarter orbit metrics agree")
	await shot("quarter")
	check(lab.canvas.earth_center.y < lab.canvas.orbit_center.y,"Quarter orbit Earth is at top")
	check(app._body.get_global_rect().end.y <= app._body_scroll.get_global_rect().end.y+2,"Reference-size first screen fits")
	for angle in [0,180,270,359.6]:
		app._change_angle(angle)
		await shot(str(angle))
	check(lab.percent.text != "100%" and not app.progress.data.lessons.has("year"),"No premature completion at rounded percent")
	app._set_playing(true)
	app._process(1.0/60.0)
	check(app._angle == 360 and not app._playing and not lab.next_button.disabled,"Playback completes and unlocks")
	await shot("complete")
	app._set_playing(true)
	check(app._playing and app._angle == 0,"Replay restarts and plays")
	lab.slider.value = 90
	check(not app._playing and app._angle == 90,"Manual scrub pauses")
	app._set_playing(true)
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not app._playing,"Background pauses")
	app._reset_lesson()
	check(app._angle == 0 and app.progress.data.lessons.has("year"),"Reset retains learned completion")
	app._change_angle(90)
	app._open_lesson("day")
	app._open_lesson("year")
	check(app._angle == 90,"Lesson switch preserves orbit position")
	for dimensions in [Vector2i(1280,800),Vector2i(1280,720),Vector2i(390,844)]:
		root.size = dimensions
		await shot(str(dimensions.x)+"x"+str(dimensions.y))
		check(app._body.size.x <= app._body_scroll.size.x+1,"No horizontal overflow "+str(dimensions))
		if dimensions.x > 900: check(app._body.get_global_rect().end.y <= app._body_scroll.get_global_rect().end.y+2,"Tablet first screen fits "+str(dimensions))
	print("PASS: year metrics, orbit position, completion, replay, pause, reset and responsive layouts" if failures.is_empty() else str(failures))
	app.queue_free()
	await process_frame
	await create_timer(.1).timeout
	quit(0 if failures.is_empty() else 1)
