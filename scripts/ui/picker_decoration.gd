extends Control
var slot := "A"
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _draw() -> void:
	var cy := size.y*.5
	draw_line(Vector2(39,5),Vector2(39,size.y-5),Color("344b65"),1,true)
	draw_string(get_theme_default_font(),Vector2(15,cy+7),slot,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("e4edf8"))
	var cx := size.x-23
	draw_colored_polygon(PackedVector2Array([Vector2(cx-6,cy-3),Vector2(cx+6,cy-3),Vector2(cx,cy+4)]),Color("9cdafa"))
