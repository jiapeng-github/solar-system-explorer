extends Control
var framed := true
var mode := "day"
var angle := 180.0
var catalog: Array = []
var first := 2
var second := 4
const INK := Color("dce7f6")
const MUTED := Color("9bafc7")
const ACCENT := Color("7ce5f7")
var discs: Array[ColorRect] = []

func _ready() -> void:
	custom_minimum_size = Vector2(0,290)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	for i in range(2):
		var disc := preload("res://scripts/planet_disc.gd").new()
		disc.configure("earth")
		add_child(disc)
		discs.append(disc)

func status() -> String:
	if mode == "year":
		return "已完成一圈的 %d%%" % roundi(angle/360*100)
	var facing := cos(deg_to_rad(angle))
	if absf(facing) < 0.02:
		return "观察点正在经过明暗交界"
	return "观察点正处于白天" if facing < 0 else "观察点正处于黑夜"

func _text(pos: Vector2, value: String, color := INK, font_size := 19) -> void:
	draw_string(get_theme_default_font(),pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
	if framed: draw_style_box(_background(),Rect2(Vector2.ZERO,size))
	for disc in discs: disc.visible = false
	if mode == "size":
		_draw_sizes()
		return
	if mode in ["rotation","period"]:
		_draw_periods()
		return
	if mode == "distance":
		_draw_distances()
		return
	var center := Vector2(size.x*0.60,size.y*0.48)
	var r := minf(size.x*0.24,size.y*0.33)
	if mode == "day":
		var sun := Vector2(-r*.12,center.y)
		for glow in range(8,0,-1): draw_circle(sun,r*(.66+glow*.035),Color(1,.65,.14,.012))
		if discs.size() > 1:
			discs[1].configure("sun")
			discs[1].position = sun-Vector2.ONE*r*.68
			discs[1].size = Vector2.ONE*r*1.36
			discs[1].visible = true
		for dy in [-0.5,0.0,0.5]:
			var start := Vector2(sun.x+r*.76,center.y+dy*r)
			var finish := Vector2(center.x-r*1.25,start.y)
			draw_line(start,finish,Color("a9884e"),2,true)
			draw_line(finish,finish+Vector2(-7,-4),Color("a9884e"),2,true)
			draw_line(finish,finish+Vector2(-7,4),Color("a9884e"),2,true)
		draw_circle(center,r,Color("153147"))
		var half := PackedVector2Array([center])
		for i in range(65):
			var theta := PI/2+float(i)/64*PI
			half.append(center+Vector2(cos(theta),sin(theta))*r)
		draw_colored_polygon(half,Color("59a9c7"))
		if not discs.is_empty():
			discs[0].configure("earth",true)
			discs[0].position = center-Vector2.ONE*r
			discs[0].size = Vector2.ONE*r*2
			discs[0].material.set_shader_parameter("rotation_angle",deg_to_rad(angle))
			discs[0].visible = true
		# Marker is outside the sphere so it remains visible over the textured disc.
		draw_arc(center,r*1.15,0,TAU,100,Color("31475f"),1,true)
		var marker := center+Vector2(cos(deg_to_rad(angle)),-sin(deg_to_rad(angle)))*r*1.12
		draw_circle(marker,8,ACCENT)
		draw_arc(marker,9,0,TAU,32,Color.WHITE,2,true)
		_text(marker+Vector2(-6,-16),"A",ACCENT,18)
		_text(Vector2(22,sun.y+r*.85),"太阳")
		_text(center+Vector2(-r*.8,r+30),"白天")
		_text(center+Vector2(r*.35,r+30),"黑夜")
		draw_arc(center,r*1.3,PI*1.15,PI*1.8,50,ACCENT,2,true)
		var arrow := center+Vector2(cos(PI*1.15),sin(PI*1.15))*r*1.3
		draw_line(arrow,arrow+Vector2(12,-2),ACCENT,2,true)
		draw_line(arrow,arrow+Vector2(1,-12),ACCENT,2,true)
		_text(Vector2(22,32),"北极视角 · 太阳光来自左侧",MUTED,17)
	else:
		center = size*Vector2(0.5,0.49)
		var orbit_r := minf(size.x*.30,size.y*.24)
		draw_arc(center,orbit_r,0,TAU,128,Color("415775"),2,true)
		# Equal segments illustrate elapsed months, not calendar positions.
		for month in range(12):
			var theta := month*TAU/12
			var direction := Vector2(cos(theta),-sin(theta))
			draw_line(center+direction*(orbit_r-5),center+direction*(orbit_r+5),MUTED,2,true)
			if month % 3 == 0:
				_text(center+direction*(orbit_r+30)+Vector2(-14,6),"起点" if month == 0 else "%d个月" % month,MUTED,15)
		if angle > 0:
			draw_arc(center,orbit_r,-deg_to_rad(angle),0,128,ACCENT,4,true)
		for theta in [0.6,2.7,4.8]:
			var point := center+Vector2(cos(theta),-sin(theta))*orbit_r
			var tangent := Vector2(-sin(theta),-cos(theta))
			draw_line(point,point-tangent*12+tangent.orthogonal()*6,ACCENT,2,true)
			draw_line(point,point-tangent*12-tangent.orthogonal()*6,ACCENT,2,true)
		draw_circle(center,24,Color("f5c77b"))
		var earth := center+Vector2(cos(deg_to_rad(angle)),-sin(deg_to_rad(angle)))*orbit_r
		draw_circle(earth,13,Color("6cb8d2"))
		if not discs.is_empty():
			discs[0].configure("earth")
			discs[0].position = earth-Vector2.ONE*15
			discs[0].size = Vector2.ONE*30
			discs[0].visible = true
		_text(earth+Vector2(-20,-22),"地球")
		_text(center+Vector2(-20,48),"太阳")
		_text(Vector2(22,32),"公转概念示意 · 不对应真实日期",MUTED,17)
	_text(Vector2(22,size.y-25),status(),ACCENT,21)

func comparison_radii() -> Vector2:
	if catalog.is_empty(): return Vector2.ZERO
	var largest: float = maxf(catalog[first].radius_km,catalog[second].radius_km)
	var max_radius := minf(size.x*.23,(size.y-92)*.5)
	return Vector2(catalog[first].radius_km,catalog[second].radius_km)/largest*max_radius

func _draw_sizes() -> void:
	if catalog.is_empty() or discs.is_empty(): return
	var radii := comparison_radii()
	var baseline := size.y-82
	draw_line(Vector2(20,baseline),Vector2(size.x-20,baseline),Color("35536a"),1,true)
	for i in range(2):
		var p: Dictionary = catalog[first if i == 0 else second]
		var x := size.x*(.26 if i == 0 else .74)
		var r: float = radii[i]
		discs[i].configure(p.id)
		discs[i].position = Vector2(x-r,baseline-r*2)
		discs[i].size = Vector2.ONE*r*2
		discs[i].visible = true
		draw_line(Vector2(x-r,baseline+12),Vector2(x+r,baseline+12),MUTED,1,true)
		for edge in [x-r,x+r]: draw_line(Vector2(edge,baseline+6),Vector2(edge,baseline+18),MUTED,1,true)
		var color := ACCENT if i == 0 else Color("f3cc75")
		if r < 25:
			draw_line(Vector2(x,baseline-r*2-3),Vector2(x+12,baseline-r*2-28),color,1,true)
			draw_line(Vector2(x+12,baseline-r*2-28),Vector2(x+48,baseline-r*2-28),color,1,true)
			_text(Vector2(x+16,baseline-r*2-34),p.name,INK,18)
		else:
			var label_x := minf(size.x-60,x+r*.72)
			var label_y := maxf(24,baseline-r*1.8)
			draw_line(Vector2(x+r*.64,baseline-r*1.7),Vector2(label_x,label_y),color,1,true)
			draw_line(Vector2(label_x,label_y),Vector2(label_x+42,label_y),color,1,true)
			_text(Vector2(label_x,label_y-6),p.name,color,18)
		_text(Vector2(x-86,baseline+42),"直径 "+_grouped(p.radius_km*2)+" km",MUTED,16)
	_text(Vector2(maxf(22,size.x*.5-85),size.y-6),"同一比例 · 平均直径",MUTED,15)

func _draw_distances() -> void:
	if catalog.is_empty():
		return
	var left := 93.0
	var width := size.x-left-95
	var step := (size.y-70)/8
	_text(Vector2(22,29),"轨道半长轴 · 同一距离比例（au）",MUTED,17)
	for i in range(8):
		var p: Dictionary = catalog[i]
		var y := 62+i*step
		_text(Vector2(18,y+6),p.name,INK,17)
		draw_line(Vector2(left,y),Vector2(left+width,y),Color("20364b"),1)
		var x: float = left+width*p.a_au/30.06992276
		draw_line(Vector2(left,y),Vector2(x,y),Color(p.color),3)
		draw_circle(Vector2(x,y),4,Color(p.color))
		_text(Vector2(x+9,y+6),"%.2f" % p.a_au,MUTED,16)

func _background() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("06132188")
	box.border_color = Color("29465c")
	box.set_border_width_all(1)
	box.corner_radius_top_left = 18
	box.corner_radius_top_right = 18
	box.corner_radius_bottom_left = 18
	box.corner_radius_bottom_right = 18
	return box

func period_values() -> Vector2:
	if mode == "rotation": return Vector2(absf(catalog[first].rotation_days),absf(catalog[second].rotation_days))
	return Vector2(catalog[first].period_years*365.25,catalog[second].period_years*365.25)

func _draw_periods() -> void:
	if catalog.is_empty(): return
	var values := period_values()
	var largest := maxf(values.x,values.y)
	_text(Vector2(22,32),"恒星自转周期 · 地球日" if mode == "rotation" else "恒星公转周期 · 地球日",MUTED,17)
	for i in range(2):
		var p: Dictionary = catalog[first if i == 0 else second]
		var y := size.y*(.34+i*.33)
		_text(Vector2(24,y-14),p.name+"  %.3f 天" % values[i],INK,20)
		draw_rect(Rect2(24,y,size.x-48,22),Color("20364b"))
		draw_rect(Rect2(24,y,(size.x-48)*values[i]/largest,22),ACCENT if i == 0 else Color("ecbd7b"))
	_text(Vector2(22,size.y-22),"线性比例 · 条越长，完成一圈越久",MUTED,16)

func _grouped(value: float) -> String:
	var digits := str(roundi(value))
	var result := ""
	for i in range(digits.length()):
		if i > 0 and (digits.length()-i)%3 == 0: result += ","
		result += digits[i]
	return result
