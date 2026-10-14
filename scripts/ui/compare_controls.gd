extends RefCounted
# Nine-patch skins retain rounded ends and fine borders at every button width.
static var textures: Dictionary = {}
static func skin(kind: String, highlighted := false) -> StyleBoxTexture:
	var key := kind+str(highlighted)
	if not textures.has(key):
		var image := Image.create(128,48,false,Image.FORMAT_RGBA8)
		var radius := 22.0 if kind == "primary" or kind == "secondary" else 16.0
		for y in range(48):
			for x in range(128):
				var q := Vector2(absf(x-63.5)-(62-radius),absf(y-23.5)-(22-radius))
				var distance := Vector2(maxf(q.x,0),maxf(q.y,0)).length()+minf(maxf(q.x,q.y),0)-radius
				var t := float(y)/47
				var color: Color
				var border: Color
				if kind == "primary":
					color = Color("37dcef").lerp(Color("0aabf1"),t)
					border = Color("68eaff")
				elif kind == "active":
					color = Color("20617b").lerp(Color("0b243b"),t)
					color = color.lerp(Color("38c5e5"),.18*pow(absf(float(x)-63.5)/63.5,3))
					border = Color("42dff9")
				else:
					color = Color("102237").lerp(Color("071220"),t)
					border = Color("799ec4") if kind == "secondary" else Color("496e92")
				if highlighted: color = color.lightened(.15)
				color = color.lerp(border,clampf((distance+2.1)/1.5,0,1))
				color.a = clampf(.5-distance,0,1)
				image.set_pixel(x,y,color)
		textures[key] = ImageTexture.create_from_image(image)
	var style := StyleBoxTexture.new()
	style.texture = textures[key]
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_texture_margin(side,24 if side in [SIDE_LEFT,SIDE_RIGHT] else 20)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
static func button(control: Button, kind: String) -> void:
	for state in ["normal","hover","pressed","hover_pressed"]:
		control.add_theme_stylebox_override(state,skin(kind,state in ["hover","hover_pressed"]))
		control.add_theme_color_override("font_color" if state == "normal" else "font_"+state+"_color",Color("042234") if kind == "primary" else Color("ecf5ff"))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("70c9dd")
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(22)
	control.add_theme_stylebox_override("focus",focus)

static func popup(menu: PopupMenu) -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("0a192b")
	panel.border_color = Color("43627d")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(14)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: panel.set_content_margin(side,8)
	menu.add_theme_stylebox_override("panel",panel)
	menu.add_theme_stylebox_override("hover",skin("active"))
	menu.add_theme_color_override("font_color",Color("dce9f6"))
	menu.add_theme_color_override("font_hover_color",Color("ffffff"))
	menu.add_theme_color_override("font_accelerator_color",Color("91b5ce"))
	menu.add_theme_font_size_override("font_size",18)
	menu.add_theme_constant_override("v_separation",20)
	menu.add_theme_constant_override("h_separation",12)
	for state in ["radio_checked","radio_unchecked"]:
		var image := Image.new()
		var fill := "#67e5fa" if state == "radio_checked" else "none"
		image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18"><circle cx="9" cy="9" r="6" fill="'+fill+'" stroke="#67e5fa" stroke-width="1.5"/></svg>')
		menu.add_theme_icon_override(state,ImageTexture.create_from_image(image))

static func option(control: OptionButton) -> void:
	for state in ["normal","hover","pressed"]:
		control.add_theme_stylebox_override(state,skin("selector",state != "normal"))
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("70c9dd")
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(14)
	control.add_theme_stylebox_override("focus",focus)
	control.add_theme_font_size_override("font_size",17)
	control.add_theme_color_override("font_color",Color("e4edf8"))
	control.add_theme_color_override("font_pressed_color",Color("e4edf8"))
	var image := Image.new()
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14"><path d="M3 5 L7 9 L11 5" fill="none" stroke="#9cdafa" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>')
	control.add_theme_icon_override("arrow",ImageTexture.create_from_image(image))
	control.add_theme_constant_override("arrow_margin",12)
	popup(control.get_popup())
