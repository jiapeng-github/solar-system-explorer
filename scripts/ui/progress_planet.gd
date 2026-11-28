extends Button
const Style = preload("res://scripts/ui/visual_style.gd")
var planet_id := "earth"
var planet_name := "地球"
var visited := false
var recommended := false
var thumb: TextureRect
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = Vector2(76,127)
	tooltip_text = planet_name+" · "+("已探索" if visited else "待探索")
	accessibility_name = tooltip_text
	for key in ["normal","hover","pressed","focus"]:
		add_theme_stylebox_override(key,Style.box(Color.TRANSPARENT if key == "normal" else Color("12314980"),12,0))
	thumb = TextureRect.new()
	thumb.texture = load("res://assets/thumbnails/"+planet_id+".png")
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb.show_behind_parent = true
	add_child(thumb)
	resized.connect(queue_redraw)
func _draw() -> void:
	if not is_instance_valid(thumb): return
	var r := minf(39,(size.x-15)*.5)
	var center := Vector2(size.x*.5,45)
	thumb.position = center-Vector2.ONE*r*1.30
	thumb.size = Vector2.ONE*r*2.60
	if visited: draw_arc(center,r+4,0,TAU,64,Color("60eafa"),1.5,true)
	elif recommended:
		for i in range(16): draw_arc(center,r+4,i*TAU/16,(i+.55)*TAU/16,5,Color("60eafa"),1.4,true)
	if visited:
		var badge := center+Vector2(r*.8,r*.8)
		draw_circle(badge,10,Color("50e3f4"))
		draw_line(badge+Vector2(-4,0),badge+Vector2(-1,3),Color("052435"),2,true)
		draw_line(badge+Vector2(-1,3),badge+Vector2(5,-4),Color("052435"),2,true)
	var font := get_theme_default_font()
	var name_width := font.get_string_size(planet_name,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
	draw_string(font,Vector2((size.x-name_width)*.5,105),planet_name,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("edf5ff"))
	var status := "已探索" if visited else "下一站" if recommended else "待探索"
	var width := font.get_string_size(status,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
	draw_string(font,Vector2((size.x-width)*.5,122),status,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("63eafa") if visited or recommended else Color("b5c9df"))
