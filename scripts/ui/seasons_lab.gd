extends VBoxContainer
signal lesson_requested(mode: String)
const Model = preload("res://scripts/seasons_model.gd")
const Sound = preload("res://scripts/ui_audio.gd")
const Style = preload("res://scripts/ui/visual_style.gd")
const Controls = preload("res://scripts/ui/compare_controls.gd")
var store
var state: Dictionary
var playing := false
var _playback_from_user := false
var _foreground := true
var _activity = preload("res://scripts/app_activity.gd").new()
var _slider_completed_before := false
var _slider_dragging := false
var canvas
var slider: HSlider
var play_button: Button
var current: Label
var guide: VBoxContainer
var columns: BoxContainer
var slider_margin: MarginContainer
var daylight: Label
var altitude: Label
var metrics: Label
var heading: Label
var opposite: Label
var feedback: Label
var hemi_buttons: Array[Button] = []
var tilt_buttons: Array[Button] = []
var step_buttons: Array[Button] = []
var season_badge: Label
var explanation: Label
var day_value: Label
var altitude_value: Label
var observation: Label
var console_columns: BoxContainer
var page_title: Label
var tabs: HBoxContainer
func spacer(parent: Node, height := 0, expand := false) -> void:
	var node := Control.new()
	node.custom_minimum_size.y = height
	if expand: node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(node)
func segment(parent: Node) -> HBoxContainer:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel",Style.box(Color("061421"),14,2))
	parent.add_child(frame)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",0)
	frame.add_child(row)
	return row
func segment_style(node: Button, selected: bool) -> void:
	Controls.button(node,"primary" if selected else "selector")
	if selected:
		for key in ["normal","hover","pressed"]:
			var selected_skin := Style.box(Color("44d9f2") if key == "normal" else Color("76ecfa"),11,6)
			selected_skin.border_color = Color("72efff")
			node.add_theme_stylebox_override(key,selected_skin)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not selected:
		node.add_theme_stylebox_override("normal",Style.box(Color.TRANSPARENT,12,6))
func sun_icon(parent: Node) -> void:
	var icon := TextureRect.new()
	var image := Image.new()
	image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="42" height="42"><g stroke="#ffda5d" stroke-width="2"><path d="M21 1v5m0 30v5M1 21h5m30 0h5M7 7l4 4m20 20l4 4M7 35l4-4m20-20l4-4"/><circle cx="21" cy="21" r="10" fill="#ffda5d"/></g></svg>')
	icon.texture = ImageTexture.create_from_image(image)
	icon.custom_minimum_size = Vector2(34,34)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(icon)
func label(value: String, parent: Node, font_size := 17) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_size_override("font_size",font_size)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(node)
	return node
func button(value: String, parent: Node, action: Callable, kind := "selector") -> Button:
	var node := Button.new()
	node.text = value
	node.custom_minimum_size.y = 40
	node.add_theme_font_size_override("font_size",16)
	Controls.button(node,kind)
	if kind == "primary":
		for key in ["normal","hover","pressed"]:
			var primary_skin := Style.box(Color("37d7f2") if key == "normal" else Color("71ebfa"),24,8)
			primary_skin.border_color = Color("73edff")
			node.add_theme_stylebox_override(key,primary_skin)
	node.pressed.connect(action)
	parent.add_child(node)
	return node
func panel(parent: Node) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel",Style.box(Color("081827dd"),18,12))
	parent.add_child(frame)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",5)
	frame.add_child(content)
	return content
