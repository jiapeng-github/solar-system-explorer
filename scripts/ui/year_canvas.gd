extends Control
const Style = preload("res://scripts/ui/visual_style.gd")
var angle := 0.0
var earth: ColorRect
var sun: ColorRect
var stars: Array[Vector3] = []
var cloud: ImageTexture
var orbit_center := Vector2.ZERO
var orbit_radius := Vector2.ZERO
var earth_center := Vector2.ZERO
func _ready() -> void:
	custom_minimum_size.y = 370
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20512
	for i in range(460): stars.append(Vector3(rng.randf(),rng.randf(),rng.randf()))
	var field := FastNoiseLite.new()
	field.seed = 18
	field.frequency = .032
	field.fractal_octaves = 5
	var map := Image.create(384,256,false,Image.FORMAT_RGBA8)
	for y in range(256):
		for x in range(384):
			var band := exp(-pow((y-(225-x*.42))/44.0,2))
			var n := maxf(0,field.get_noise_2d(x,y)+.40)
			map.set_pixel(x,y,Color(.10,.28,.49,n*n*band*.55))
	cloud = ImageTexture.create_from_image(map)
	sun = ColorRect.new()
	sun.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var solar := ShaderMaterial.new()
	solar.shader = preload("res://assets/shaders/year_sun.gdshader")
	sun.material = solar
	add_child(sun)
	earth = ColorRect.new()
	earth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var globe := ShaderMaterial.new()
	globe.shader = preload("res://assets/shaders/seasons_earth.gdshader")
	globe.set_shader_parameter("surface_map",preload("res://assets/textures/earth.png"))
	globe.set_shader_parameter("clouds",preload("res://assets/textures/clouds.jpg"))
	earth.material = globe
	add_child(earth)
func text(pos: Vector2, value: String, font_size := 16, color := Color("deebfa")) -> void:
	draw_string(get_theme_default_font(),pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
func point(a: float) -> Vector2:
	return orbit_center+Vector2(cos(a)*orbit_radius.x,-sin(a)*orbit_radius.y)
func _draw() -> void:
	if not is_instance_valid(earth): return
	var compact := size.x < 500
	draw_style_box(Style.box(Color("0614209c"),15,12),Rect2(Vector2.ZERO,size))
	draw_texture_rect(cloud,Rect2(Vector2(1,1),size-Vector2(2,2)),false)
	for star in stars:
		var p := Vector2(12,12)+Vector2(star.x,star.y)*(size-Vector2(24,24))
		draw_circle(p,.25+star.z*.65,Color(.65,.83,1,.1+star.z*.36))
	text(Vector2(20,31),"地球绕太阳公转",21,Color("5feafa"))
	text(Vector2(20,55),"从同一起点出发，再回到起点。",15,Color("a8bfd6"))
	if not compact:
		var pill := Rect2(size.x-245,14,227,30)
		draw_style_box(Style.box(Color("091f30b0"),14,4),pill)
		text(pill.position+Vector2(12,20),"同一颗地球 · 一次完整公转",14,Color("b8d4ed"))
	var plot_top := 114.0 if compact else 100.0
	var plot_bottom := size.y-80
	orbit_center = Vector2(size.x*.51,(plot_top+plot_bottom)*.5)
	orbit_radius = Vector2(size.x*(.29 if compact else .32),(plot_bottom-plot_top)*.5)
	var a := deg_to_rad(angle)
	# Projected circular orbit. The completed arc runs right -> top -> left -> bottom.
	for i in range(180):
		if i%3 == 2: continue
		draw_line(point(i*TAU/180),point((i+1)*TAU/180),Color("7c95b2"),1.4,true)
	if angle > 0:
		var points := PackedVector2Array()
		for i in range(121): points.append(point(a*i/120))
		draw_polyline(points,Color("42c7f02b"),7,true)
		draw_polyline(points,Color("64e9f8"),2.2,true)
	for i in range(12):
		var p := point(i*TAU/12)
		draw_circle(p,3.5 if i%3 else 4.5,Color("b3cde9"))
	var start := point(0)
	for i in range(12): draw_arc(start,14,i*TAU/12,(i+.65)*TAU/12,5,Color("e6f5ff"),1.8,true)
	var earth_r := 25.0 if compact else 32.0
	var solar_r := minf(58,size.y*.128)
	earth_center = point(a)
	for i in range(8,0,-1): draw_circle(earth_center,earth_r+i,Color(.1,.7,1,.025))
	draw_arc(earth_center,earth_r+2,0,TAU,64,Color("5ce8ff"),1.5,true)
	earth.position = earth_center-Vector2.ONE*earth_r
	earth.size = Vector2.ONE*earth_r*2
	earth.material.set_shader_parameter("phase",a-PI*.5)
	sun.position = orbit_center-Vector2.ONE*solar_r*1.9
	sun.size = Vector2.ONE*solar_r*3.8
	text(orbit_center+Vector2(-18,solar_r+27),"太阳",19,Color("ffe7ab"))
	if angle > 15:
		var arrow_a := a-minf(.18,a*.5)
		var tip := point(arrow_a)
		var direction := Vector2(-sin(arrow_a)*orbit_radius.x,-cos(arrow_a)*orbit_radius.y).normalized()
		var side := direction.orthogonal()
		draw_colored_polygon(PackedVector2Array([tip+direction*8,tip-direction*9+side*6,tip-direction*9-side*6]),Color("69edff"))
	var font_size := 12 if compact else 16
	text(point(PI*.5)+Vector2(-31,-earth_r-14),"约 3 个月",font_size)
	text(point(PI)+Vector2(-78 if not compact else -58,5),"约 6 个月",font_size)
	text(point(PI*1.5)+Vector2(-31,earth_r+24),"约 9 个月",font_size)
	if compact:
		text(start+Vector2(-24,-earth_r-15),"0 / 12个月",11)
		text(start+Vector2(-12,earth_r+19),"起点",11)
	else:
		text(start+Vector2(-15,-earth_r-24),"0 / 约 12 个月",15)
		text(start+Vector2(-15,-earth_r-5),"起点 / 一圈终点",14,Color("b0c5dc"))
	# At the bottom, keep the Earth label above the globe so it does not cover the 9-month tick.
	var label_pos := earth_center+Vector2(-54,earth_r+24)
	if sin(a) < -.4: label_pos = earth_center+Vector2(earth_r+12,5)
	if compact: label_pos.x = clampf(label_pos.x,12,size.x-112)
	text(label_pos,"地球 · 当前位置",12 if compact else 15)
	var status := "已走过 1/4 圈" if is_equal_approx(angle,90) else "已走过 1/2 圈" if is_equal_approx(angle,180) else "已走过 3/4 圈" if is_equal_approx(angle,270) else "已完成一圈" if angle >= 360 else "已完成公转 %d%%" % floori(angle/3.6)
	text(Vector2(20,size.y-19),status,18,Color("5feafa"))
