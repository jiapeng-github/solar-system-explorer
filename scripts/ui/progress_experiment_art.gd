extends Control
var mode := "day"
var earth: ColorRect
var sun: ColorRect
func _ready() -> void:
	custom_minimum_size = Vector2(94,86)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	earth = preload("res://scripts/planet_disc.gd").new()
	earth.configure("earth")
	if mode == "seasons":
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://assets/shaders/seasons_earth.gdshader")
		mat.set_shader_parameter("surface_map",preload("res://assets/textures/earth.png"))
		mat.set_shader_parameter("clouds",preload("res://assets/textures/clouds.jpg"))
		mat.set_shader_parameter("phase",PI*.5)
		earth.material = mat
	add_child(earth)
	if mode == "year":
		sun = ColorRect.new()
		sun.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://assets/shaders/year_sun.gdshader")
		sun.material = mat
		add_child(sun)
	resized.connect(queue_redraw)
func _draw() -> void:
	if not is_instance_valid(earth): return
	var center := size*.5
	if mode == "year":
		for i in range(32):
			if i%2: continue
			var a := i*TAU/32
			var b := (i+1)*TAU/32
			draw_line(center+Vector2(cos(a)*40,sin(a)*24),center+Vector2(cos(b)*40,sin(b)*24),Color("7aacc5"),1,true)
		sun.position = center-Vector2(23,23)
		sun.size = Vector2(46,46)
		earth.position = center+Vector2(18,-12)-Vector2(17,17)
		earth.size = Vector2(34,34)
	else:
		earth.position = center-Vector2(34,34)
		earth.size = Vector2(68,68)
		if mode == "seasons":
			var axis := Vector2(.4,-.916)
			draw_dashed_line(center-axis*43,center+axis*43,Color("cce9fa"),1.3,4)
			draw_arc(center,35,0,TAU,64,Color("287b9f"),1,true)
