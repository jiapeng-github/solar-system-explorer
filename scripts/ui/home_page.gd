extends VBoxContainer
signal destination_requested(destination: String)
signal continue_requested
signal seasons_requested
signal sources_requested
const Style = preload("res://scripts/ui/visual_style.gd")
const Audio = preload("res://scripts/ui_audio.gd")
var visited := 0
var lessons := 0
var selected_name := "地球"
var hero: BoxContainer
var hero_art: TextureRect
var intro: VBoxContainer
var title: Label
var actions: BoxContainer
var progress_row: BoxContainer
var segments: HBoxContainer
var cards: BoxContainer
var card_buttons: Array[Button] = []
var card_titles: Array[Label] = []
var card_art: Array[Control] = []
var footer: BoxContainer
var primary_button: Button
var continue_button: Button
var progress_button: Button
var visit_label: Label
var lesson_label: Label
func label(value: String, parent: Node, font_size := 17, color := Color("eaf1fc")) -> Label:
	var node := Label.new()
	node.text = value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	parent.add_child(node)
	return node
func button(value: String, parent: Node, action: Callable, primary := false) -> Button:
	var node := Button.new()
	# Let the page scroll take over a drag that starts on a button.
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	node.text = value
	node.add_theme_font_size_override("font_size",18)
	node.custom_minimum_size.y = 48
	for key in ["normal","hover","pressed"]:
		var skin := Style.box(Color("43dff4") if primary else Color("04111caa"),13,13)
		skin.border_color = Color("67eafb")
		if key == "hover": skin.bg_color = skin.bg_color.lightened(.13)
		node.add_theme_stylebox_override(key,skin)
		node.add_theme_color_override("font_color" if key == "normal" else "font_"+key+"_color",Color("012233") if primary else Color("b8ecfc"))
	var focus := Style.box(Color.TRANSPARENT,13,0)
	focus.border_color = Color("97f5ff")
	focus.set_border_width_all(2)
	node.add_theme_stylebox_override("focus",focus)
	node.pressed.connect(func() -> void:
		Audio.play_from(self, "navigate")
		action.call()
	)
	parent.add_child(node)
	return node
