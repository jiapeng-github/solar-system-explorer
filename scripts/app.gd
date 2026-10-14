extends Control
const Sound = preload("res://scripts/ui_audio.gd")
var audio = Sound.new()
var _sound_button: Button
var _brand_row: HBoxContainer
var _task_answers := {}
const SolarWorld = preload("res://scripts/solar_system.gd")
const Catalog = preload("res://scripts/catalog.gd")
const Store = preload("res://scripts/progress_store.gd")
const Tasks = preload("res://scripts/learning_tasks.gd")
const LearningCanvas = preload("res://scripts/learning_canvas.gd")
const SUMMARIES = [
	"离太阳最近的岩石行星", "被浓厚大气与云层包裹的世界",
	"目前已知唯一孕育生命的行星", "拥有火山与峡谷的红色星球",
	"太阳系中体积最大的行星", "醒目的行星环由许多颗粒组成",
	"拥有独特自转姿态的冰巨行星", "八大行星中离太阳最远的一颗"
]
const VisualStyle = preload("res://scripts/ui/visual_style.gd")
const CompareControls = preload("res://scripts/ui/compare_controls.gd")
const PickerDecoration = preload("res://scripts/ui/picker_decoration.gd")
const SelectionOverlay = preload("res://scripts/ui/selection_overlay.gd")
const BG := Color("050e1b")
const PANEL := Color("081827d9")
const INK := Color("e4edf8")
const MUTED := Color("9cafc7")
const ACCENT := Color("7ce5f7")
var quality = preload("res://scripts/quality_settings.gd").new()
var _settings: AcceptDialog
var _explore_heading: BoxContainer
var _region_buttons: Dictionary = {}
var _view_buttons: Dictionary = {}
var _quality_picker: OptionButton
var _quality_note: Label
var _showcase
var _space_backdrop
var knowledge: Dictionary = {}
var _reset_dialog: Control
var _task_feedback := {}
var catalog: Array = []
var progress = Store.new()
var page := "home"
var selected_index := 2
var world
var viewport: SubViewport
var _layout: VBoxContainer
var _body: VBoxContainer
var _info: VBoxContainer
var _split: BoxContainer
var _scene_container: SubViewportContainer
var _time_label: Label
var _pause: Button
var _planet_buttons: Array[Button] = []
var _canvas
var _year_lab
var _feedback: Label
var _angle_label: Label
var _timer := 0.0
var _foreground := true
var _activity = preload("res://scripts/app_activity.gd").new()
var _lab_mode := "day"
var _angle := 180.0
var _answer := ""
var _sources: Control
var _compact := false
var _stage: Control
var _title: Label
var _eyebrow: Label
var _planet_grid: GridContainer
var _nav_buttons: Dictionary = {}
var _scene_opened := false
var _brand_button: Button
var _navigation: HFlowContainer
var _header: BoxContainer
var _home_progress: BoxContainer
var _cards: BoxContainer
var _slider: HSlider
var _playing := false
var _play_button: Button
var _comparison_hint: Label
var _comparison_heading: BoxContainer
var _compare_info: VBoxContainer
var _compare_first := 2
var _compare_second := 4
var _compare_mode := "size"
var _compare_slot := 0
var _slot_buttons: Array[Button] = []
var _comparison_buttons: Array[Button] = []
var _pickers: Array[OptionButton] = []
var _lesson_states := {"day": {"angle":180.0,"answer":""}, "year":{"angle":0.0,"answer":""},"seasons":{"angle":90.0,"answer":""}}
var _history: Array[String] = []
var _back_button: Button
var _body_scroll: ScrollContainer
var _guide_status: Label
var _guide_instructions: Label
var _summary: VBoxContainer
var _answer_buttons: Array[Button] = []
var _scroll_positions := {}


func _ready() -> void:
	audio.name = "UIAudio"
	add_child(audio)
	catalog = Catalog.load_planets()
	knowledge = JSON.parse_string(FileAccess.get_file_as_string("res://data/knowledge.json")).planets
	if catalog.size() != 8:
		var failure := Label.new()
		failure.text = "天体数据加载失败，请重新安装完整应用。"
		add_child(failure)
		return
	progress.load_progress()
	quality.load_settings()
	# The public app now always starts in HD, including upgrades from older settings.
	quality.level = 2
	for i in range(catalog.size()):
		if catalog[i].id == progress.data.selected:
			selected_index = i
	get_tree().auto_accept_quit = false
	_theme()
	var background := preload("res://scripts/space_backdrop.gd").new()
	_space_backdrop = background
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,20)
	add_child(margin)
	_layout = VBoxContainer.new()
	_layout.add_theme_constant_override("separation",12)
	margin.add_child(_layout)
	_header = BoxContainer.new()
	_header.add_theme_constant_override("separation",20)
	_layout.add_child(_header)
	var brand_row := HBoxContainer.new()
	_brand_row = brand_row
	_header.add_child(brand_row)
	var brand := _button("太阳系漫游",brand_row,func() -> void: _navigate_from_ui("home"))
	_brand_button = brand
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.alignment = HORIZONTAL_ALIGNMENT_LEFT
	brand.icon = preload("res://assets/ui/brand-mark-v3.png")
	brand.add_theme_constant_override("icon_max_width",48)
	brand.add_theme_font_size_override("font_size",26)
	brand.add_theme_stylebox_override("normal",_style(Color.TRANSPARENT,0,0))
	_back_button = _button("‹",brand_row,_go_back)
	_back_button.tooltip_text = "返回上一页"
	_back_button.custom_minimum_size.x = 48
	var navigation := HFlowContainer.new()
	_navigation = navigation
	navigation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	navigation.alignment = FlowContainer.ALIGNMENT_CENTER
	navigation.add_theme_constant_override("h_separation",12)
	_header.add_child(navigation)
	for nav in [["出发","home"],["探索","explore"],["实验室","lab"],["比较","compare"],["进度","progress"]]:
		var dest: String = nav[1]
		var button := _button(nav[0],navigation,func() -> void: _navigate_from_ui(dest))
		button.custom_minimum_size.x = 76
		button.toggle_mode = true
		button.add_theme_stylebox_override("normal",_style(Color.TRANSPARENT,0,12))
		var active := _style(Color("08182755"),0,12)
		active.set_border_width_all(0)
		active.border_color = ACCENT
		active.border_width_bottom = 2
		button.add_theme_stylebox_override("pressed",active)
		_nav_buttons[dest] = button
	_sound_button = preload("res://scripts/ui/sound_button.gd").new()
	_sound_button.name = "SoundToggle"
	_sound_button.setup(audio)
	_header.add_child(_sound_button)
	var rule := HSeparator.new()
	var line := StyleBoxLine.new()
	line.color = Color("23394c")
	line.thickness = 1
	rule.custom_minimum_size.y = 1
	rule.add_theme_stylebox_override("separator",line)
	_layout.add_child(rule)
	_body = VBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body_scroll := ScrollContainer.new()
	_body_scroll = body_scroll
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_layout.add_child(body_scroll)
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.add_child(_body)
	var dialog_layer := CanvasLayer.new()
	dialog_layer.layer = 40
	add_child(dialog_layer)
	_sources = preload("res://scripts/ui/quiz_overlay.gd").new()
	dialog_layer.add_child(_sources)
	_sources.set_heading("资料与模型说明")
	var source_text := "数据：NASA / JPL Solar System Dynamics\nssd.jpl.nasa.gov/planets/phys_par.html\nssd.jpl.nasa.gov/planets/approx_pos.html\n\n校对日期：2026-10-07\n半径为体积等效平均半径；公转周期为恒星周期。\n椭圆轨道固定且共面，初始相位为示意，不是实时星历。\n地球：NASA Blue Marble；月球：NASA SVS CGI Moon Kit。\n其他行星：Solar System Scope（CC BY 4.0）。\n色彩经过艺术调整，探索视图未模拟真实轴倾角；四季实验使用约23.4°倾角。\n地月距离与大小经调整；月球周期采用约 27.3 天。\n\n基础内容离线可用。学习记录仅保存在本机。\n地球贴图：NASA/GSFC Scientific Visualization Studio\nsvs.gsfc.nasa.gov/2915\n月球贴图：NASA/GSFC/ASU，Ernie Wright\nsvs.gsfc.nasa.gov/4720\n\n行星贴图：Solar System Scope / INOVE\nsolarsystemscope.com/textures\nCC BY 4.0 · creativecommons.org/licenses/by/4.0/\n贴图经球面映射、光照和缩略图渲染处理。\n\nGodot Engine — MIT License\ngodotengine.org/license"
	_label(source_text,_sources.content,16,MUTED)
	_button("返回",_sources.content,_sources.dismiss,true)
	_build_settings()
	_build_reset_dialog()
	get_window().size_changed.connect(_window_resized)
	_window_resized()
	resized.connect(_responsive)
	_compact = size.x/ maxf(size.y,1) < 1.1
	navigate("home")