func _ready() -> void:
	state = Model.normalized(store.data.get("seasons",{}))
	add_theme_constant_override("separation",8)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns = BoxContainer.new()
	columns.add_theme_constant_override("separation",14)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(columns)
	var stage := VBoxContainer.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_theme_constant_override("separation",8)
	columns.add_child(stage)
	page_title = label("地球为什么会有四季？",stage,36)
	label("地轴倾斜，让一年中的日照发生变化。",stage,18)
	tabs = segment(stage)
	tabs.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for entry in [["自转与昼夜","day"],["公转与一年","year"],["四季与地轴","seasons"]]:
		var mode: String = entry[1]
		var tab := button(entry[0],tabs,func():
			if mode == "seasons": return
			Sound.play_from(self,"select")
			lesson_requested.emit(mode)
		)
		tab.custom_minimum_size = Vector2(146,32)
		segment_style(tab,mode == "seasons")
	canvas = preload("res://scripts/ui/seasons_canvas.gd").new()
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.position_chosen.connect(func(value): set_angle(value,true,true))
	stage.add_child(canvas)
	var console := panel(stage)
	console_columns = BoxContainer.new()
	console_columns.add_theme_constant_override("separation",16)
	console.add_child(console_columns)
	var timeline := VBoxContainer.new()
	timeline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	timeline.add_theme_constant_override("separation",0)
	console_columns.add_child(timeline)
	current = label("",timeline,18)
	current.add_theme_color_override("font_color",Color("60eaff"))
	slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 360
	slider.step = .1
	slider.custom_minimum_size.y = 28
	slider.value_changed.connect(func(value): set_angle(value,true))
	slider.drag_started.connect(func():
		_slider_dragging = true
		_slider_completed_before = store.data.lessons.has("seasons")
		set_playing(false)
	)
	slider.drag_ended.connect(func(changed: bool):
		_slider_dragging = false
		if changed:
			save()
			_finish_user_action(_slider_completed_before,"")
	)
	slider.gui_input.connect(_slider_key_input)
	var track := Style.box(Color("304c6c"),3,0)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	slider.add_theme_stylebox_override("slider",track)
	var fill := track.duplicate()
	fill.bg_color = Color("51dff3")
	slider.add_theme_stylebox_override("grabber_area",fill)
	slider.add_theme_stylebox_override("grabber_area_highlight",fill)
	var knob := Image.new()
	knob.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28"><circle cx="14" cy="14" r="13" fill="#37ceff" fill-opacity=".2"/><circle cx="14" cy="14" r="10" fill="#eefcff" stroke="#54e4ff" stroke-width="2"/></svg>')
	for key in ["grabber","grabber_highlight"]: slider.add_theme_icon_override(key,ImageTexture.create_from_image(knob))
	slider_margin = MarginContainer.new()
	timeline.add_child(slider_margin)
	slider_margin.add_child(slider)
	Sound.bind_slider(slider)
	slider_margin.resized.connect(adapt)
	var nodes := HBoxContainer.new()
	nodes.add_theme_constant_override("separation",0)
	timeline.add_child(nodes)
	for i in range(5):
		var value := i*90.0
		var item := button(["3月","6月","9月","12月","次年3月"][i],nodes,func(): set_angle(value,true,true,"adjust"))
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.add_theme_font_size_override("font_size",12)
		item.custom_minimum_size = Vector2(44,24)
		for side in ["normal","hover","pressed"]:
			item.add_theme_stylebox_override(side,Style.box(Color.TRANSPARENT,8,1))
	var playback := VBoxContainer.new()
	console_columns.add_child(playback)
	var actions := HBoxContainer.new()
	playback.add_child(actions)
	play_button = button("▶ 播放一年",actions,func(): set_playing(not playing,true),"primary")
	button("↻ 重置",actions,func(): reset(true),"secondary")
	label("拖动时间轴，比较四个位置。",playback,13)
	guide = panel(columns)
	guide.add_theme_constant_override("separation",8)
	build_guide()
	var foot := label("圆形轨道教学模型 · 大小与距离为示意 · 不对应具体年份 · 来源：NASA Space Place",self,12)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_color_override("font_color",Color("99b0ca"))
	resized.connect(adapt)
	adapt()
	observe()
	update_display()
func adapt() -> void:
	var narrow := size.x < 900
	columns.vertical = narrow
	guide.get_parent().custom_minimum_size.x = 0 if narrow else clampf(size.x*.30,350,410)
	console_columns.vertical = size.x < 1100
	page_title.add_theme_font_size_override("font_size",26 if narrow else 36)
	for tab in tabs.get_children():
		tab.custom_minimum_size.x = 98 if narrow else 146
		tab.add_theme_font_size_override("font_size",13 if narrow else 16)
	if is_instance_valid(slider_margin):
		var inset := maxi(0,roundi(slider_margin.size.x/10)-14)
		slider_margin.add_theme_constant_override("margin_left",inset)
		slider_margin.add_theme_constant_override("margin_right",inset)
