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
	root.get_texture().get_image().save_png("res://work/home-v013-"+name+".png")
func home(): return app._body.get_node("HomePage")
func run() -> void:
	create_timer(80).timeout.connect(func(): quit(2))
	root.size = Vector2i(1584,992)
	app = load("res://scenes/main.tscn").instantiate()
	app.progress.path = "res://work/home-test-progress.json"
	app.quality.path = "res://work/home-test-quality.cfg"
	app.audio.path = "res://work/home_tests-audio.cfg"
	app.progress.reset_progress()
	for id in ["mercury","venus","earth"]: app.progress.visit(id)
	app.progress.complete("day")
	root.add_child(app)
	app.audio.set_enabled(false,false)
	check(app.page == "home","Launch opens departure home")
	check(app._brand_button.icon.resource_path == "res://assets/ui/brand-mark-v3.png","Header uses new logo")
	app.navigate("home")
	await shot("reference")
	check(home().visited == 3 and home().lessons == 1,"Home shows real learning counts")
	check(home().segments.get_child_count() == 8,"Planet progress has eight segments")
	check(home().hero_art.texture != null and not home().hero_art.is_processing(),"Hero is static artwork")
	home().primary_button.pressed.emit()
	check(app.page == "explore","Primary enters exploration")
	app.navigate("home")
	home().continue_button.pressed.emit()
	check(app.page == "explore" and app.selected_index == 2,"Continue opens saved Earth")
	for i in range(3):
		app.navigate("home")
		home().card_buttons[i].pressed.emit()
		check(app.page == ["explore","lab","compare"][i],"Card navigates correctly "+str(i))
		if i == 1: check(app._lab_mode == "seasons","Middle card opens seasons")
	app.navigate("home")
	home().progress_button.pressed.emit()
	check(app.page == "progress","Progress link opens progress")
	app.navigate("home")
	for dimensions in [Vector2i(1584,992),Vector2i(1280,800),Vector2i(1280,720),Vector2i(800,1100),Vector2i(390,844)]:
		root.size = dimensions
		await shot(str(dimensions.x)+"x"+str(dimensions.y))
		check(app._body.size.x <= app._body_scroll.size.x+1,"Width fits "+str(dimensions))
		if dimensions.x > 1000: check(app._body.get_global_rect().end.y <= app._body_scroll.get_global_rect().end.y+2,"First screen fits "+str(dimensions))
	app.progress.reset_progress()
	app.navigate("home")
	check(home().visited == 0 and home().lessons == 0,"Empty progress stays empty")
	for id in ["mercury","venus","earth","mars","jupiter","saturn","uranus","neptune"]: app.progress.visit(id)
	for id in ["day","year","seasons"]: app.progress.complete(id)
	app.selected_index = 7
	app.navigate("home")
	check(home().visited == 8 and home().lessons == 3 and home().continue_button.text.contains("海王星"),"Full progress and selected planet reflected")
	print("PASS: home navigation, real progress, static hero and responsive layouts" if failures.is_empty() else str(failures))
	app.queue_free()
	await process_frame
	await create_timer(.1).timeout
	quit(0 if failures.is_empty() else 1)
