extends SceneTree
func visible_rect(source: Image) -> Rect2i:
	var lo := source.get_size()
	var hi := Vector2i.ZERO
	for y in source.get_height():
		for x in source.get_width():
			if source.get_pixel(x,y).a >= .1:
				lo = lo.min(Vector2i(x,y))
				hi = hi.max(Vector2i(x,y))
	return Rect2i(lo,hi-lo+Vector2i.ONE)
func fitted(source: Image, canvas_size: int, content_size: int, use_visible_bounds := false) -> Image:
	var bounds := visible_rect(source).grow(2).intersection(Rect2i(Vector2i.ZERO,source.get_size())) if use_visible_bounds else source.get_used_rect()
	var content := source.get_region(bounds)
	var ratio := float(content_size)/maxi(content.get_width(),content.get_height())
	content.resize(roundi(content.get_width()*ratio),roundi(content.get_height()*ratio),Image.INTERPOLATE_LANCZOS)
	var result := Image.create(canvas_size,canvas_size,false,Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	result.blit_rect(content,Rect2i(Vector2i.ZERO,content.get_size()),(Vector2i(canvas_size,canvas_size)-content.get_size())/2)
	return result
func _initialize() -> void:
	var tile := Image.load_from_file("res://assets/ui/app-logo-v3-master.png")
	var mark := Image.load_from_file("res://assets/ui/brand-mark-v3-master.png")
	var icon := fitted(tile,1024,836,true)
	icon.save_png("res://assets/ui/app-logo-v3.png")
	fitted(mark,256,236).save_png("res://assets/ui/brand-mark-v3.png")
	fitted(mark,432,250).save_png("res://assets/ui/app-logo-adaptive-v3.png")
	var background := Image.create(432,432,false,Image.FORMAT_RGBA8)
	background.fill(Color("061827"))
	background.save_png("res://assets/ui/app-logo-background-v3.png")
	assert(icon.get_pixel(0,0).a == 0)
	assert(visible_rect(icon).size.x >= 830 and visible_rect(icon).size.x <= 834)
	print("PASS: transparent corners, 832px rounded silhouette in 1024px canvas")
	quit()