func _theme() -> void:
	var t := Theme.new()
	t.default_font_size = 19
	for state in ["normal","hover","pressed","focus","disabled"]:
		var style := _style(PANEL if state == "normal" else Color("173449"),12,12)
		if state in ["focus","pressed"]:
			style.border_color = ACCENT
			style.set_border_width_all(2)
		t.set_stylebox(state,"Button",style)
		t.set_stylebox(state,"OptionButton",style)
	t.set_color("font_disabled_color","Button",MUTED)
	t.set_color("font_color","Button",INK)
	t.set_color("font_color","OptionButton",INK)
	t.set_color("font_color","Label",INK)
	t.set_color("font_hover_color","Button",INK)
	t.set_color("font_pressed_color","Button",ACCENT)
	t.set_constant("separation","VBoxContainer",12)
	t.set_constant("separation","HBoxContainer",10)
	t.set_constant("h_separation","HFlowContainer",8)
	t.set_constant("v_separation","HFlowContainer",8)
	theme = t

func _style(color: Color, radius := 16, padding := 18) -> StyleBoxFlat:
	return VisualStyle.box(color,radius,padding)

func _label(text: String, parent: Node, font_size := 19, color := INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if parent is HFlowContainer:
		label.custom_minimum_size.x = text.length()*font_size
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	parent.add_child(label)
	return label

func _button(text: String, parent: Node, callback: Callable, primary := false, cue := "") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 48
	b.pressed.connect(func():
		Sound.play_from(self,cue)
		callback.call()
	)
	if primary:
		b.add_theme_stylebox_override("normal",VisualStyle.primary())
		b.add_theme_color_override("font_color",Color("082432"))
		for state in ["hover","pressed"]:
			b.add_theme_stylebox_override(state,_style(Color("a9f1ff"),12,12))
			b.add_theme_color_override("font_"+state+"_color",Color("082432"))
	parent.add_child(b)
	return b

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _navigate_from_ui(destination: String) -> void:
	if destination == page:
		_nav_buttons[destination].set_pressed_no_signal(true)
		return
	Sound.play_from(self,"navigate")
	navigate(destination)

func navigate(destination: String, remember := true) -> void:
	_space_backdrop.rich = destination in ["home","progress"]
	_space_backdrop.queue_redraw()
	if _body.get_child_count() > 0:
		_scroll_positions[page] = _body_scroll.scroll_vertical
		if destination != page and remember:
			_history.append(page)
			if _history.size() > 32: _history.pop_front()
	_back_button.disabled = destination == "home" and _history.is_empty()
	_back_button.visible = destination == "knowledge"
	_layout.add_theme_constant_override("separation",4 if destination == "progress" else 12)
	_answer_buttons.clear()
	_summary = null
	_year_lab = null
	_guide_status = null
	# Keep simulation/camera state when leaving and returning to exploration.
	if is_instance_valid(world):
		world.camera.cancel_gestures()
		if viewport.get_parent() != null:
			viewport.get_parent().remove_child(viewport)
		world.set_process(false)
		world.camera.set_process(false)
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_playing = false
	_showcase = null
	_home_progress = null
	_cards = null
	_slider = null
	_play_button = null
	_compare_info = null
	_comparison_hint = null
	_comparison_heading = null
	_pickers.clear()
	_slot_buttons.clear()
	_comparison_buttons.clear()
	_body.add_theme_constant_override("separation",12)
	_clear(_body)
	_info = null
	_split = null
	_time_label = null
	_title = null
	_eyebrow = null
	_stage = null
	_explore_heading = null
	_region_buttons.clear()
	_view_buttons.clear()
	_planet_grid = null
	_planet_buttons.clear()
	page = destination
	for dest in _nav_buttons:
		_nav_buttons[dest].set_pressed_no_signal(dest == page or (dest == "explore" and page == "knowledge"))
	match page:
		"home": _home()
		"explore": _explore()
		"lab": _lab()
		"compare": _compare()
		"knowledge": _knowledge_page()
		"progress": _progress_page()
	call_deferred("_restore_scroll",destination)

func _restore_scroll(destination: String) -> void:
	if page == destination: _body_scroll.scroll_vertical = _scroll_positions.get(destination,0)

func _go_back() -> void:
	var progress_page := _body.get_node_or_null("ProgressPage")
	if _reset_dialog.visible:
		_reset_dialog.dismiss()
	elif _settings.visible:
		_settings.hide()
	elif _sources.visible:
		_sources.dismiss()
	elif is_instance_valid(progress_page) and progress_page.quiz.visible:
		progress_page.quiz.dismiss()
	elif not _history.is_empty():
		Sound.play_from(self,"back")
		navigate(_history.pop_back(),false)
	elif page != "home":
		Sound.play_from(self,"back")
		navigate("home",false)


func _columns() -> BoxContainer:
	_split = BoxContainer.new()
	_split.vertical = _compact
	_split.add_theme_constant_override("separation",24)
	_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.add_child(_split)
	return _split

func _panel_content(parent: Node, width := 0) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_style(PANEL,20,20))
	panel.custom_minimum_size.x = width
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation",9)
	panel.add_child(content)
	return content

func _home() -> void:
	var home := preload("res://scripts/ui/home_page.gd").new()
	home.name = "HomePage"
	home.visited = progress.data.visited.size()
	home.lessons = progress.data.lessons.size()
	home.selected_name = catalog[selected_index].name
	home.destination_requested.connect(func(destination): navigate(destination))
	home.continue_requested.connect(func(): navigate("explore"); world.select_body(selected_index,true))
	home.seasons_requested.connect(func(): _open_lesson("seasons"))
	home.sources_requested.connect(_show_sources)
	_body.add_child(home)
	_showcase = home.hero_art
	if not progress.error_message.is_empty(): _label(progress.error_message,_body,16,MUTED)

