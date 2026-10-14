extends RefCounted
const ACCENT := Color("67e5fa")
static func box(color: Color, radius := 18, padding := 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	if color.a > 0:
		style.border_color = Color("365c78")
		style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style
static var button_texture: ImageTexture
static func primary() -> StyleBoxTexture:
	if button_texture == null:
		var image := Image.create(128,64,false,Image.FORMAT_RGBA8)
		for y in range(64):
			for x in range(128):
				var q := Vector2(absf(x-63.5)-45.5,absf(y-31.5)-13.5)
				var distance := Vector2(maxf(q.x,0),maxf(q.y,0)).length()+minf(maxf(q.x,q.y),0)-18
				var color := Color("41dff6").lerp(Color("9defff"),(x+y)/192.0)
				color.a = clampf(.5-distance,0,1)
				image.set_pixel(x,y,color)
		button_texture = ImageTexture.create_from_image(image)
	var style := StyleBoxTexture.new()
	style.texture = button_texture
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_texture_margin(side,18)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