func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",12)
	hero = BoxContainer.new()
	hero.add_theme_constant_override("separation",4)
	hero.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(hero)
	intro = VBoxContainer.new()
	intro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro.size_flags_stretch_ratio = .40
	intro.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	intro.add_theme_constant_override("separation",14)
	hero.add_child(intro)
	label("今天，从一颗星球开始",intro,18,Color("b5c8e1"))
	title = label("从这里出发\n探索太阳系",intro,58)
	label("走近八大行星，亲手发现宇宙的奥秘。",intro,18)
	var gap := Control.new()
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gap.custom_minimum_size.y = 6
	intro.add_child(gap)
	actions = BoxContainer.new()
	actions.add_theme_constant_override("separation",14)
	intro.add_child(actions)
	primary_button = button("进入太阳系  →",actions,func(): destination_requested.emit("explore"),true)
	primary_button.custom_minimum_size.x = 205
	continue_button = button(("继续探索" if visited > 0 else "认识")+selected_name,actions,func(): continue_requested.emit())
	var visual := Control.new()
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual.size_flags_stretch_ratio = .60
	visual.custom_minimum_size.y = 335
	hero.add_child(visual)
	hero_art = TextureRect.new()
	hero_art.texture = preload("res://assets/art/home-saturn-v2.png")
	hero_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visual.add_child(hero_art)
	var saturn_label := label("土星\nSATURN",visual,14,Color("b5cce7"))
	saturn_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	saturn_label.position = Vector2(-114,-94)
	saturn_label.size = Vector2(100,48)
	visual.resized.connect(func(): saturn_label.position = Vector2(visual.size.x*.81,visual.size.y*.65))
	var progress_frame := PanelContainer.new()
	progress_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	progress_frame.add_theme_stylebox_override("panel",Style.box(Color("051522c0"),14,12))
	add_child(progress_frame)
	progress_row = BoxContainer.new()
	progress_row.add_theme_constant_override("separation",18)
	progress_frame.add_child(progress_row)
	var progress_title := label("你的探索旅程",progress_row,24)
	progress_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	progress_title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	visit_label = label("已探索 %d / 8 颗行星" % visited,progress_row,15,Color("c2d2e7"))
	visit_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	visit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	segments = HBoxContainer.new()
	segments.size_flags_horizontal = Control.SIZE_FILL
	segments.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	segments.add_theme_constant_override("separation",6)
	progress_row.add_child(segments)
	for i in range(8):
		var segment := Panel.new()
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		segment.custom_minimum_size = Vector2(18,10)
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var skin := Style.box(Color("51e2f2") if i < visited else Color("1b354c"),5,0)
		skin.set_border_width_all(0)
		segment.add_theme_stylebox_override("panel",skin)
		segments.add_child(segment)
	lesson_label = label("已完成 %d / 3 个实验" % lessons,progress_row,15,Color("c2d2e7"))
	lesson_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	lesson_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_button = button("查看进度  →",progress_row,func(): destination_requested.emit("progress"))
	progress_button.add_theme_font_size_override("font_size",16)
	progress_button.custom_minimum_size.y = 30
	progress_button.add_theme_stylebox_override("normal",Style.box(Color.TRANSPARENT,8,3))
	cards = BoxContainer.new()
	cards.add_theme_constant_override("separation",14)
	add_child(cards)
	for i in range(3):
		var index := i
		var frame := PanelContainer.new()
		frame.mouse_filter = Control.MOUSE_FILTER_PASS
		frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		frame.custom_minimum_size.y = 192
		frame.add_theme_stylebox_override("panel",Style.box(Color("061623b0"),13,10))
		cards.add_child(frame)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",6)
		frame.add_child(row)
		var art := preload("res://scripts/ui/home_card_art.gd").new()
		art.kind = i
		art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		art.size_flags_stretch_ratio = .48
		row.add_child(art)
		card_art.append(art)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.size_flags_stretch_ratio = .52
		words.add_theme_constant_override("separation",6)
		row.add_child(words)
		label(["探索","实验室 · 3 个互动实验","比较"][i],words,13,Color("69d9f5"))
		card_titles.append(label(["认识八大行星","地球为什么有四季？","行星有多大？"][i],words,21))
		label(["从水星到海王星","改变地轴，观察日照变化","用同一比例，比较不同世界"][i],words,14,Color("bdcfe4"))
		var space := Control.new()
		space.mouse_filter = Control.MOUSE_FILTER_IGNORE
		space.size_flags_vertical = Control.SIZE_EXPAND_FILL
		words.add_child(space)
		var enter := button("→",words,func(): open_card(index))
		enter.size_flags_horizontal = Control.SIZE_SHRINK_END
		enter.custom_minimum_size = Vector2(40,40)
		enter.add_theme_font_size_override("font_size",24)
		for key in ["normal","hover","pressed"]:
			var skin := Style.box(Color("06223390") if key == "normal" else Color("12516a"),24,0)
			skin.border_color = Color("65e8f6")
			enter.add_theme_stylebox_override(key,skin)
		enter.tooltip_text = card_titles[i].text
		card_buttons.append(enter)
	footer = BoxContainer.new()
	add_child(footer)
	label("↓  核心内容离线可用",footer,13,Color("a5bdd7"))
	var note := LinkButton.new()
	note.mouse_filter = Control.MOUSE_FILTER_PASS
	note.text = "ⓘ  资料与模型说明"
	note.add_theme_font_size_override("font_size",13)
	note.custom_minimum_size.y = 24
	note.pressed.connect(func() -> void:
		Audio.play_from(self, "tap")
		sources_requested.emit()
	)
	footer.add_child(note)
	resized.connect(adapt)
	adapt()
func open_card(index: int) -> void:
	if index == 1: seasons_requested.emit()
	else: destination_requested.emit("explore" if index == 0 else "compare")
func adapt() -> void:
	var compact := size.x < 900
	hero.vertical = compact
	progress_row.vertical = size.x < 1100
	segments.custom_minimum_size.x = 0 if size.x < 1100 else minf(size.x*.29,370)
	cards.vertical = compact
	footer.vertical = compact
	actions.vertical = size.x < 460
	title.add_theme_font_size_override("font_size",40 if compact else 58)
	intro.size_flags_vertical = Control.SIZE_FILL if compact else Control.SIZE_SHRINK_CENTER
	for i in range(3):
		card_titles[i].add_theme_font_size_override("font_size",20 if compact else 22)
		card_art[i].size_flags_stretch_ratio = .42 if i == 1 else .48