func _create_scene(parent: Node) -> void:
	_scene_container = SubViewportContainer.new()
	_scene_container.stretch = true
	_scene_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_container.custom_minimum_size = Vector2(0,280)
	parent.add_child(_scene_container)
	if not is_instance_valid(viewport):
		viewport = SubViewport.new()
		viewport.size = Vector2i(700,420)
		viewport.own_world_3d = true
		viewport.transparent_bg = true
		viewport.msaa_3d = Viewport.MSAA_2X
		_scene_container.add_child(viewport)
		world = SolarWorld.new()
		viewport.add_child(world)
		world.selected.connect(_on_selected)
		world.view_changed.connect(_update_info)
		world.selected_index = selected_index
	else:
		_scene_container.add_child(viewport)
	world.set_process(_foreground)
	world.camera.set_process(_foreground)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _foreground else SubViewport.UPDATE_DISABLED
	_apply_quality()

func _explore() -> void:
	_body.add_theme_constant_override("separation",10)
	_explore_heading = BoxContainer.new()
	_explore_heading.vertical = _compact
	_body.add_child(_explore_heading)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation",2)
	_explore_heading.add_child(titles)
	_title = _label("",titles,30)
	_eyebrow = _label("",titles,16,MUTED)
	var regions := HBoxContainer.new()
	regions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	regions.add_theme_constant_override("separation",0)
	_explore_heading.add_child(regions)
	for entry in [["全部行星","all"],["内太阳系","inner"],["外太阳系","outer"]]:
		var region: String = entry[1]
		var region_button := _button(entry[0],regions,func() -> void: _choose_region(region))
		region_button.custom_minimum_size = Vector2(100,40)
		region_button.add_theme_font_size_override("font_size",16)
		_region_buttons[region] = region_button
	_split = BoxContainer.new()
	_split.vertical = _compact
	_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_split.add_theme_constant_override("separation",16)
	_body.add_child(_split)
	_stage = Control.new()
	_stage.custom_minimum_size.y = 340
	_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_split.add_child(_stage)
	_create_scene(_stage)
	_scene_container.custom_minimum_size = Vector2.ZERO
	_scene_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var label_overlay := preload("res://scripts/ui/orbit_labels.gd").new()
	label_overlay.world = world
	_stage.add_child(label_overlay)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel",_style(PANEL,24,12))
	panel.custom_minimum_size.x = 300
	_split.add_child(panel)
	_info = VBoxContainer.new()
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.add_theme_constant_override("separation",2)
	panel.add_child(_info)
	var toolbar := PanelContainer.new()
	toolbar.add_theme_stylebox_override("panel",_style(Color("091827df"),26,4))
	_body.add_child(toolbar)
	var controls := HFlowContainer.new()
	controls.add_theme_constant_override("h_separation",8)
	toolbar.add_child(controls)
	_pause = _button("▷  继续" if world.paused else "Ⅱ  暂停",controls,_toggle_pause)
	var speed := OptionButton.new()
	speed.custom_minimum_size = Vector2(164,40)
	speed.name = "SimulationSpeed"
	for value in [1,12,120,365]:
		speed.add_item("1 秒 = %d 天" % value)
	speed.select([1.0,12.0,120.0,365.0].find(world.days_per_second))
	speed.item_selected.connect(_choose_speed)
	speed.get_popup().about_to_popup.connect(func(): Sound.play_from(self,"tap"))
	controls.add_child(speed)
	var orbits := _button("轨道",controls,func() -> void: pass)
	orbits.toggle_mode = true
	orbits.button_pressed = world.orbits_visible
	orbits.toggled.connect(func(enabled: bool):
		world.set_orbits(enabled)
		Sound.play_from(self,"toggle_on" if enabled else "toggle_off")
	)
	_view_buttons["overview"] = _button("全景",controls,func() -> void: _overview_from_ui())
	_view_buttons["close"] = _button("近景",controls,func() -> void: _select_planet(selected_index,true))
	var zoom_out := _button("−",controls,func() -> void: _zoom_from_ui(1.2))
	zoom_out.custom_minimum_size.x = 44
	zoom_out.tooltip_text = "缩小（也可双指捏合或滚轮向下）"
	var zoom_in := _button("＋",controls,func() -> void: _zoom_from_ui(1.0/1.2))
	zoom_in.custom_minimum_size.x = 44
	zoom_in.tooltip_text = "放大（也可双指张开或滚轮向上）"
	_button("恢复视角",controls,func() -> void: _restore_view_from_ui())
	var gesture_hint := _label("拖动旋转 · 双指缩放",controls,13,MUTED)
	gesture_hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for control in controls.get_children():
		if control is Button or control is OptionButton:
			control.custom_minimum_size.y = 40
			control.add_theme_font_size_override("font_size",17)
			if control is OptionButton:
				CompareControls.option(control)
			else:
				CompareControls.button(control,"selector")
				control.add_theme_stylebox_override("pressed",CompareControls.skin("active"))
				control.add_theme_stylebox_override("hover_pressed",CompareControls.skin("active",true))
	var tray := PanelContainer.new()
	tray.add_theme_stylebox_override("panel",_style(Color("091625e8"),22,8))
	_body.add_child(tray)
	_planet_grid = GridContainer.new()
	_planet_grid.columns = 4 if _compact else 8
	_planet_grid.add_theme_constant_override("h_separation",8)
	tray.add_child(_planet_grid)
	for i in range(catalog.size()):
		var index := i
		var button := _button("",_planet_grid,func() -> void: _select_planet(index,world.camera.follow_node != null,"select"))
		button.toggle_mode = true
		button.tooltip_text = "探索"+catalog[i].name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(74,96)
		button.add_theme_stylebox_override("normal",_style(Color.TRANSPARENT,16,6))
		var active := _style(Color.TRANSPARENT,16,6)
		active.border_color = ACCENT
		active.set_border_width_all(1)
		button.add_theme_stylebox_override("pressed",active)
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_top = 4
		content.add_theme_constant_override("separation",2)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(content)
		var thumbnail := TextureRect.new()
		var path: String = "res://assets/thumbnails/"+catalog[i].id+".png"
		if ResourceLoader.exists(path): thumbnail.texture = load(path)
		thumbnail.custom_minimum_size = Vector2(66,65)
		thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(thumbnail)
		var name_label := _label(catalog[i].name,content,17)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var overlay := SelectionOverlay.new()
		overlay.name = "SelectionOverlay"
		overlay.circular = true
		button.add_child(overlay)
		_planet_buttons.append(button)
	var foot := HBoxContainer.new()
	_body.add_child(foot)
	_time_label = _label("",foot,13,MUTED)
	var note := _label("大小与轨道间距均经示意处理 · 真实比例请前往「比较」",foot,12,MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if not _scene_opened:
		world.reset_view()
		_scene_opened = true
	_update_info()
	_responsive()

func _on_selected(index: int) -> void:
	selected_index = index
	progress.visit(catalog[index].id)
	if page == "explore":
		_update_info()

func _update_info() -> void:
	if not is_instance_valid(_info): return
	_clear(_info)
	var p: Dictionary = catalog[selected_index]
	_eyebrow.text = "太阳系   /   "+p.kind if world.camera.follow_node != null else "看清八大行星，探索各自的轨道。"
	_title.text = ("我们的蓝色星球" if p.id == "earth" else "走近"+p.name+"的世界") if world.camera.follow_node != null else "太阳系 · 全景探索"
	for region in _region_buttons:
		CompareControls.button(_region_buttons[region],"active" if region == world.region and world.camera.follow_node == null else "selector")
	for mode in _view_buttons:
		CompareControls.button(_view_buttons[mode],"active" if (mode == "overview") == (world.camera.follow_node == null) else "selector")
	_label(p.id.to_upper()+"  ·  %02d" % (selected_index+1),_info,15,MUTED)
	_label(p.name,_info,32)
	var summary := _label(SUMMARIES[selected_index],_info,16,MUTED)
	summary.tooltip_text = p.description
	_metric("平均半径",_grouped_number(p.radius_km)+" km")
	_metric("公转周期",("%.2f 天" % (p.period_years*365.25)) if p.period_years < 2 else ("%.2f 年" % p.period_years))
	_metric("恒星自转",("%.2f 小时" % absf(p.rotation_days*24)) if absf(p.rotation_days) < 2 else ("%.2f 天" % absf(p.rotation_days)))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info.add_child(spacer)
	if world.camera.follow_node == null:
		var close := _button("进入近景  →",_info,func() -> void: _select_planet(selected_index,true))
		CompareControls.button(close,"primary")
		var read := _button("阅读知识卡",_info,func() -> void: navigate("knowledge"),false,"navigate")
		CompareControls.button(read,"secondary")
	else:
		_button("阅读"+p.name+"知识卡  →",_info,func() -> void: navigate("knowledge"),true,"navigate")
		if p.id == "earth":
			_button("探索昼夜",_info,func() -> void: _open_lesson("day"),false,"navigate")
		else:
			_button("与地球比较",_info,_compare_with_earth,false,"navigate")
	_label("数据来源  NASA / JPL",_info,13,MUTED)
	for i in range(_planet_buttons.size()):
		_planet_buttons[i].set_pressed_no_signal(i == selected_index)
		_planet_buttons[i].get_node("SelectionOverlay").update_state(i == selected_index)

func _grouped_number(value: float) -> String:
	var raw := str(roundi(value))
	var output := ""
	for i in range(raw.length()):
		if i > 0 and (raw.length()-i)%3 == 0: output += ","
		output += raw[i]
	return output

func _metric(title: String, value: String) -> void:
	var separator := HSeparator.new()
	separator.add_theme_constant_override("separation",5)
	var line := StyleBoxLine.new()
	line.color = Color("294358")
	separator.add_theme_stylebox_override("separator",line)
	_info.add_child(separator)
	var row := HBoxContainer.new()
	_info.add_child(row)
	_label(title,row,17,MUTED)
	var number := _label(value,row,21)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _toggle_pause() -> void:
	world.paused = not world.paused
	Sound.play_from(self,"toggle_off" if world.paused else "toggle_on")
	_pause.text = "▷  继续" if world.paused else "Ⅱ  暂停"

func _open_lesson(mode: String) -> void:
	var switching := mode != _lab_mode
	_lab_mode = mode
	_angle = _lesson_states[mode].angle
	_answer = _lesson_states[mode].answer
	navigate("lab")
	if switching:
		_scroll_positions["lab"] = 0
		_body_scroll.scroll_vertical = 0

func _lab() -> void:
	if _lab_mode == "seasons":
		_body.add_theme_constant_override("separation",7)
		var experiment := preload("res://scripts/ui/seasons_lab.gd").new()
		experiment.name = "SeasonsLab"
		experiment.store = progress
		experiment.lesson_requested.connect(_open_lesson)
		_body.add_child(experiment)
		return
	if _lab_mode == "year":
		_year_lab = preload("res://scripts/ui/year_lab.gd").new()
		_year_lab.name = "YearLab"
		_year_lab.lesson_requested.connect(_open_lesson)
		_year_lab.angle_changed.connect(_change_angle)
		_year_lab.play_requested.connect(func(): _set_playing(not _playing))
		_year_lab.pause_requested.connect(func(): _set_playing(false))
		_year_lab.reset_requested.connect(_reset_lesson)
		_body.add_child(_year_lab)
		_canvas = _year_lab.canvas
		_slider = _year_lab.slider
		_bind_year_completion(_slider)
		_play_button = _year_lab.play_button
		_angle_label = _year_lab.progress_label
		_change_angle(_angle)
		return
	var modes := HFlowContainer.new()
	modes.add_theme_constant_override("h_separation",22)
	_body.add_child(modes)
	_label("为什么会有昼夜？" if _lab_mode == "day" else "一年是怎样形成的？",modes,36)
	_button("自转与昼夜",modes,func() -> void: _lesson_from_ui("day"),_lab_mode == "day")
	_button("公转与一年",modes,func() -> void: _lesson_from_ui("year"),_lab_mode == "year")
	_button("四季与地轴",modes,func(): _lesson_from_ui("seasons"))
	var columns := _columns()
	var stage := VBoxContainer.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(stage)
	_canvas = LearningCanvas.new()
	_canvas.mode = _lab_mode
	_canvas.angle = _angle
	_canvas.custom_minimum_size.y = 350
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(_canvas)
	var console := _panel_content(stage)
	console.get_parent().add_theme_stylebox_override("panel",_style(Color("081827df"),20,12))
	_angle_label = _label("",console,20,ACCENT)
	_slider = preload("res://scripts/ui/angle_slider.gd").new()
	_slider.orbital = _lab_mode == "year"
	_slider.min_value = 0
	_slider.max_value = 360
	_slider.step = 1
	_slider.value = _angle
	_slider.custom_minimum_size.y = 48
	_slider.tick_count = 5
	_slider.add_theme_stylebox_override("slider",_style(Color("20364b"),3,3))
	_slider.add_theme_stylebox_override("grabber_area",_style(ACCENT,3,3))
	_slider.value_changed.connect(func(value: float) -> void:
		_set_playing(false)
		_change_angle(value)
	)
	_slider.drag_started.connect(func() -> void: _set_playing(false))
	console.add_child(_slider)
	Sound.bind_slider(_slider)
	var controls := HFlowContainer.new()
	console.add_child(controls)
	_play_button = _button("▶ 播放自转" if _lab_mode == "day" else "▶ 播放公转",controls,func() -> void: _set_playing(not _playing,true),true)
	_button("↻ 重置",controls,func(): _reset_lesson(true))
	var guide := _panel_content(columns,330)
	_label("实验 01" if _lab_mode == "day" else "实验 02",guide,15,MUTED)
	_guide_status = _label("观察 → 思考 → 验证",guide,25)
	_guide_instructions = _label("①  A 点代表地球上的同一地点\n②  转动地球，观察 A 点明暗变化\n③  回答问题，验证你的发现" if _lab_mode == "day" else "1  从起点沿箭头观察公转\n2  每段刻度约代表一个月\n3  拖到终点或播放一圈，完成实验",guide,17,MUTED)
	if _lab_mode == "day":
		_label("昼夜交替主要是因为？",guide,20)
		for option in ["地球自转","地球公转","太阳忽明忽暗"]:
			var answer: String = option
			var option_button := _button(answer,guide,func() -> void: _answer_question(answer,true))
			option_button.toggle_mode = true
			preload("res://scripts/ui/quiz_style.gd").option(option_button,_answer_buttons.size())
			_answer_buttons.append(option_button)
	_feedback = _label("",guide,17,ACCENT)
	_feedback.add_theme_stylebox_override("normal",_style(Color("0c353ed0"),14,12))
	_summary = VBoxContainer.new()
	guide.add_child(_summary)
	_label("模型仅解释当前概念；天体大小与距离为示意。",_body,13,MUTED)
	_change_angle(_angle)
	if not _answer.is_empty(): _answer_question(_answer)

func _reset_lesson(user_action := false) -> void:
	var initial := 180.0 if _lab_mode == "day" else 0.0
	if user_action and (_playing or not is_equal_approx(_angle,initial) or not _answer.is_empty()):
		Sound.play_from(self,"reset")
	_set_playing(false)
	if _lab_mode == "year" and is_instance_valid(_year_lab):
		_change_angle(0)
		return
	_answer = ""
	_lesson_states[_lab_mode].answer = ""
	_change_angle(180 if _lab_mode == "day" else 0)
	_feedback.text = ""
	_refresh_lesson_guide()

func _set_playing(enabled: bool, user_action := false) -> void:
	if user_action and enabled != _playing: Sound.play_from(self,"toggle_on" if enabled else "toggle_off")
	_playing = enabled
	if enabled and _angle >= 360: _change_angle(0)
	if is_instance_valid(_play_button):
		_play_button.text = "Ⅱ 暂停" if enabled else ("▶ 播放自转" if _lab_mode == "day" else "▶ 播放公转")
	if is_instance_valid(_year_lab): _year_lab.update_state(_angle,_playing,progress.data.lessons.has("year"))

func _change_angle(value: float, user_action := false) -> void:
	value = clampf(value,0,360)
	_angle = value
	_lesson_states[_lab_mode].angle = value
	if _lab_mode == "year" and is_instance_valid(_year_lab):
		if value >= 360:
			var first_completion: bool = not progress.data.lessons.has("year")
			progress.complete("year")
			if user_action and first_completion: Sound.play_from(self,"complete")
		_year_lab.update_state(value,_playing,progress.data.lessons.has("year"))
		return
	_slider.set_value_no_signal(value)
	_canvas.angle = value
	_canvas.queue_redraw()
	_angle_label.text = "自转角度  %d°" % value if _lab_mode == "day" else "公转进度  %d%%" % roundi(value/360*100)
	if _lab_mode == "year":
		if is_equal_approx(value,360):
			progress.complete("year")
			_feedback.text = "已完成！地球绕太阳运行一圈，就是一次公转。"
		else:
			_feedback.text = "自转：绕自己的轴旋转。公转：绕太阳运行。"

	_refresh_lesson_guide()

func _answer_question(answer: String, user_action := false) -> void:
	var changed := _answer != answer
	var first_completion: bool = not progress.data.lessons.has("day")
	if user_action and changed:
		Sound.play_from(self,("complete" if first_completion else "correct") if answer == "地球自转" else "retry")
	_answer = answer
	_lesson_states[_lab_mode].answer = answer
	if answer == "地球自转":
		progress.complete("day")
		_feedback.text = "答对了！同一地点随地球自转，交替朝向和背向太阳。"
	else:
		_feedback.text = "再试一次：保持光照方向不变，只转动地球，观察点也会进入黑夜。"

	preload("res://scripts/ui/quiz_style.gd").feedback(_feedback,answer == "地球自转")
	_refresh_lesson_guide()

func _refresh_lesson_guide() -> void:
	if not is_instance_valid(_summary): return
	var complete: bool = (_answer == "地球自转") if _lab_mode == "day" else is_equal_approx(_angle,360)
	_guide_status.text = "✓ 实验完成" if complete else ("观察 A 点 → 回答问题" if _lab_mode == "day" else "沿轨道前进 → 回到起点")
	_guide_instructions.visible = not complete
	_feedback.visible = not complete and not _feedback.text.is_empty()
	for button in _answer_buttons:
		button.set_pressed_no_signal(str(button.get_meta("answer_text")) == _answer)
		preload("res://scripts/ui/quiz_style.gd").option(button,_answer_buttons.find(button),button.button_pressed,_answer == "地球自转")
	# Rebuild only when completion changes, keeping buttons stable during playback.
	if _summary.has_meta("complete") and _summary.get_meta("complete") == complete: return
	_summary.set_meta("complete",complete)
	_clear(_summary)
	if complete:
		_label("地球自转让同一地点交替面向和背向太阳。" if _lab_mode == "day" else "绕太阳一圈约为一年；自转和公转是不同运动。",_summary,16,MUTED)
		_button("下一站：公转与一年" if _lab_mode == "day" else "下一站：四季与地轴",_summary,func() -> void: _open_lesson("year") if _lab_mode == "day" else _open_lesson("seasons"),true,"navigate")
		_button("查看学习进度",_summary,func() -> void: navigate("progress"),false,"navigate")

func _compare() -> void:
	_body.add_theme_constant_override("separation",8)
	_comparison_heading = BoxContainer.new()
	_comparison_heading.vertical = _compact
	_comparison_heading.add_theme_constant_override("separation",16)
	_body.add_child(_comparison_heading)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_constant_override("separation",2)
	_comparison_heading.add_child(heading)
	_label("世界的大小，放在一起看" if _compare_mode == "size" else "比较不同世界",heading,32)
	_label({"size":"同一比例，比较两颗行星的平均直径","distance":"同一距离比例，观察各行星轨道半长轴","rotation":"比较恒星自转周期，分清时长与方向","period":"比较恒星公转周期，看看一年有多长"}[_compare_mode],heading,16,MUTED)
	var mode_panel := PanelContainer.new()
	mode_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mode_panel.add_theme_stylebox_override("panel",_style(Color("071421dd"),18,0))
	_comparison_heading.add_child(mode_panel)
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation",0)
	mode_panel.add_child(modes)
	for entry in [["大小","size"],["距离","distance"],["自转","rotation"],["公转","period"]]:
		var mode: String = entry[1]
		var button := _button(entry[0],modes,func() -> void: _compare_mode_from_ui(mode),_compare_mode == mode)
		button.custom_minimum_size.x = 80
		if _compare_mode == mode:
			CompareControls.button(button,"active")
		else:
			for state in ["normal","pressed"]: button.add_theme_stylebox_override(state,_style(Color.TRANSPARENT,16,10))
			button.add_theme_stylebox_override("hover",CompareControls.skin("selector",true))
		if mode != "period":
			var separator := VSeparator.new()
			separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
			separator.add_theme_constant_override("separation",0)
			var line := StyleBoxLine.new()
			line.color = Color("263e54")
			line.vertical = true
			line.grow_begin = -8
			line.grow_end = -8
			separator.add_theme_stylebox_override("separator",line)
			modes.add_child(separator)
	var columns := _columns()
	columns.add_theme_constant_override("separation",12)
	var stage := _panel_content(columns)
	stage.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.get_parent().add_theme_stylebox_override("panel",_style(Color("06132288"),18,12))
	stage.add_theme_constant_override("separation",0)
	var choices := HBoxContainer.new()
	choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation",8 if _compact else 16)
	stage.add_child(choices)
	for slot in range(2):
		var picker := OptionButton.new()
		picker.custom_minimum_size = Vector2(142 if _compact else 154,40)
		picker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for planet in catalog: picker.add_item(planet.name)
		for state in ["normal","hover","pressed"]:
			var picker_skin := CompareControls.skin("selector",state != "normal")
			picker_skin.content_margin_left = 56
			picker_skin.content_margin_right = 43
			picker.add_theme_stylebox_override(state,picker_skin)
		var blank := Image.create(1,1,false,Image.FORMAT_RGBA8)
		picker.add_theme_icon_override("arrow",ImageTexture.create_from_image(blank))
		picker.add_theme_constant_override("arrow_margin",0)
		picker.add_theme_constant_override("h_separation",0)
		var decoration := PickerDecoration.new()
		decoration.slot = "A" if slot == 0 else "B"
		picker.add_child(decoration)
		var popup := picker.get_popup()
		CompareControls.popup(popup)
		popup.about_to_popup.connect(func(): Sound.play_from(self,"tap"))
		picker.select(_compare_first if slot == 0 else _compare_second)
		var which := slot
		picker.item_selected.connect(func(i: int) -> void: _choose_comparison(which,i,true))
		choices.add_child(picker)
		_pickers.append(picker)
		if slot == 0:
			var swap := _button("⇄",choices,func(): _swap_comparison(true))
			swap.tooltip_text = "交换 A 与 B"
			swap.add_theme_font_size_override("font_size",30)
			swap.add_theme_color_override("font_color",Color("a6c9f1"))
			swap.add_theme_stylebox_override("normal",_style(Color.TRANSPARENT,12,8))
	_canvas = LearningCanvas.new()
	_canvas.mode = _compare_mode
	_canvas.catalog = catalog
	_canvas.first = _compare_first
	_canvas.second = _compare_second
	_canvas.framed = false
	_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(_canvas)
	_compare_info = _panel_content(columns,360)
	_compare_info.add_theme_constant_override("separation",2)
	_compare_info.get_parent().add_theme_stylebox_override("panel",_style(PANEL,18,14))
	_update_comparison()
	var dock := _panel_content(_body)
	dock.get_parent().add_theme_stylebox_override("panel",_style(Color("091827d9"),18,6))
	dock.add_theme_constant_override("separation",2)
	var dock_header := HFlowContainer.new()
	dock.add_child(dock_header)
	var dock_title := _label("选择比较对象",dock_header,20)
	dock_title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var slot_panel := PanelContainer.new()
	slot_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot_panel.add_theme_stylebox_override("panel",_style(Color("081523"),24,0))
	dock_header.add_child(slot_panel)
	var slot_group := HBoxContainer.new()
	slot_group.add_theme_constant_override("separation",0)
	slot_panel.add_child(slot_group)
	for slot in range(2):
		var target_slot := slot
		var button := _button("A" if slot == 0 else "B",slot_group,func() -> void: _select_comparison_slot(target_slot,true))
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(54,44)
		button.add_theme_stylebox_override("normal",_style(Color.TRANSPARENT,22,6))
		button.add_theme_stylebox_override("pressed",CompareControls.skin("active"))
		button.add_theme_stylebox_override("hover_pressed",CompareControls.skin("active",true))
		button.add_theme_stylebox_override("hover",CompareControls.skin("selector",true))
		button.add_theme_color_override("font_pressed_color",INK)
		_slot_buttons.append(button)
	_comparison_hint = _label("",dock_header,15,MUTED)
	_comparison_hint.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_planet_grid = GridContainer.new()
	_planet_grid.columns = 4 if _compact else 8
	_planet_grid.add_theme_constant_override("h_separation",8)
	dock.add_child(_planet_grid)
	for i in range(catalog.size()):
		var index := i
		var button := _button("",_planet_grid,func() -> void: _choose_comparison(_compare_slot,index,true))
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(74,80)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.add_theme_constant_override("separation",0)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(content)
		var thumbnail := TextureRect.new()
		thumbnail.texture = load("res://assets/thumbnails/"+catalog[i].id+".png")
		thumbnail.custom_minimum_size.y = 51
		thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(thumbnail)
		var title := _label(catalog[i].name,content,16)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var overlay := SelectionOverlay.new()
		overlay.name = "SelectionOverlay"
		button.add_child(overlay)
		overlay.comparison = true
		_comparison_buttons.append(button)
	_select_comparison_slot(_compare_slot)
	var note := _label("缩略图仅用于选择，不代表真实大小比例",dock,12,MUTED)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _select_comparison_slot(slot: int, user_action := false) -> void:
	if user_action and slot != _compare_slot: Sound.play_from(self,"select")
	_compare_slot = slot
	if is_instance_valid(_comparison_hint): _comparison_hint.text = "点击行星，替换 "+("A" if slot == 0 else "B")
	for i in range(_slot_buttons.size()): _slot_buttons[i].set_pressed_no_signal(i == slot)
	for i in range(_comparison_buttons.size()):
		var is_a := i == _compare_first
		var is_b := i == _compare_second
		_comparison_buttons[i].set_pressed_no_signal(is_a or is_b)
		_comparison_buttons[i].add_theme_stylebox_override("normal",_style(Color.TRANSPARENT,12,2))
		var chosen := _style(Color.TRANSPARENT,12,2)
		_comparison_buttons[i].add_theme_stylebox_override("pressed",chosen)
		_comparison_buttons[i].get_node("SelectionOverlay").update_state(false,"AB" if i == _compare_first and i == _compare_second else ("A" if i == _compare_first else ("B" if i == _compare_second else "")))
		_comparison_buttons[i].tooltip_text = "选择"+catalog[i].name+"作为对象"+("A" if slot == 0 else "B")

func _choose_comparison(slot: int, index: int, user_action := false) -> void:
	if user_action and index != (_compare_first if slot == 0 else _compare_second): Sound.play_from(self,"select")
	if slot == 0: _compare_first = index
	else: _compare_second = index
	_canvas.first = _compare_first
	_canvas.second = _compare_second
	_canvas.queue_redraw()
	_pickers[0].select(_compare_first)
	_pickers[1].select(_compare_second)
	_select_comparison_slot(slot)
	_update_comparison()

func _swap_comparison(user_action := false) -> void:
	if user_action and _compare_first != _compare_second: Sound.play_from(self,"swap")
	var previous := _compare_first
	var active_slot := _compare_slot
	_compare_first = _compare_second
	_choose_comparison(1,previous)
	_select_comparison_slot(active_slot)

func _update_comparison() -> void:
	_clear(_compare_info)
	var a: Dictionary = catalog[_compare_first]
	var b: Dictionary = catalog[_compare_second]
	_label(a.id.to_upper()+" / "+b.id.to_upper(),_compare_info,14,MUTED)
	if _compare_mode == "size":
		var ratio: float = b.radius_km/a.radius_km
		_label(b.name+"有多大？",_compare_info,26)
		var value := HBoxContainer.new()
		_compare_info.add_child(value)
		var number := _label("%.2f" % ratio,value,60,ACCENT)
		number.autowrap_mode = TextServer.AUTOWRAP_OFF
		number.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var unit := _label("倍",value,30,ACCENT)
		unit.autowrap_mode = TextServer.AUTOWRAP_OFF
		unit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		unit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_label(b.name+"的平均直径约为"+a.name+"的 %.2f 倍" % ratio,_compare_info,17)
		_compare_info.add_child(HSeparator.new())
		for p in [a,b]:
			var row := HBoxContainer.new()
			_compare_info.add_child(row)
			_label(p.name+"平均半径",row,16,MUTED)
			var measurement := _label(_grouped_number(p.radius_km)+" km",row,18)
			measurement.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_compare_info.add_child(spacer)
		var info := _label("ⓘ  直径比不等于体积比",_compare_info,16,MUTED)
		info.add_theme_stylebox_override("normal",_style(Color("102637dd"),12,6))
	elif _compare_mode in ["rotation","period"]:
		var values: Vector2 = _canvas.period_values()
		_label("转一圈，要多久？",_compare_info,24)
		_label("%.2f 倍" % (values.y/values.x),_compare_info,54,ACCENT)
		_label(b.name+"周期 / "+a.name+"周期",_compare_info,18)
		_label("恒星自转周期：相对恒星转一圈，不等于昼夜周期。" if _compare_mode == "rotation" else "公转：相对恒星绕太阳一圈。这里统一换算为地球日。",_compare_info,17,MUTED)
		if _compare_mode == "rotation":
			_label(a.name+"："+("逆行" if a.rotation_days < 0 else "顺行")+" · "+b.name+"："+("逆行" if b.rotation_days < 0 else "顺行"),_compare_info,17,ACCENT)
		_label("条越长，自转周期越长；气态行星采用代表值。" if _compare_mode == "rotation" else "条越长，完成公转一圈所需时间越长。",_compare_info,15,MUTED)
	else:
		_label("离太阳有多远？",_compare_info,27)
		_label("au · 天文单位",_compare_info,24,ACCENT)
		_label("横线采用相同距离比例，表示各行星轨道半长轴。\n\n圆点只标记位置，不代表行星直径；它也不是某一天的实时日地距离。",_compare_info,18,MUTED)
	progress.record_comparison(Tasks.comparison_key(_compare_mode,a.id,b.id))
	var exchange := _button("⇄  交换比较对象",_compare_info,func(): _swap_comparison(true),true)
	CompareControls.button(exchange,"primary")
	var back := _button("←  返回探索",_compare_info,_return_to_explore)
	CompareControls.button(back,"secondary")
	var source := _label("数据来源 NASA / JPL",_compare_info,12,MUTED)
	source.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _window_resized() -> void:
	var physical := get_window().size
	var portrait := physical.x < physical.y
	var landscape_width := maxi(1280,roundi(800.0*physical.x/maxi(physical.y,1)))
	var width := (720 if physical.x >= 700 else 440) if portrait else landscape_width
	get_window().content_scale_size = Vector2i(width,roundi(float(width)*physical.y/maxi(physical.x,1)))
	call_deferred("_responsive")

func _responsive() -> void:
	_compact = size.x/maxf(size.y,1) < 1.1
	if is_instance_valid(_header):
		var narrow := size.x < 900
		var sound_parent: Node = _brand_row if narrow else _header
		if is_instance_valid(_sound_button) and _sound_button.get_parent() != sound_parent:
			_sound_button.reparent(sound_parent)
		_header.vertical = narrow
		_navigation.add_theme_constant_override("h_separation",4 if narrow else 12)
		_brand_button.add_theme_font_size_override("font_size",24 if narrow else 26)
		for nav in _nav_buttons.values():
			nav.custom_minimum_size.x = 64 if narrow else 76
			nav.add_theme_font_size_override("font_size",16 if narrow else 19)
			for state in ["normal","pressed"]:
				var skin := nav.get_theme_stylebox(state).duplicate() as StyleBoxFlat
				skin.content_margin_left = 6 if narrow else 12
				skin.content_margin_right = 6 if narrow else 12
				skin.content_margin_top = 8 if narrow else 12
				skin.content_margin_bottom = 8 if narrow else 12
				nav.add_theme_stylebox_override(state,skin)
	if is_instance_valid(_split):
		_split.vertical = _compact
	if is_instance_valid(_cards): _cards.vertical = _compact
	if is_instance_valid(_home_progress): _home_progress.vertical = _compact
	if is_instance_valid(_explore_heading): _explore_heading.vertical = _compact
	if is_instance_valid(_comparison_heading): _comparison_heading.vertical = _compact
	if is_instance_valid(_planet_grid):
		_planet_grid.columns = 4 if _compact else 8
	if is_instance_valid(_stage):
		_stage.custom_minimum_size.y = 320 if _compact else 340
	if is_instance_valid(_title):
		_title.add_theme_font_size_override("font_size",28 if _compact else 30)

func _process(delta: float) -> void:
	if page == "lab" and _playing and _foreground and is_instance_valid(_slider):
		_change_angle(minf(360,_angle+delta*30),true)
		if _angle >= 360: _set_playing(false)
	_timer += delta
	if _timer > .25 and is_instance_valid(_time_label) and is_instance_valid(world):
		_timer = 0
		_time_label.text = "已模拟 %.1f 天 · 任意初始相位" % world.days

func _show_sources() -> void:
	if not _sources.visible: Sound.play_from(self,"tap")
	_sources.present()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and (page != "home" or not _history.is_empty()):
		_go_back()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _reset_dialog and _reset_dialog.visible: _reset_dialog.dismiss()
		elif _settings and _settings.visible: _settings.hide()
		elif _sources and _sources.visible: _sources.dismiss()
		elif page != "home" or not _history.is_empty(): _go_back()
		else: get_tree().quit()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_RESUMED]:
		_activity.handle_notification(what)
		_foreground = _activity.is_active()
		audio.set_foreground(_foreground)
		if not _foreground: _set_playing(false)
		if is_instance_valid(world):
			world.set_process(_foreground and page == "explore")
			world.camera.set_process(_foreground and page == "explore")
			world.camera.cancel_gestures()
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if _foreground and page == "explore" else SubViewport.UPDATE_DISABLED

