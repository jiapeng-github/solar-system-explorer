extends Control
var kind := 0
var discs: Array[ColorRect] = []
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	for id in (["earth","moon","mars"] if kind == 0 else ["earth"] if kind == 1 else ["jupiter","earth"]):
		var disc := preload("res://scripts/planet_disc.gd").new()
		disc.configure(id)
		if id == "earth":
			disc.material.shader = preload("res://assets/shaders/home_planet.gdshader")
			disc.material.set_shader_parameter("surface_map",preload("res://assets/textures/earth.png"))
			disc.material.set_shader_parameter("clouds",preload("res://assets/textures/clouds.jpg"))
			disc.material.set_shader_parameter("earth",true)
			disc.material.set_shader_parameter("rotation_angle",1.5)
		add_child(disc)
		discs.append(disc)
	resized.connect(queue_redraw)
func place(index: int, center: Vector2, radius: float) -> void:
	discs[index].position = center-Vector2.ONE*radius
	discs[index].size = Vector2.ONE*radius*2
func _draw() -> void:
	if discs.is_empty(): return
	var r := minf(size.y*.45,size.x*.50)
	if kind == 0:
		var p := Vector2(size.x*.45,size.y*.57)
		for i in range(6,0,-1): draw_circle(p,r+i,Color(.08,.48,.94,.025))
		place(0,p,r)
		place(1,Vector2(size.x*.84,size.y*.18),r*.13)
		place(2,Vector2(size.x*.91,size.y*.83),r*.25)
	elif kind == 1:
		var p := Vector2(size.x*.48,size.y*.60)
		place(0,p,r*.87)
		var axis := Vector2(.4,-.916)
		draw_dashed_line(p-axis*(r+19),p+axis*(r+19),Color("cde9fa"),1.2,5)
		var light := Vector2(0,size.y*.24)
		for i in range(25,0,-1): draw_circle(light,14+i,Color(1,.75,.26,.014))
		draw_circle(light,14,Color("ffdf78"))
	else:
		place(0,Vector2(size.x*.40,size.y*.49),r)
		place(1,Vector2(size.x*.86,size.y*.78),r*.39)
