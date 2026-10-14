extends Control
var world
var _clock := 0.0
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _process(delta: float) -> void:
	_clock += delta
	if _clock > .033:
		_clock = 0
		queue_redraw()
func _draw() -> void:
	if not is_instance_valid(world) or world.camera.follow_node != null: return
	var camera = world.camera
	var font := get_theme_default_font()
	var occupied: Array[Rect2] = []
	var sun: Vector2 = camera.unproject_position(Vector3.ZERO)
	var sun_edge: Vector2 = camera.unproject_position(camera.global_basis.x*7.0)
	var sun_radius := sun.distance_to(sun_edge)
	occupied.append(Rect2(sun-Vector2.ONE*(sun_radius+4),Vector2(sun_radius*2+55,sun_radius*2+8)))
	var points: Dictionary = {}
	for i in range(world.bodies.size()):
		var body = world.bodies[i]
		if not body.visible or camera.is_position_behind(body.global_position): continue
		var point: Vector2 = camera.unproject_position(body.global_position)
		if not Rect2(Vector2.ZERO,size).grow(-8).has_point(point): continue
		var edge: Vector2 = camera.unproject_position(body.global_position+camera.global_basis.x*world.catalog[i].display_radius*body.scale.x)
		var radius := point.distance_to(edge)
		points[i] = [point,radius]
		occupied.append(Rect2(point-Vector2.ONE*(radius+4),Vector2.ONE*(radius+4)*2))
	for i in points:
		var point: Vector2 = points[i][0]
		var radius: float = points[i][1]
		var color := Color("85eaff") if i == world.selected_index else Color("e4edf8")
		if i == world.selected_index: draw_arc(point,radius+5,0,TAU,64,color,1.5,true)
		var text: String = world.catalog[i].name
		var extent := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,18)+Vector2(6,6)
		var origin := point+Vector2(radius+13,-radius-15)
		for offset in [Vector2(radius+13,-radius-15),Vector2(-radius-extent.x-14,-radius-15),Vector2(radius+13,radius+12),Vector2(-radius-extent.x-14,radius+12),Vector2(-extent.x*.5,-radius-40)]:
			var candidate: Vector2 = point+offset
			candidate.x = clampf(candidate.x,4,maxf(4,size.x-extent.x-4))
			candidate.y = clampf(candidate.y,4,maxf(4,size.y-extent.y-4))
			var rect := Rect2(candidate,extent)
			var clear := true
			for other in occupied:
				if rect.intersects(other.grow(3)): clear = false
			origin = candidate
			if clear: break
		occupied.append(Rect2(origin,extent))
		var end := Vector2(origin.x-3 if origin.x > point.x else origin.x+extent.x+3,origin.y+extent.y*.5)
		var elbow := end+Vector2(-9 if origin.x > point.x else 9,0)
		var start := point+point.direction_to(elbow)*(radius+3)
		draw_polyline(PackedVector2Array([start,elbow,end]),color.darkened(.2),1,true)
		draw_circle(start,2,color)
		draw_string_outline(font,origin+Vector2(0,20),text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,3,Color("04101c"))
		draw_string(font,origin+Vector2(0,20),text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,color)
	if Rect2(Vector2.ZERO,size).has_point(sun):
		draw_string(font,sun+Vector2(sun_radius+9,5),"太阳",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f6dfa1"))
