extends Control
static var nebula: ImageTexture
var rich := false
var stars: Array[Vector3] = []
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261008
	for i in range(2200):
		stars.append(Vector3(rng.randf(),rng.randf(),rng.randf()))
	if nebula == null:
		var field := FastNoiseLite.new()
		field.seed = 73
		field.frequency = .025
		field.fractal_octaves = 4
		var map := Image.create(512,320,false,Image.FORMAT_RGBA8)
		for y in range(320):
			for x in range(512):
				var band := exp(-pow((y-(240-x*.34))/47.0,2))
				var cloud := pow(maxf(0,field.get_noise_2d(x,y)+.35),2)*band
				map.set_pixel(x,y,Color(.12+cloud*.18,.22+cloud*.2,.38+cloud*.24,cloud*.42))
		nebula = ImageTexture.create_from_image(map)
	resized.connect(queue_redraw)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("050e1b"))
	var nebula_size := Vector2(maxf(size.x,size.y*1.6),maxf(size.y,size.x/1.6))
	draw_texture_rect(nebula,Rect2((size-nebula_size)*.5,nebula_size),false,Color(1.2,1.3,1.45,2.6) if rich else Color.WHITE)
	for i in range(stars.size() if rich else 650):
		var s := stars[i]
		var p := Vector2(s.x,s.y)*size
		var c := Color("b4d4f3")
		c.a = .12+s.z*.46
		draw_circle(p,.4+s.z*.75,c)
		if s.z > .986:
			draw_circle(p,3.2,Color(.35,.64,1,.04))
			draw_line(p-Vector2(3,0),p+Vector2(3,0),Color(.6,.78,1,.18),.6,true)
			draw_line(p-Vector2(0,3),p+Vector2(0,3),Color(.6,.78,1,.18),.6,true)