func build_guide() -> void:
	for child in guide.get_children():
		guide.remove_child(child)
		child.queue_free()
	hemi_buttons.clear()
	tilt_buttons.clear()
	step_buttons.clear()
	metrics = null
	heading = null
	opposite = null
	label("实验 03 · 四季与地轴",guide,17).add_theme_color_override("font_color",Color("adcbea"))
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation",0)
	guide.add_child(steps)
	for i in range(3):
		var index := i
		var step := button(["观察","对照","验证"][i],steps,func(): set_step(index,true))
		var number_path: String = ["M13 12l5-4v18", "M11 12c0-8 16-6 11 2l-11 12h13", "M11 9h13l-8 8c12-4 11 13-5 8"][i]
		var ink := "#58eaff" if state.step == i else "#8baace"
		var icon_image := Image.new()
		icon_image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="36" height="36"><circle cx="18" cy="18" r="16" fill="#071e30" stroke="'+ink+'" stroke-width="1.5"/><path d="'+number_path+'" fill="none" stroke="'+ink+'" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>')
		step.icon = ImageTexture.create_from_image(icon_image)
		step.add_theme_constant_override("h_separation",8)
		step.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		step.add_theme_font_size_override("font_size",18)
		step.add_theme_stylebox_override("normal",Style.box(Color.TRANSPARENT,8,3))
		step.add_theme_color_override("font_color",Color("58eaff") if state.step == i else Color("a7bfdc"))
		step_buttons.append(step)
		if i < 2:
			var connector := ColorRect.new()
			connector.color = Color("345977")
			connector.custom_minimum_size = Vector2(10,1)
			connector.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
			steps.add_child(connector)
	if state.step < 2:
		var hemispheres := segment(guide)
		for i in range(2):
			var south := i == 1
			hemi_buttons.append(button("南半球" if south else "北半球",hemispheres,func(): set_south(south,true)))
		metrics = label("",guide,16)
		metrics.add_theme_color_override("font_color",Color("aec7e3"))
		var title_row := HBoxContainer.new()
		guide.add_child(title_row)
		heading = label("",title_row,30)
		heading.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		heading.autowrap_mode = TextServer.AUTOWRAP_OFF
		season_badge = label("",title_row,17)
		season_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		season_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		season_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		season_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		season_badge.custom_minimum_size = Vector2(66,32)
		season_badge.add_theme_stylebox_override("normal",Style.box(Color("ffc650"),16,4))
		season_badge.add_theme_color_override("font_color",Color("322100"))
		observation = label("",guide,16)
		var metric_row := HBoxContainer.new()
		metric_row.add_theme_constant_override("separation",10)
		guide.add_child(metric_row)
		for i in range(2):
			var card := panel(metric_row)
			card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation",9)
			card.add_child(row)
			sun_icon(row)
			var values := VBoxContainer.new()
			values.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			values.add_theme_constant_override("separation",0)
			row.add_child(values)
			label("白昼时间" if i == 0 else "正午太阳",values,14)
			var quality := label("",values,24)
			quality.autowrap_mode = TextServer.AUTOWRAP_OFF
			quality.add_theme_color_override("font_color",Color("56e8f5"))
			var numeric := label("",card,13)
			numeric.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			numeric.add_theme_color_override("font_color",Color("a5bed6"))
			if i == 0: daylight = quality; day_value = numeric
			else: altitude = quality; altitude_value = numeric
		explanation = label("",guide,16)
		var callout := panel(guide)
		var callout_skin := Style.box(Color("032434aa"),12,12)
		callout_skin.border_color = Color("49dfee")
		callout.get_parent().add_theme_stylebox_override("panel",callout_skin)
		opposite = label("",callout,16)
		opposite.add_theme_color_override("font_color",Color("7eeaf9"))
		spacer(guide,0,true)
		var line := HSeparator.new()
		guide.add_child(line)
		var tilt_row := HBoxContainer.new()
		guide.add_child(tilt_row)
		var tilt_label := label("地轴倾角",tilt_row,16)
		tilt_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		tilt_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		var tilts := segment(tilt_row)
		tilts.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for i in range(2):
			var tilt := 23.4 if i == 0 else 0.0
			tilt_buttons.append(button("约 23.4°" if i == 0 else "0° 对照",tilts,func(): set_tilt(tilt,true)))
		var next := button("试试地轴不倾斜 →" if state.step == 0 else "进入验证 →",guide,func(): set_tilt(0.0,true) if state.step == 0 else set_step(2,true),"primary")
		next.custom_minimum_size.y = 48
	else:
		spacer(guide,12)
		label("四季变化的主要原因？",guide,26)
		label("回顾观察与对照，选择你的发现。",guide,16)
		var answers := ["地轴倾斜，并随公转改变日照","夏天总是更靠近太阳","太阳每年忽冷忽热"]
		for i in range(3):
			var index := i
			var option := button(answers[i],guide,func(): answer(index,true),"active" if state.answer == i else "selector")
			option.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			preload("res://scripts/ui/quiz_style.gd").option(option,i,state.answer == i,i == 0)
		spacer(guide,0,true)
		button("回到观察",guide,func(): set_step(0,true))
	feedback = label("",guide,12)
	feedback.add_theme_color_override("font_color",Color("9ab9cf"))
