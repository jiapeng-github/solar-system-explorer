extends HSlider
var orbital := false
func _ready() -> void:
	resized.connect(queue_redraw)
func _draw() -> void:
	var captions := ["0%","50%","100%"] if orbital else ["0°","180°","360°"]
	for i in range(3):
		var x := (size.x-36)*i*.5
		draw_string(get_theme_default_font(),Vector2(x,size.y-1),captions[i],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("9cafc7"))
