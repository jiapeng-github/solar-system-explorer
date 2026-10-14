extends Control
signal position_chosen(angle: float)
var angle := 90.0
var tilt := 23.4
var discs: Array[ColorRect] = []
var centers: Array[Vector2] = []
var radius := 30.0
const Style = preload("res://scripts/ui/visual_style.gd")
const Model = preload("res://scripts/seasons_model.gd")
func _ready() -> void:
	custom_minimum_size = Vector2(0,330)
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)
	for i in range(6):
		var disc := preload("res://scripts/planet_disc.gd").new()
		disc.configure("sun" if i == 4 else "earth")
		var mat := ShaderMaterial.new()
		if i == 4:
			mat.shader = preload("res://assets/shaders/seasons_sun.gdshader")
		else:
			mat.shader = preload("res://assets/shaders/seasons_earth.gdshader")
			mat.set_shader_parameter("surface_map",preload("res://assets/textures/earth.png"))
			mat.set_shader_parameter("clouds",preload("res://assets/textures/clouds.jpg"))
			mat.set_shader_parameter("phase",i*PI*.5)
		disc.material = mat
		add_child(disc)
		discs.append(disc)
func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		for i in range(centers.size()):
			if centers[i].distance_to(event.position) < maxf(radius+8,24):
				position_chosen.emit(i*90.0)
				accept_event()
				break