func _exit_tree() -> void:
	if is_instance_valid(viewport) and viewport.get_parent() == null:
		viewport.free()

func _build_settings() -> void:
	_settings = AcceptDialog.new()
	_settings.title = "画质设置"
	_settings.add_theme_stylebox_override("panel",_style(PANEL,16,16))
	_settings.add_theme_stylebox_override("embedded_border",_style(PANEL,16,16))
	var content := VBoxContainer.new()
	content.custom_minimum_size.x = 290
	_settings.add_child(content)
	_quality_picker = OptionButton.new()
	_quality_picker.custom_minimum_size.y = 52
	for preset in quality.PRESETS: _quality_picker.add_item(preset)
	_quality_picker.select(quality.level)
	_quality_picker.item_selected.connect(_set_quality)
	content.add_child(_quality_picker)
	_quality_note = _label("",content,17,MUTED)
	_label("流畅：关闭抗锯齿、云层和光晕\n均衡：2× 抗锯齿，保留云层与大气\n高清：4× 抗锯齿，增加太阳光晕",content,16,MUTED)
	_label("设置立即生效并保存在本机。",content,16,MUTED)
	_button("资料与模型说明",content,func() -> void: _settings.hide(); _show_sources())
	for child in content.get_children():
		if child is Label: child.custom_minimum_size.x = 290
	add_child(_settings)

