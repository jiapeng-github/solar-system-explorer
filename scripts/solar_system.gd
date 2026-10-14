extends Node3D
signal selected(index: int)
signal view_changed
const Catalog = preload("res://scripts/catalog.gd")
const CameraRig = preload("res://scripts/orbit_camera.gd")
const Visual = preload("res://scripts/planet_visual.gd")
var catalog: Array = []
var bodies: Array[MeshInstance3D] = []
var labels: Array[Label3D] = []
var camera: Camera3D
var days := 0.0
var days_per_second := 1.0
var paused := true
var sun: MeshInstance3D
var moon: MeshInstance3D
var highlight: MeshInstance3D
var selected_index := 2
var _saturn_ring: MeshInstance3D
var orbits: Array[MeshInstance3D] = []
var orbits_visible := true
var quality_level := 1
var sun_glow: Sprite3D
var _label_clock := 0.0
var region := "all"
const OVERVIEW_RADII = [3.0,4.8,5.5,4.0,10.0,8.0,6.5,6.5]

func _ready() -> void:
	catalog = Catalog.load_planets()
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.background_color = Color("07101d")
	add_child(env)
	sun = _make_body(7.0,Color("ffd58b"),"sun")
	sun_glow = Sprite3D.new()
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0,0.45,1.0])
	gradient.colors = PackedColorArray([Color(1,.65,.18,.3),Color(1,.45,.08,.16),Color(1,.25,.03,0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(.5,.5)
	texture.fill_to = Vector2(1,.5)
	sun_glow.texture = texture
	sun_glow.pixel_size = .28
	sun_glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sun.add_child(sun_glow)
	sun_glow.visible = false
	for i in range(catalog.size()):
		var p: Dictionary = catalog[i]
		var body := _make_body(p.display_radius,Color(p.color),p.id)
		body.name = p.id
		bodies.append(body)
		if p.id == "saturn":
			var ring := Visual.ring(p.display_radius)
			add_child(ring)
			_saturn_ring = ring
			ring.rotation.z = deg_to_rad(27)
		var label := Label3D.new()
		label.text = p.name
		label.font_size = 40
		label.pixel_size = 0.00085
		label.fixed_size = true
		label.position.y = p.display_radius + 1.5
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("c0cee0")
		add_child(label)
		labels.append(label)
		var orbit := _orbit(p.display_a,p.eccentricity)
		add_child(orbit)
		orbits.append(orbit)
	moon = _make_body(0.125,Color("c3bdb0"),"moon")
	moon.name = "Moon"
	highlight = _orbit(0.9,0,Color("75dff5"))
	add_child(highlight)
	camera = CameraRig.new()
	add_child(camera)
	camera.tapped.connect(_pick)
	camera.overview_radius = 156.0

	update_positions()

func _process(delta: float) -> void:
	if not paused:
		days += delta * days_per_second
		update_positions()
	if camera.follow_node == null:
		for i in range(bodies.size()):
			var radius: float = catalog[i].display_radius
			var desired: float = OVERVIEW_RADII[i]/radius
			# Do not enlarge the departure planet around the camera during zoom-out.
			var safe := maxf(1.0,camera.position.distance_to(bodies[i].position)/(radius*5.0))
			var scale_value := lerpf(bodies[i].scale.x,minf(desired,safe),1.0-exp(-delta*12.0))
			bodies[i].scale = Vector3.ONE*scale_value
		_saturn_ring.scale = bodies[5].scale
	_label_clock += delta
	if _label_clock >= .1:
		_label_clock = 0.0
		_layout_labels()

func update_positions() -> void:
	for i in range(bodies.size()):
		var p: Dictionary = catalog[i]
		bodies[i].position = Catalog.orbital_position(p.display_a,p.eccentricity,Catalog.mean_anomaly(days,p.period_years,p.phase))
		bodies[i].rotation.y = -fposmod(days / p.rotation_days,1.0)*TAU + (1.8 if p.id == "earth" else 0.0)
	if is_instance_valid(_saturn_ring):
		_saturn_ring.position = bodies[5].position
	if bodies.size() > 2:
		moon.position = bodies[2].position + Vector3(cos(days/27.3*TAU+1.2),0,-sin(days/27.3*TAU+1.2))*1.20
		highlight.visible = false
		highlight.position = bodies[selected_index].position
		highlight.scale = Vector3.ONE * (maxf(catalog[selected_index].display_radius*2.5,1.8) + 1.2)/0.9

func _layout_labels() -> void:
	for label in labels: label.visible = false

func select_body(index: int, close_up := false) -> void:
	selected_index = clampi(index,0,bodies.size()-1)
	if not close_up and camera.follow_node == null and not _in_region(selected_index):
		region = "all"
		camera.overview_radius = 156.0
		camera.reset_view()
	if close_up:
		camera.focus_body(bodies[selected_index],catalog[selected_index].display_radius)
	set_labels(camera.follow_node == null)
	_refresh_visibility()
	_refresh_orbits()
	update_positions()
	selected.emit(selected_index)
	view_changed.emit()

func set_labels(enabled: bool) -> void:
	for label in labels:
		label.visible = false

func _pick(screen_position: Vector2) -> void:
	var best := -1
	var best_distance := INF
	for i in range(bodies.size()):
		if not bodies[i].visible or camera.is_position_behind(bodies[i].global_position):
			continue
		var point: Vector2 = camera.unproject_position(bodies[i].global_position)
		var offset: Vector2 = camera.unproject_position(bodies[i].global_position + camera.global_basis.x*catalog[i].display_radius*bodies[i].scale.x)
		var hit_radius := maxf(point.distance_to(offset),24.0)
		var d := point.distance_to(screen_position)
		if d < hit_radius and d < best_distance:
			best = i
			best_distance = d
	if best >= 0:
		if selected_index == best and camera.follow_node == bodies[best]: return
		preload("res://scripts/ui_audio.gd").play_from(self,"focus")
		select_body(best,true)

func _in_region(index: int) -> bool:
	return region == "all" or (index < 4 if region == "inner" else index >= 4)

func set_region(value: String) -> void:
	region = value if value in ["all","inner","outer"] else "all"
	if not _in_region(selected_index):
		selected_index = 2 if region == "inner" else 5
		selected.emit(selected_index)
	reset_view()

func reset_view() -> void:
	camera.overview_radius = 78.0 if region == "inner" else 156.0
	camera.reset_view()
	set_labels(true)
	_refresh_visibility()
	_refresh_orbits()
	update_positions()
	view_changed.emit()

func _refresh_visibility() -> void:
	var overview := camera.follow_node == null
	sun.visible = overview
	for i in range(bodies.size()):
		bodies[i].visible = _in_region(i) if overview else i == selected_index
		(bodies[i].material_override as ShaderMaterial).set_shader_parameter("portrait_light",overview)
		if not overview: bodies[i].scale = Vector3.ONE
		labels[i].modulate = Color("8eeaff") if i == selected_index else Color("c0cee0")
	moon.visible = not overview and selected_index == 2
	_saturn_ring.scale = bodies[5].scale
	_saturn_ring.visible = _in_region(5) if overview else selected_index == 5

func set_orbits(enabled: bool) -> void:
	orbits_visible = enabled
	_refresh_orbits()

func _refresh_orbits() -> void:
	for i in range(orbits.size()):
		orbits[i].visible = orbits_visible and camera.follow_node == null and _in_region(i)
		var material := orbits[i].material_override as StandardMaterial3D
		material.albedo_color = Color("65bad2") if i == selected_index else Color("647585")

func _make_body(radius: float, color: Color, id: String) -> MeshInstance3D:
	var body := Visual.create(radius,color,id)
	add_child(body)
	return body

func _orbit(a: float, e: float, color := Color("1c344b")) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(256):
		var t0 := float(i)/256*TAU
		var t1 := float(i+1)/256*TAU
		for pair in [[t0,-.42],[t0,.42],[t1,.42],[t0,-.42],[t1,.42],[t1,-.42]]:
			var radius: float = a+pair[1]
			mesh.surface_add_vertex(Vector3(radius*cos(pair[0])-a*e,0,-radius*sqrt(1-e*e)*sin(pair[0])))
	mesh.surface_end()
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = color
	node.material_override = material
	return node


func set_quality(level: int) -> void:
	quality_level = clampi(level,0,2)
	bodies[2].get_node("Clouds").visible = quality_level > 0
	bodies[2].get_node("Atmosphere").visible = quality_level > 0
	sun_glow.visible = quality_level > 0