func text(point: Vector2, value: String, font_size := 16, color := Color("dce7f6")) -> void:
	draw_string(get_theme_default_font(),point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func glow(pos: Vector2, r: float, color: Color) -> void:
	for i in range(8,0,-1):
		var tint := color
		tint.a = .025+float(8-i)*.008
		draw_circle(pos,r+i*1.4,tint)
func axis_at(pos: Vector2, axis: Vector2) -> void:
	draw_line(pos-axis*(radius+10),pos+axis*(radius+14),Color("d6eeff"),1.7,true)
	text(pos+axis*(radius+20)+Vector2(2,2),"N",12)
	text(pos-axis*(radius+18)+Vector2(-9,3),"S",12)
func _draw() -> void:
	draw_style_box(Style.box(Color("05142270"),16,10),Rect2(Vector2.ZERO,size))
	if discs.is_empty(): return
	var compact := size.x < 500
	text(Vector2(18,29),"一年中的四个位置",21)
	text(Vector2(18,49),"同一颗地球在不同时间的位置。",13,Color("9bafc7"))
	if not compact:
		var pill := Rect2(size.x-224,14,210,30)
		var skin := Style.box(Color("002231bb"),10,4)
		skin.border_color = Color("23bace")
		draw_style_box(skin,pill)
		text(pill.position+Vector2(11,20),"地轴方向在一年中近似不变",13,Color("69edfb"))
	var inset_height := 84.0 if not compact else 71.0
	var center := Vector2(size.x*.51,(size.y-inset_height)*.53+9)
	var rx := size.x*.325
	var ry := (size.y-inset_height-140)*.5
	radius = minf(35,maxf(24,(size.y-inset_height)*.115))
	if compact: radius = 24; rx = size.x*.31
	centers.clear()
	for i in range(160):
		if i%2 == 1: continue
		var a := i*TAU/160
		var b := (i+1)*TAU/160
		draw_line(center+Vector2(-sin(a)*rx,-cos(a)*ry),center+Vector2(-sin(b)*rx,-cos(b)*ry),Color("49789b"),1.0,true)
	var axis := Vector2(sin(deg_to_rad(tilt)),-cos(deg_to_rad(tilt))*.866).normalized()
	var selected := roundi(angle/90)%4
	var exact := absf(angle-roundf(angle/90)*90) < .5
	for i in range(4):
		var pos := center+Vector2(-sin(i*PI*.5)*rx,-cos(i*PI*.5)*ry)
		centers.append(pos)
		discs[i].position = pos-Vector2.ONE*radius
		discs[i].size = Vector2.ONE*radius*2
		discs[i].material.set_shader_parameter("tilt",deg_to_rad(tilt))
		axis_at(pos,axis)
		var label_pos := pos+Vector2(radius+11,4)
		if i == 1: label_pos = pos+Vector2(-radius-79,5)
		if compact: label_pos = pos+Vector2(-30,radius+31) if i in [1,3] else pos+Vector2(radius+8,3)
		text(label_pos,Model.NAMES[i],14,Color("58ecfb") if selected == i and exact else Color("e0ecfb"))
		if selected == i and exact:
			glow(pos,radius+3,Color("26bfff"))
			draw_arc(pos,radius+4,0,TAU,64,Color("6aeaff"),2,true)
	# The dashed reference and tilt arc use the same projected axis as the globes.
	var selected_pos: Vector2 = centers[selected]
	if exact and not compact:
		var pivot := selected_pos-axis*(radius*.15)
		var reference_end := pivot+Vector2(0,-radius-47)
		draw_dashed_line(pivot,reference_end,Color("a4c1db"),1,4)
		if tilt > 0:
			draw_arc(pivot,radius+21,-PI*.5,axis.angle(),24,Color("52e9f8"),1.3,true)
		text(reference_end+Vector2(8,9),"%.1f°" % tilt,15,Color("58edff"))
	var a := deg_to_rad(angle)
	var marker := center+Vector2(-sin(a)*rx,-cos(a)*ry)
	discs[5].visible = not exact
	if not exact:
		discs[5].position = marker-Vector2.ONE*radius
		discs[5].size = Vector2.ONE*radius*2
		discs[5].material.set_shader_parameter("phase",a)
		discs[5].material.set_shader_parameter("tilt",deg_to_rad(tilt))
		glow(marker,radius+3,Color("26bfff"))
		draw_arc(marker,radius+4,0,TAU,64,Color("60e7ff"),2,true)
		axis_at(marker,axis)
	var direction := center.direction_to(marker)
	var perpendicular := direction.orthogonal()
	for k in [-1,0,1]:
		var start: Vector2 = center+direction*(radius+12)+perpendicular*k*12
		var finish: Vector2 = marker-direction*(radius+13)+perpendicular*k*12
		draw_line(start,finish,Color("fac84b33"),6,true)
		draw_line(start,finish,Color("ffda66"),1.6,true)
		draw_colored_polygon(PackedVector2Array([finish,finish-direction*8+perpendicular*4,finish-direction*8-perpendicular*4]),Color("ffdf78"))
	discs[4].position = center-Vector2.ONE*radius*1.9
	discs[4].size = Vector2.ONE*radius*3.8
	text(center+Vector2(radius+12,18),"太阳",15,Color("ffebad"))
	var inset := Rect2(12,size.y-inset_height-7,size.x-24,inset_height)
	draw_style_box(Style.box(Color("041524bb"),12,8),inset)
	draw_line(Vector2(size.x*.5,inset.position.y+14),Vector2(size.x*.5,size.y-21),Color("30506b"),1,true)
	for i in range(2):
		var x := 26.0+i*(size.x-24)*.5
		var top := inset.position.y
		text(Vector2(x,top+22),"直射：能量更集中" if i == 0 else "斜射：能量更分散",13,Color("ffdb63"))
		for k in range(3):
			var y := top+36+k*12
			var finish := Vector2(x+79+(12-k*12 if i == 1 else 0),y)
			draw_line(Vector2(x+7,y),finish,Color("ffdb66"),1.6,true)
			draw_line(finish,finish+Vector2(-5,-3),Color("ffdb66"),1.6,true)
		draw_line(Vector2(x+79+(18 if i else 0),top+30),Vector2(x+79+(-18 if i else 0),top+66),Color("ffdb66"),3,true)
		if not compact:
			text(Vector2(x+112,top+41),"阳光更集中，" if i == 0 else "阳光更分散，",12,Color("c3d8ed"))
			text(Vector2(x+112,top+58),"单位面积接收能量更多。" if i == 0 else "单位面积接收能量更少。",12,Color("c3d8ed"))