func _show_settings() -> void:
	_quality_note.text = "当前画质："+quality.PRESETS[quality.level]
	_settings.popup_centered(Vector2i(mini(int(size.x)-40,500),300))

func _set_quality(level: int) -> void:
	quality.set_level(level)
	_quality_picker.select(quality.level)
	_quality_note.text = "当前画质："+quality.PRESETS[quality.level]+("\n"+quality.error_message if not quality.error_message.is_empty() else "")
	_apply_quality()

func _apply_quality() -> void:
	if is_instance_valid(viewport): viewport.msaa_3d = quality.msaa()
	if is_instance_valid(world): world.set_quality(quality.level)

func _compare_with_earth() -> void:
	_compare_first = 2
	_compare_second = 4 if selected_index == 2 else selected_index
	_compare_mode = "size"
	navigate("compare")

func _knowledge_page() -> void:
	var p: Dictionary = catalog[selected_index]
	var facts: Dictionary = knowledge[p.id]
	_label(p.name+" · 知识卡",_body,32)
	var columns := _columns()
	var overview := _panel_content(columns,280)
	var thumbnail := TextureRect.new()
	thumbnail.texture = load("res://assets/thumbnails/"+p.id+".png")
	thumbnail.custom_minimum_size.y = 180
	thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overview.add_child(thumbnail)
	_label(p.kind,overview,18,ACCENT)
	_label(facts.title,overview,23)
	_button("与木星比较" if p.id == "earth" else "与地球比较",overview,_compare_with_earth,true,"navigate")
	_button("返回行星探索",overview,_return_to_explore)
	var content := _panel_content(columns)
	content.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label("先记住这一点",content,24)
	_label(facts.feature,content,21)
	for item in [["内部结构","structure"],["大气环境","atmosphere"],["卫星世界","moons"]]:
		var text := _label(facts[item[1]],content,18,MUTED)
		text.visible = false
		var button := _button("展开 · "+item[0],content,func() -> void: pass)
		content.move_child(button,text.get_index())
		button.toggle_mode = true
		var title: String = item[0]
		button.toggled.connect(func(open: bool) -> void:
			text.visible = open
			button.text = ("收起 · " if open else "展开 · ")+title
			Sound.play_from(self,"toggle_on" if open else "toggle_off")
		)
	_label("来源：NASA Science · 核对于 2026-10-08",content,14,MUTED)
	var source := LinkButton.new()
	source.text = "查看 NASA 原文（联网）"
	source.custom_minimum_size.y = 48
	source.pressed.connect(func() -> void: Sound.play_from(self,"navigate"); OS.shell_open(facts.source))
	content.add_child(source)