# User feedback lives at accepted action boundaries. Restore and redraw stay silent.
func _finish_user_action(was_complete: bool, cue: String) -> void:
	if not _foreground: return
	if not was_complete and store.data.lessons.has("seasons"):
		Sound.play_from(self,"complete")
	elif not cue.is_empty():
		Sound.play_from(self,cue)
func _slider_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed: return
	for action in ["ui_left","ui_right","ui_up","ui_down","ui_home","ui_end"]:
		if event.is_action_pressed(action,true):
			_finish_slider_key.call_deferred(slider.value,store.data.lessons.has("seasons"))
			return
func _finish_slider_key(before: float, was_complete: bool) -> void:
	if is_instance_valid(slider) and not is_equal_approx(slider.value,before):
		_finish_user_action(was_complete,"")
func set_step(value: int, user := false) -> void:
	var changed: bool = state.step != value
	if user and not changed: return
	var was_complete: bool = store.data.lessons.has("seasons")
	var cue := "back" if state.step == 2 and value == 0 else "select"
	set_playing(false)
	state.step = value
	build_guide()
	update_display()
	save()
	if user and changed: _finish_user_action(was_complete,cue)
func set_south(value: bool, user := false) -> void:
	var changed: bool = state.south != value
	if user and not changed: return
	var was_complete: bool = store.data.lessons.has("seasons")
	state.south = value
	update_display()
	save()
	if user and changed: _finish_user_action(was_complete,"select")
func set_tilt(value: float, user := false) -> void:
	var changed: bool = not is_equal_approx(state.tilt,value) or (value == 0 and (state.step != 1 or not state.contrast))
	if user and not changed: return
	var was_complete: bool = store.data.lessons.has("seasons")
	set_playing(false)
	state.tilt = value
	if value == 0:
		state.contrast = true
		state.step = 1
	build_guide()
	observe()
	update_display()
	save()
	if user and changed: _finish_user_action(was_complete,"select")
func answer(value: int, user := false) -> void:
	var changed: bool = state.answer != value
	if user and not changed: return
	var was_complete: bool = store.data.lessons.has("seasons")
	state.answer = value
	build_guide()
	update_display()
	save()
	if user and changed: _finish_user_action(was_complete,"correct" if value == 0 else "retry")
func set_angle(value: float, manual := false, user := false, cue := "select") -> void:
	if manual: set_playing(false)
	var before: float = state.angle
	var was_complete: bool = store.data.lessons.has("seasons")
	state.angle = clampf(value,0,360)
	# Playback visits crossed landmarks, even if a slow frame skips the exact angle.
	if playing and state.tilt > 0:
		for i in range(5):
			if before <= i*90 and state.angle >= i*90 and not state.visited.has(i%4): state.visited.append(i%4); save()
	observe()
	update_display()
	if manual: save()
	if user and not is_equal_approx(before,state.angle): _finish_user_action(was_complete,cue)
func observe() -> void:
	if state.tilt == 0: return
	var index := roundi(float(state.angle)/90)%4
	if absf(float(state.angle)-roundf(float(state.angle)/90)*90) < 1 and not state.visited.has(index):
		state.visited.append(index)
		save()
func set_playing(value: bool, user := false) -> void:
	var changed := playing != value
	var was_complete: bool = store.data.lessons.has("seasons")
	playing = value
	_playback_from_user = value and user and _foreground
	if value and state.angle >= 360: set_angle(0)
	if is_instance_valid(play_button): play_button.text = "Ⅱ 暂停" if playing else "▶ 播放一年"
	if user and changed: _finish_user_action(was_complete,"toggle_on" if playing else "toggle_off")
func reset(user := false) -> void:
	var changed: bool = playing or not is_equal_approx(state.angle,90.0) or state.south or not is_equal_approx(state.tilt,23.4) or state.step != 0 or state.answer != -1
	var was_complete: bool = store.data.lessons.has("seasons")
	set_playing(false)
	state.angle = 90.0
	state.south = false
	state.tilt = 23.4
	state.step = 0
	state.answer = -1
	build_guide()
	observe()
	update_display()
	save()
	if user and changed: _finish_user_action(was_complete,"reset")
