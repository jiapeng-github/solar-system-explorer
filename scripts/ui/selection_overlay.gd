extends Control
var selected := false
var badge := ""
var circular := false
var comparison := false
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _draw() -> void:
	if circular and selected:
		var center := Vector2(size.x*.5,36.5)
		for i in range(3): draw_arc(center,32+i*2,0,TAU,64,Color(.3,.85,1,.3/(i+1)),2,true)
		draw_arc(center,32,0,TAU,64,Color("7ce5f7"),1.5,true)
	if not badge.is_empty():
		var center := Vector2(size.x-18,16)
		if comparison:
			var width := minf(size.x-12,112)
			var frame := Rect2((size.x-width)*.5,1,width,size.y-2)
			var outline := StyleBoxFlat.new()
			outline.bg_color = Color.TRANSPARENT
			outline.border_color = Color("f3cc75") if badge == "B" else Color("55e5ff")
			outline.set_border_width_all(2)
			outline.set_corner_radius_all(12)
			outline.draw(get_canvas_item(),frame)
			center = Vector2(frame.end.x-3,12)
		draw_circle(center,13,Color("f3cc75") if badge == "B" else Color("7ce5f7"))
		draw_string(get_theme_default_font(),center+Vector2(-7,6),badge,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("082432"))
func update_state(active: bool, text := "") -> void:
	selected = active
	badge = text
	queue_redraw()
