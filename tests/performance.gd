extends SceneTree
var app
var results: Array = []
func _initialize() -> void:
	call_deferred("run")
func sample(label: String) -> void:
	for i in range(30): await process_frame
	var timings: Array[float] = []
	var previous := Time.get_ticks_usec()
	for i in range(120):
		await process_frame
		var now := Time.get_ticks_usec()
		timings.append((now-previous)/1000.0)
		previous = now
	timings.sort()
	results.append({"scene":label,"frames":120,"median_frame_ms":timings[60],"p95_frame_ms":timings[114],"static_bytes":OS.get_static_memory_usage(),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
func run() -> void:
	create_timer(60).timeout.connect(func() -> void: quit(2))
	app = load("res://scenes/main.tscn").instantiate()
	app.progress.path = "res://work/perf-progress.json"
	app.quality.path = "res://work/perf-settings.cfg"
	app.audio.path = "res://work/performance-audio.cfg"
	root.add_child(app)
	app.audio.set_enabled(false,false)
	app._set_quality(2)
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	app.world.reset_view()
	app.world.paused = false
	await sample("overview_running_high")
	app.world.select_body(2,true)
	await sample("earth_closeup_high")
	app._open_lesson("year")
	app._reset_lesson()
	app._set_playing(true)
	await sample("year_playback")
	app.navigate("home")
	await sample("static_home")
	var output := {"platform":OS.get_name(),"renderer":RenderingServer.get_video_adapter_name(),"scope":"Desktop short samples including presentation scheduling; not Android performance or a before/after speedup claim", "samples":results}
	var file := FileAccess.open("res://work/render-samples-v06.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(output,"  "))
	file.close()
	app.queue_free()
	await process_frame
	print("PASS: four desktop rendering scenarios sampled")
	quit()
