extends VBoxContainer
signal lesson_requested(mode: String)
signal angle_changed(value: float)
signal play_requested
signal reset_requested
signal pause_requested
const Style = preload("res://scripts/ui/visual_style.gd")
const Sound = preload("res://scripts/ui_audio.gd")
var canvas
var slider: HSlider
var play_button: Button
var progress_label: Label
var percent: Label
var elapsed: Label
var callout: Label
var next_button: Button
var columns: BoxContainer
var heading_row: BoxContainer
var console_row: BoxContainer
var guide: VBoxContainer
var title: Label
var tabs: HBoxContainer
var completed := false
var current_angle := 0.0
var is_playing := false
func label(value: String, parent: Node, font_size := 17, color := Color("e5eefb"), wrap := true) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	if wrap: node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(node)
	return node
func button(value: String, parent: Node, action: Callable, active := false) -> Button:
	var node := Button.new()
	node.text = value
	node.custom_minimum_size.y = 44
	node.add_theme_font_size_override("font_size",17)
	for key in ["normal","hover","pressed","disabled"]:
		var skin := Style.box(Color("46dff4") if active else Color("061827b0"),12,10)
		skin.border_color = Color("6fdbec") if active else Color("4b7895")
		if key == "hover": skin.bg_color = skin.bg_color.lightened(.12)
		if key == "disabled": skin.bg_color = Color("15283b"); skin.border_color = Color("526b83")
		node.add_theme_stylebox_override(key,skin)
		node.add_theme_color_override("font_color" if key == "normal" else "font_"+key+"_color",Color("032034") if active else Color("eef6ff"))
	node.add_theme_color_override("font_disabled_color",Color("94abc3"))
	var focus := Style.box(Color.TRANSPARENT,12,0)
	focus.border_color = Color("80f0ff")
	focus.set_border_width_all(2)
	node.add_theme_stylebox_override("focus",focus)
	node.pressed.connect(action)
	parent.add_child(node)
	return node
func panel(parent: Node, padding := 16, color := Color("061522bd"), border := Color("416e8a")) -> VBoxContainer:
	var frame := PanelContainer.new()
	var skin := Style.box(color,15,padding)
	skin.border_color = border
	frame.add_theme_stylebox_override("panel",skin)
	parent.add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	frame.add_child(box)
	return box