func _progress_page() -> void:
	var screen := preload("res://scripts/ui/progress_page.gd").new()
	screen.name = "ProgressPage"
	screen.data = progress.data.duplicate(true)
	screen.catalog = catalog
	screen.task_feedback = _task_feedback.duplicate()
	screen.planet_requested.connect(func(index): navigate("explore"); world.select_body(index,true))
	screen.lesson_requested.connect(_open_lesson)
	screen.task_requested.connect(_continue_task)
	screen.answer_requested.connect(func(index,answer): _answer_task(index,answer,true))
	screen.sources_requested.connect(_show_sources)
	screen.reset_requested.connect(func(): _reset_dialog.popup_centered(Vector2i(mini(int(size.x)-40,460),230)))
	_body.add_child(screen)
	if not progress.error_message.is_empty(): _label(progress.error_message,_body,16,MUTED)

func _continue_task(index: int) -> void:
	var task: Dictionary = Tasks.TASKS[index]
	for id in task.bodies:
		if not progress.data.visited.has(id):
			for i in range(catalog.size()):
				if catalog[i].id == id:
					navigate("explore")
					world.select_body(i,true)
					return
	_compare_first = task.pair[0]
	_compare_second = task.pair[1]
	_compare_mode = task.mode
	navigate("compare")

