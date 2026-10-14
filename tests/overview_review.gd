extends SceneTree
var app
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	for i in range(70):
		app.world.camera._process(1.0/60)
		app.world._process(1.0/60)
		await process_frame
func shot(name: String) -> void:
	await settle()
	RenderingServer.force_draw(false)
	await process_frame
	root.get_texture().get_image().save_png("res://work/"+name+".png")
func run() -> void:
	create_timer(60).timeout.connect(func(): quit(2))
	root.size = Vector2i(1280,800)
	app = load("res://scenes/main.tscn").instantiate()
	app.progress.path = "res://work/overview-review-progress.json"
	app.quality.path = "res://work/overview-review-quality.cfg"
	app.audio.path = "res://work/overview_review-audio.cfg"
	root.add_child(app)
	app.audio.set_enabled(false,false)
	app.world.days = 0
	app.world.select_body(7)
	app.world.reset_view()
	await shot("overview-v010")
	check_layout()
	for body in app.world.bodies:
		if not app.viewport.get_visible_rect().has_point(app.world.camera.unproject_position(body.global_position)):
			failures.append("Overview body out of view: "+body.name)
	for region in ["inner","outer"]:
		app.world.set_region(region)
		await shot("overview-v010-"+region)
	app.world.set_region("all")
	app.world.camera.zoom_by(.7)
	await shot("overview-v010-zoom")
	root.size = Vector2i(1280,720)
	app.world.reset_view()
	await shot("overview-v010-wide")
	check_layout()
	root.size = Vector2i(390,844)
	app.world.reset_view()
	await shot("overview-v010-phone")
	if app._body.size.x > app._body_scroll.size.x+1: failures.append("Phone horizontal overflow")
	app.queue_free()
	await process_frame
	print("PASS: overview and regional screenshots; tablet fit and phone width" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
func check_layout() -> void:
	if app._body.get_global_rect().end.y > app._body_scroll.get_global_rect().end.y+2:
		failures.append("Overview vertical overflow "+str(root.size))