func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",10)
	columns = BoxContainer.new()
	columns.add_theme_constant_override("separation",18)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(columns)
	var stage := VBoxContainer.new()
	stage.add_theme_constant_override("separation",12)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(stage)
	heading_row = BoxContainer.new()
	heading_row.add_theme_constant_override("separation",10)
	stage.add_child(heading_row)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation",1)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(titles)
	title = label("一年是怎样形成的？",titles,34)
	label("跟随地球绕太阳一圈，认识公转与一年。",titles,16,Color("afcbe3"))
	var segment := PanelContainer.new()
	segment.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	segment.add_theme_stylebox_override("panel",Style.box(Color("04121dcc"),13,3))
	heading_row.add_child(segment)
	tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation",0)
	segment.add_child(tabs)
	for entry in [["自转与昼夜","day"],["公转与一年","year"],["四季与地轴","seasons"]]:
		var mode: String = entry[1]
		var item := button(entry[0],tabs,func():
			if mode == "year": return
			Sound.play_from(self,"select")
			lesson_requested.emit(mode)
		,mode == "year")
		item.add_theme_font_size_override("font_size",15)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.custom_minimum_size.y = 38
		if mode != "year": item.add_theme_stylebox_override("normal",Style.box(Color.TRANSPARENT,10,8))
	canvas = preload("res://scripts/ui/year_canvas.gd").new()
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(canvas)
	var console := panel(stage,16)
	console_row = BoxContainer.new()
	console_row.add_theme_constant_override("separation",20)
	console.add_child(console_row)
	var timeline := VBoxContainer.new()
	timeline.add_theme_constant_override("separation",5)
	timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	console_row.add_child(timeline)
	progress_label = label("公转进度  0%",timeline,19,Color("60e6f5"))
	slider = HSlider.new()
	slider.accessibility_name = "公转进度"
	slider.min_value = 0
	slider.max_value = 360
	slider.step = .1
	slider.custom_minimum_size.y = 24
	var track := Style.box(Color("19374f"),4,0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	slider.add_theme_stylebox_override("slider",track)
	var fill := track.duplicate()
	fill.bg_color = Color("53def2")
	slider.add_theme_stylebox_override("grabber_area",fill)
	slider.add_theme_stylebox_override("grabber_area_highlight",fill)
	var knob := Image.new()
	knob.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="26" height="26"><circle cx="13" cy="13" r="13" fill="#49dfff" fill-opacity=".18"/><circle cx="13" cy="13" r="9" fill="#c6faff" stroke="#6eeaff" stroke-width="1.5"/></svg>')
	for key in ["grabber","grabber_highlight"]: slider.add_theme_icon_override(key,ImageTexture.create_from_image(knob))
	slider.value_changed.connect(func(value): pause_requested.emit(); angle_changed.emit(value))
	slider.drag_started.connect(func(): pause_requested.emit())
	timeline.add_child(slider)
	Sound.bind_slider(slider)
	var ticks := HBoxContainer.new()
	ticks.add_theme_constant_override("separation",0)
	timeline.add_child(ticks)
	for i in range(5):
		var value := i*90.0
		var tick := button(["起点","3个月","6个月","9个月","一年"][i],ticks,func():
			var changed := not is_equal_approx(current_angle,value)
			var was_completed := completed
			pause_requested.emit()
			angle_changed.emit(value)
			if not was_completed and completed: Sound.play_from(self,"complete")
			elif changed: Sound.play_from(self,"adjust")
		)
		tick.custom_minimum_size.y = 22
		tick.add_theme_font_size_override("font_size",13)
		tick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tick.size_flags_stretch_ratio = .5 if i in [0,4] else 1.0
		tick.alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_RIGHT if i == 4 else HORIZONTAL_ALIGNMENT_CENTER
		for key in ["normal","hover","pressed"]: tick.add_theme_stylebox_override(key,Style.box(Color.TRANSPARENT,5,0))
	label("拖动时间轴，观察地球的位置变化。",timeline,12,Color("abc4db"))
	var controls := HBoxContainer.new()
	controls.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	controls.add_theme_constant_override("separation",10)
	console_row.add_child(controls)
	play_button = button("▶ 播放公转",controls,func():
		Sound.play_from(self,"toggle_off" if is_playing else "toggle_on")
		play_requested.emit()
	,true)
	button("↻ 重置",controls,func():
		if is_playing or not is_zero_approx(current_angle): Sound.play_from(self,"reset")
		reset_requested.emit()
	)
	guide = panel(columns,18)
	guide.add_theme_constant_override("separation",6)
	label("实验 02 · 公转与一年",guide,16,Color("abc8e2"))
	label("绕太阳一圈，就是一年",guide,27)
	label("地球沿轨道持续运动，回到同一起点时，完成一次公转。",guide,16,Color("c0d7eb"))
	var metrics := HBoxContainer.new()
	metrics.add_theme_constant_override("separation",10)
	guide.add_child(metrics)
	for i in range(2):
		var card := panel(metrics,10,Color("061c2db0"))
		card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var number := label("",card,42,Color("62e6f5"),false)
		label("已完成公转" if i == 0 else "已用时间",card,16)
		if i == 0: percent = number
		else: elapsed = number
	var note := panel(guide,12,Color("00304770"),Color("30c7df"))
	callout = label("",note,15,Color("69e9f5"))
	guide.add_child(HSeparator.new())
	label("实验步骤",guide,15,Color("a8c8e1"))
	for i in range(3):
		var step := HBoxContainer.new()
		step.add_theme_constant_override("separation",10)
		guide.add_child(step)
		var number := label(str(i+1),step,17,Color("d5eaff"),false)
		number.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		number.custom_minimum_size = Vector2(29,29)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var ring := Style.box(Color("0b263980"),15,0)
		ring.border_color = Color("8bbcd5")
		number.add_theme_stylebox_override("normal",ring)
		label(["找到轨道上的起点","观察地球沿轨道前进","回到起点，完成一圈"][i],step,16)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	guide.add_child(gap)
	var fact := panel(guide,12,Color("27291940"),Color("d8b864"))
	var fact_row := HBoxContainer.new()
	fact.add_child(fact_row)
	var orbit_icon := TextureRect.new()
	var icon_image := Image.new()
	icon_image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="60" height="64"><ellipse cx="30" cy="32" rx="29" ry="16" transform="rotate(-35 30 32)" fill="none" stroke="#ffda76" stroke-width="1.5"/><circle cx="30" cy="32" r="7" fill="#ffda76"/><circle cx="49" cy="15" r="2.5" fill="#ffda76"/></svg>')
	orbit_icon.texture = ImageTexture.create_from_image(icon_image)
	orbit_icon.custom_minimum_size = Vector2(55,64)
	orbit_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	orbit_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fact_row.add_child(orbit_icon)
	var fact_words := VBoxContainer.new()
	fact_words.add_theme_constant_override("separation",2)
	fact_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fact_row.add_child(fact_words)
	label("约 365 天",fact_words,28,Color("ffdc77"))
	label("地球公转一圈的时间",fact_words,15)
	label("月份刻度为教学近似。",fact_words,12,Color("adc4da"))
	next_button = button("下一实验：四季与地轴 →",guide,func(): Sound.play_from(self,"navigate"); lesson_requested.emit("seasons"))
	next_button.add_theme_font_size_override("font_size",15)
	next_button.disabled = true
	label("圆形轨道教学模型 · 天体大小与距离为示意 · 不对应真实日期",self,12,Color("a4bdd3"))
	resized.connect(adapt)
	adapt()
func adapt() -> void:
	var compact := size.x < 900
	columns.vertical = compact
	guide.get_parent().custom_minimum_size.x = 0 if compact else clampf(size.x*.29,342,400)
	heading_row.vertical = size.x < 1100
	title.add_theme_font_size_override("font_size",26 if compact else 34)
	console_row.vertical = size.x < 1080
	for tab in tabs.get_children():
		tab.add_theme_font_size_override("font_size",13 if compact else 15)
		tab.custom_minimum_size.x = 0 if compact else 118
func update_state(angle: float, playing: bool, unlocked: bool) -> void:
	current_angle = angle
	is_playing = playing
	completed = unlocked
	canvas.angle = angle
	canvas.queue_redraw()
	slider.set_value_no_signal(angle)
	var value := floori(angle/3.6)
	percent.text = "%d%%" % value
	elapsed.text = "约 %d 天" % roundi(angle/360.0*365.26)
	elapsed.add_theme_font_size_override("font_size",28)
	progress_label.text = "公转进度  %d%%" % value
	callout.text = "ⓘ  现在，地球大约走过了四分之一圈。" if is_equal_approx(angle,90) else "ⓘ  现在，地球大约走过了二分之一圈。" if is_equal_approx(angle,180) else "ⓘ  现在，地球大约走过了四分之三圈。" if is_equal_approx(angle,270) else "✓  已回到起点，完成一次公转。" if angle >= 360 else "ⓘ  从起点出发，跟随地球沿轨道前进。" if angle == 0 else "ⓘ  地球持续前进，已公转约 %d°。" % floori(angle)
	play_button.text = "Ⅱ 暂停" if playing else "▶ 再看一圈" if angle >= 360 else "▶ 继续公转" if angle > 0 else "▶ 播放公转"
	next_button.disabled = not unlocked
	if not next_button.has_meta("unlocked") or next_button.get_meta("unlocked") != unlocked:
		next_button.set_meta("unlocked",unlocked)
		var lock_image := Image.new()
		lock_image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="18" height="20"><path d="M5 8V5a4 4 0 0 1 8 0v3" stroke="#94abc3" stroke-width="2" fill="none"/><rect x="2" y="8" width="14" height="11" rx="2" fill="#94abc3"/><circle cx="9" cy="13" r="1.5" fill="#15283b"/></svg>')
		next_button.icon = null if unlocked else ImageTexture.create_from_image(lock_image)
	next_button.tooltip_text = "完成一次公转后解锁" if not unlocked else "进入四季与地轴实验"