func _answer_task(index: int, answer: int, user_action := false) -> void:
	var task: Dictionary = Tasks.TASKS[index]
	if not Tasks.ready_for_quiz(task,progress.data): return
	var first_completion: bool = not progress.data.tasks.has(task.id)
	if user_action and first_completion and _task_answers.get(task.id,-1) != answer:
		Sound.play_from(self,"complete" if answer == task.correct else "retry")
	_task_answers[task.id] = answer
	if answer == task.correct:
		progress.complete_task(task.id)
		_task_feedback.erase(task.id)
	else:
		_task_feedback[task.id] = "再想一想："+("类地行星有岩石地表。" if index == 0 else "木星和土星主要由氢和氦组成。")
	navigate("progress")
	_body.get_node("ProgressPage").open_quiz(index,answer,false)

func _build_reset_dialog() -> void:
	_reset_dialog = preload("res://scripts/ui/confirmation_overlay.gd").new()
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	layer.add_child(_reset_dialog)
	_reset_dialog.confirmed.connect(func(): _reset_learning(true))

func _reset_learning(user_action := false) -> void:
	progress.reset_progress()
	if user_action and progress.error_message.is_empty(): Sound.play_from(self,"reset")
	_task_answers.clear()
	_lesson_states = {"day":{"angle":180.0,"answer":""},"year":{"angle":0.0,"answer":""},"seasons":{"angle":90.0,"answer":""}}
	_lab_mode = "day"
	_angle = 180
	_answer = ""
	_task_feedback.clear()
	_scroll_positions.clear()
	_history.clear()
	selected_index = 2
	if is_instance_valid(world):
		world.selected_index = 2
		world.region = "all"
	_scene_opened = false
	navigate("progress",false)

