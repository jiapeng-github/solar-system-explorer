extends SceneTree
const Visual = preload("res://scripts/planet_visual.gd")
const Catalog = preload("res://scripts/catalog.gd")
func _initialize() -> void:
	call_deferred("bake")
func bake() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(192,160)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var camera := Camera3D.new()
	camera.position = Vector3(0,.3,3.35)
	camera.fov = 38
	viewport.add_child(camera)
	camera.look_at(Vector3.ZERO)
	for p in Catalog.load_planets():
		var body := Visual.create(1,Color(p.color),p.id)
		viewport.add_child(body)
		body.rotation.y = 3.05
		body.material_override.set_shader_parameter("portrait_light",true)
		if body.has_node("Atmosphere"):
			body.get_node("Atmosphere").material_override.set_shader_parameter("portrait_light",true)
		if body.has_node("Clouds"):
			body.get_node("Clouds").material_override.set_shader_parameter("portrait_light",true)
		var ring: MeshInstance3D
		if p.id == "saturn":
			ring = Visual.ring(1)
			ring.rotation.z = deg_to_rad(-24)
			viewport.add_child(ring)
			camera.position = Vector3(0,2.8,6.0)
		else: camera.position = Vector3(0,.3,3.35)
		camera.look_at(Vector3.ZERO)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://assets/thumbnails/"+p.id+".png")
		body.queue_free()
		if is_instance_valid(ring): ring.queue_free()
		await process_frame
	print("PASS: eight planet thumbnails rendered")
	quit()