func update_display() -> void:
	canvas.angle = state.angle
	canvas.tilt = state.tilt
	canvas.queue_redraw()
	slider.set_value_no_signal(state.angle)
	var index := int(floor(float(state.angle)/90))%4
	var exact := absf(float(state.angle)-roundf(float(state.angle)/90)*90) < .5
	var position_name: String = Model.NAMES[roundi(float(state.angle)/90)%4] if exact else Model.NAMES[index]+"之后"
	current.text = "当前："+position_name
	if is_instance_valid(metrics):
		var result := Model.sunlight(state.angle,-40 if state.south else 40,state.tilt)
		var seasons := ["春季","夏季","秋季","冬季"]
		var season: String = seasons[(index+(2 if state.south else 0))%4]
		heading.text = "地轴不倾斜" if state.tilt == 0 else position_name
		heading.add_theme_font_size_override("font_size",24 if position_name.length() > 5 else 30)
		season_badge.text = "对照" if state.tilt == 0 else season
		var summer: bool = result.hours > 12.1
		var winter: bool = result.hours < 11.9
		observation.text = "地轴直立，全年日照指标不变。" if state.tilt == 0 else (("南半球" if state.south else "北半球")+("朝向太阳倾斜。" if summer else "背向太阳倾斜。" if winter else "与另一半球日照大致相当。"))
		daylight.text = "更长" if summer else "更短" if winter else "约等长"
		altitude.text = "更高" if summer else "更低" if winter else "居中"
		if state.tilt == 0: daylight.text = "不变"; altitude.text = "不变"
		explanation.text = "两个变化共同影响日照：\n"+("阳光更集中，白昼更长。" if summer else "阳光更分散，白昼更短。" if winter else "两半球日照大致相当。")
		if state.tilt == 0: explanation.text = "对照发现：去掉地轴倾斜后，\n公转仍继续，日照不再随季节变化。"
		metrics.text = "观察地点：%s纬 40°" % ("南" if state.south else "北")
		day_value.text = "约 %.1f 小时" % result.hours
		altitude_value.text = "约 %.1f°" % result.altitude
		opposite.text = "此模型中，全年日照指标不变。" if state.tilt == 0 else ("❄  " if summer else "☀  ")+"此时，"+("北" if state.south else "南")+"半球是"+seasons[(index+(0 if state.south else 2))%4]+"。"
		opposite.tooltip_text = "当地气温变化还可能滞后于日照变化，至日并不等于最热或最冷的一天。"
		for i in range(2):
			segment_style(hemi_buttons[i],state.south == (i == 1))
			segment_style(tilt_buttons[i],(state.tilt == 0) == (i == 1))
	var prefix := ""
	if state.step == 2 and state.answer >= 0:
		prefix = "答对了！倾角与公转共同改变日照。\n" if state.answer == 0 else "再观察：同一时刻两半球的季节相反，并不是距离导致。\n"
	if state.step == 2 and state.answer >= 0: preload("res://scripts/ui/quiz_style.gd").feedback(feedback,state.answer == 0)
	feedback.text = prefix+"已观察 %d/4 · 不倾斜对照%s" % [state.visited.size()," ✓" if state.contrast else " 未完成"]
	if Model.complete(state):
		feedback.text = "✓ 实验完成！地轴倾斜与公转共同改变日照。"
		if not store.data.lessons.has("seasons"):
			store.data.lessons.append("seasons")
			save()
func save(force := false) -> void:
	store.data.seasons = state.duplicate(true)
	# Keep the visible state current without blocking each drag update on a disk flush.
	if force: _slider_dragging = false
	if _slider_dragging and not force: return
	store.save_progress()
func _process(delta: float) -> void:
	if playing:
		var was_complete: bool = store.data.lessons.has("seasons")
		set_angle(minf(360,state.angle+delta*24))
		if _playback_from_user: _finish_user_action(was_complete,"")
		if state.angle >= 360: set_playing(false); save()
func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_RESUMED]:
		_activity.handle_notification(what)
		_foreground = _activity.is_active()
		if not _foreground and is_instance_valid(play_button):
			set_playing(false)
			save(true)
func _exit_tree() -> void:
	if state != null and store != null: save(true)