func _lesson_from_ui(mode: String) -> void:
	if mode == _lab_mode: return
	Sound.play_from(self,"select")
	_open_lesson(mode)

func _compare_mode_from_ui(mode: String) -> void:
	if mode == _compare_mode: return
	Sound.play_from(self,"select")
	_compare_mode = mode
	navigate("compare")

func _choose_region(region: String) -> void:
	if world.region == region and world.camera.follow_node == null: return
	world.set_region(region)
	Sound.play_from(self,"select")

func _choose_speed(index: int) -> void:
	var value: float = [1.0,12.0,120.0,365.0][index]
	if is_equal_approx(value,world.days_per_second): return
	world.days_per_second = value
	Sound.play_from(self,"select")

func _return_to_explore() -> void:
	# An explicit return consumes the route instead of adding the page being left.
	var previous := _history.rfind("explore")
	if previous >= 0: _history.resize(previous)
	Sound.play_from(self,"back")
	navigate("explore",false)

func _select_planet(index: int, close_up: bool, cue := "") -> void:
	if index == selected_index and (not close_up or world.camera.follow_node == world.bodies[index]):
		# Toggle buttons must keep the current selection even when the camera stays put.
		if index < _planet_buttons.size(): _planet_buttons[index].set_pressed_no_signal(true)
		if not progress.data.visited.has(catalog[index].id):
			progress.visit(catalog[index].id)
			Sound.play_from(self,"select")
		return
	world.select_body(index,close_up)
	Sound.play_from(self,cue if not cue.is_empty() else ("focus" if close_up else "select"))

func _zoom_from_ui(factor: float) -> void:
	var before: float = world.camera.distance
	world.camera.zoom_by(factor)
	if not is_equal_approx(before,world.camera.distance): Sound.play_from(self,"adjust")

func _camera_signature() -> Array:
	return [world.camera.yaw,world.camera.pitch,world.camera.distance,world.camera.follow_node]

func _overview_from_ui() -> void:
	var before := _camera_signature()
	world.reset_view()
	if before != _camera_signature(): Sound.play_from(self,"back")

func _restore_view_from_ui() -> void:
	var before := _camera_signature()
	world.camera.restore_view()
	if before != _camera_signature(): Sound.play_from(self,"reset")

func _bind_year_completion(slider: HSlider) -> void:
	slider.drag_started.connect(func(): slider.set_meta("year_done_before",progress.data.lessons.has("year")))
	slider.drag_ended.connect(func(changed: bool):
		if changed and not slider.get_meta("year_done_before",true) and progress.data.lessons.has("year"):
			Sound.play_from(self,"complete")
	)
	slider.gui_input.connect(func(event: InputEvent):
		if event is InputEventKey and event.pressed and not progress.data.lessons.has("year"):
			_year_key_completion.call_deferred(weakref(slider),slider.value)
	)

func _year_key_completion(reference: WeakRef, before: float) -> void:
	var slider: HSlider = reference.get_ref() as HSlider
	if is_instance_valid(slider) and slider.is_inside_tree() and not is_equal_approx(before,slider.value) and progress.data.lessons.has("year"):
		Sound.play_from(self,"complete")
