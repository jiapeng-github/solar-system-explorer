extends VBoxContainer
signal planet_requested(index: int)
signal lesson_requested(mode: String)
signal task_requested(index: int)
signal answer_requested(index: int, answer: int)
signal reset_requested
signal sources_requested
const Style = preload("res://scripts/ui/visual_style.gd")
const Tasks = preload("res://scripts/learning_tasks.gd")
const Audio = preload("res://scripts/ui_audio.gd")
var data: Dictionary
var catalog: Array
var task_feedback: Dictionary = {}
var recommendation: Dictionary
var summary: BoxContainer
var metric_counts: Array[Label] = []
var metric_icons: Array[TextureRect] = []
var metrics: HBoxContainer
var planets: GridContainer
var experiments: BoxContainer
var tasks: BoxContainer
var heading: BoxContainer
var footer: BoxContainer
var recommended_button: Button
var planet_buttons: Array[Button] = []
var lesson_buttons: Array[Button] = []
var task_buttons: Array[Button] = []
var task_rows: Array[BoxContainer] = []
var reset_button: Button
var quiz: Control
var answer_buttons: Array[Button] = []
func label(value: String, parent: Node, font_size := 16, color := Color("e4effb")) -> Label:
	var node := Label.new()
	node.text = value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size",font_size)
	node.add_theme_color_override("font_color",color)
	parent.add_child(node)
	return node
func button(value: String, parent: Node, action: Callable, primary := false, cue := "") -> Button:
	var node := Button.new()
	# Let the scroll container distinguish taps from drags.
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	node.text = value
	node.custom_minimum_size.y = 32
	node.add_theme_font_size_override("font_size",14)
	for key in ["normal","hover","pressed","focus"]:
		var skin := Style.box(Color("48dff4") if primary else Color("041722c0"),16,6)
		skin.border_color = Color("5be5f5")
		if key in ["hover","focus"]: skin.bg_color = skin.bg_color.lightened(.15)
		node.add_theme_stylebox_override(key,skin)
		node.add_theme_color_override("font_color" if key == "normal" else "font_"+key+"_color",Color("032435") if primary else Color("72eafa"))
	node.pressed.connect(func() -> void:
		Audio.play_from(self, cue)
		action.call()
	)
	parent.add_child(node)
	return node
func panel(parent: Node, padding := 8, accented := false) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_PASS
	var skin := Style.box(Color("051725d9"),12,padding)
	skin.border_color = Color("44dcec") if accented else Color("37657f")
	frame.add_theme_stylebox_override("panel",skin)
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",5)
	frame.add_child(box)
	return box
func thumbnail(id: String, parent: Node, width: float) -> TextureRect:
	var image := TextureRect.new()
	image.texture = load("res://assets/thumbnails/"+id+".png")
	image.custom_minimum_size = Vector2(width,width)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	return image
func next_step() -> Dictionary:
	for i in range(Tasks.TASKS.size()):
		var task: Dictionary = Tasks.TASKS[i]
		if data.tasks.has(task.id): continue
		for id in task.bodies:
			if not data.visited.has(id):
				for j in range(catalog.size()):
					if catalog[j].id == id: return {"kind":"planet","index":j,"title":"继续"+task.title,"caption":"下一站："+catalog[j].name,"action":"探索"+catalog[j].name+" →","planet":id}
		if not data.comparisons.has(task.comparison): return {"kind":"task","index":i,"title":task.title,"caption":"下一步：完成指定比较","action":"进入比较 →","planet":task.bodies[0]}
		return {"kind":"quiz","index":i,"title":task.title,"caption":"下一步：回答问题，验证发现","action":"开始验证 →","planet":task.bodies[0]}
	for mode in ["day","year","seasons"]:
		if not data.lessons.has(mode): return {"kind":"lesson","mode":mode,"title":"继续互动实验","caption":{"day":"自转与昼夜","year":"公转与一年","seasons":"四季与地轴"}[mode],"action":"开始实验 →","planet":"earth"}
	return {"kind":"planet","index":2,"title":"全部学习目标已完成","caption":"再次出发，发现更多细节","action":"重访地球 →","planet":"earth"}
func activate_recommendation() -> void:
	if recommendation.kind != "quiz": Audio.play_from(self, "navigate")
	match recommendation.kind:
		"planet": planet_requested.emit(recommendation.index)
		"task": task_requested.emit(recommendation.index)
		"quiz": open_quiz(recommendation.index)
		"lesson": lesson_requested.emit(recommendation.mode)
func _ready() -> void:
	add_theme_constant_override("separation",6)
	recommendation = next_step()
	heading = BoxContainer.new()
	heading.add_theme_constant_override("separation",22)
	add_child(heading)
	var title := label("你的学习旅程",heading,34)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label("每一次探索，都让宇宙更清晰一点。",heading,16).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary = BoxContainer.new()
	summary.add_theme_constant_override("separation",10)
	add_child(summary)
	metrics = HBoxContainer.new()
	metrics.add_theme_constant_override("separation",8)
	metrics.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	metrics.size_flags_stretch_ratio = 1.4
	summary.add_child(metrics)
	for i in range(3):
		var card := panel(metrics,8)
		var metric_row := HBoxContainer.new()
		card.add_child(metric_row)
		var icon := TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var image := Image.new()
		var drawing: String = ['<ellipse cx="23" cy="23" rx="15" ry="6"/><circle cx="23" cy="23" r="11"/><path d="M23 12c-8 7-8 15 0 22m0-22c8 7 8 15 0 22"/>','<path d="M18 10h10m-8 0v12L13 34q-1 3 3 3h16q4 0 2-3l-8-12V10M18 28h12"/>','<rect x="14" y="12" width="20" height="25" rx="3"/><path d="M20 10h8v5h-8zM19 22l2 2 3-4m2 3h4M19 30h11"/>'][i]
		image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="46" height="46"><g fill="none" stroke="#69dff0" stroke-width="1.5"><circle cx="23" cy="23" r="22" stroke="#557e9c"/>'+drawing+'</g></svg>')
		icon.texture = ImageTexture.create_from_image(image)
		icon.custom_minimum_size = Vector2(38,38)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		metric_row.add_child(icon)
		metric_icons.append(icon)
		var count_label := label(["%d / 8" % data.visited.size(),"%d / 3" % data.lessons.size(),"%d / 2" % data.tasks.size()][i],metric_row,31,Color("66e8f4"))
		count_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		metric_counts.append(count_label)
		label(["已探索行星","已完成实验","已完成任务"][i],card,14)
	var next := panel(summary,8,true)
	next.get_parent().size_flags_stretch_ratio = 1.0
	var next_row := HBoxContainer.new()
	next.add_child(next_row)
	thumbnail(recommendation.planet,next_row,67)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation",2)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_row.add_child(words)
	label("推荐下一步",words,13,Color("66e8f4"))
	label(recommendation.title,words,20)
	label(recommendation.caption,words,13,Color("b4c9dc"))
	recommended_button = button(recommendation.action,next_row,activate_recommendation,true)
	recommended_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	recommended_button.custom_minimum_size.y = 44
	var planet_panel := panel(self)
	var planet_header := HBoxContainer.new()
	planet_panel.add_child(planet_header)
	label("行星足迹",planet_header,23)
	label("点击行星，继续探索 →",planet_header,13,Color("75ddeb")).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	planets = GridContainer.new()
	planets.columns = 8
	planets.add_theme_constant_override("h_separation",4)
	planet_panel.add_child(planets)
	for i in range(catalog.size()):
		var index := i
		var tile := preload("res://scripts/ui/progress_planet.gd").new()
		tile.planet_id = catalog[i].id
		tile.planet_name = catalog[i].name
		tile.visited = data.visited.has(catalog[i].id)
		tile.recommended = recommendation.kind == "planet" and recommendation.index == i and not tile.visited
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.pressed.connect(func() -> void:
			Audio.play_from(self, "navigate")
			planet_requested.emit(index)
		)
		planets.add_child(tile)
		planet_buttons.append(tile)
	var experiment_panel := panel(self,8)
	var experiment_header := HBoxContainer.new()
	experiment_panel.add_child(experiment_header)
	label("互动实验",experiment_header,23)
	label("已完成 %d / 3" % data.lessons.size(),experiment_header,14,Color("a8dce9")).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	experiments = BoxContainer.new()
	experiments.add_theme_constant_override("separation",10)
	experiment_panel.add_child(experiments)
	for entry in [["day","自转与昼夜","地球自转如何产生昼夜？"],["year","公转与一年","地球公转如何形成一年？"],["seasons","四季与地轴","地轴倾斜如何影响日照？"]]:
		var mode: String = entry[0]
		var done: bool = data.lessons.has(mode)
		var card := panel(experiments,8)
		var row := HBoxContainer.new()
		card.add_child(row)
		var illustration := preload("res://scripts/ui/progress_experiment_art.gd").new()
		illustration.mode = mode
		row.add_child(illustration)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation",4)
		row.add_child(text)
		label(entry[1],text,19)
		label(entry[2],text,12,Color("b0c5db"))
		var actions := HBoxContainer.new()
		text.add_child(actions)
		label("✓ 已完成" if done else "○ 待完成",actions,13,Color("5fe8f5") if done else Color("a8bcd4"))
		lesson_buttons.append(button("再看一次 →" if done else "开始实验 →",actions,func(): lesson_requested.emit(mode),false,"navigate"))
	var tasks_panel := panel(self,8)
	var tasks_header := HBoxContainer.new()
	tasks_panel.add_child(tasks_header)
	label("学习任务",tasks_header,23)
	label("探索 → 比较 → 验证",tasks_header,13,Color("abc1d8"))
	tasks = BoxContainer.new()
	tasks.add_theme_constant_override("separation",10)
	tasks_panel.add_child(tasks)
	for i in range(2): build_task(i)
	footer = BoxContainer.new()
	add_child(footer)
	label("↓  学习记录仅保存在本机",footer,13,Color("afc5de"))
	var sources := button("资料与模型说明",footer,func(): sources_requested.emit())
	sources.add_theme_font_size_override("font_size",13)
	sources.add_theme_stylebox_override("normal",Style.box(Color.TRANSPARENT,8,2))
	reset_button = button("↻ 重置学习记录",footer,func(): reset_requested.emit())
	reset_button.add_theme_font_size_override("font_size",13)
	reset_button.add_theme_stylebox_override("normal",Style.box(Color.TRANSPARENT,8,2))
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 30
	add_child(overlay_layer)
	quiz = preload("res://scripts/ui/quiz_overlay.gd").new()
	overlay_layer.add_child(quiz)
	resized.connect(adapt)
	adapt()
func build_task(index: int) -> void:
	var task: Dictionary = Tasks.TASKS[index]
	var count := 0
	for id in task.bodies:
		if data.visited.has(id): count += 1
	var compared: bool = data.comparisons.has(task.comparison)
	var done: bool = data.tasks.has(task.id)
	var ready := Tasks.ready_for_quiz(task,data)
	var card := panel(tasks,8)
	var row := BoxContainer.new()
	task_rows.append(row)
	card.add_child(row)
	var miniatures := HBoxContainer.new()
	miniatures.add_theme_constant_override("separation",0)
	miniatures.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(miniatures)
	for id in task.bodies: thumbnail(id,miniatures,42)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation",2)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	label("任务 0%d" % (index+1),text,11,Color("aec6db"))
	label(task.title,text,17)
	label("已探索 %d / 4 · 指定比较%s" % [count,"已完成" if compared else "待完成"],text,12,Color("b8cce0"))
	label("%s探索行星  %s比较%s  %s回答问题" % ["✓" if count == 4 else "◐" if count else "○","✓" if compared else "○","自转" if index == 0 else "大小","✓" if done else "○"],text,10,Color("6ecfdd"))
	var action := button("查看收获 →" if done else "开始验证 →" if ready else "继续任务 →" if count else "开始任务 →",row,func() -> void:
		if ready or done:
			open_quiz(index)
		else:
			Audio.play_from(self, "navigate")
			task_requested.emit(index)
	)
	action.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	task_buttons.append(action)
	if task_feedback.has(task.id): label(task_feedback[task.id],card,12,Color("ffd784"))
func open_quiz(index: int, selected_answer := -1, user_action := true) -> void:
	if user_action and not quiz.visible: Audio.play_from(self, "tap")
	for child in quiz.content.get_children():
		quiz.content.remove_child(child)
		child.queue_free()
	answer_buttons.clear()
	var box: VBoxContainer = quiz.content
	var task: Dictionary = Tasks.TASKS[index]
	var top := HBoxContainer.new()
	box.add_child(top)
	label("学习任务 0%d · 验证你的发现" % (index+1),top,15,Color("71dcea"))
	button("✕",top,quiz.dismiss).tooltip_text = "关闭答题"
	label(task.title,box,28)
	if data.tasks.has(task.id):
		var success := label("✓ 任务完成\n"+task.review,box,18)
		preload("res://scripts/ui/quiz_style.gd").feedback(success,true)
	else:
		label(task.question,box,22)
		label("选择一个答案，验证刚才的观察。",box,14,Color("abc4da"))
		for i in range(task.options.size()):
			var answer := i
			var choice := button(task.options[i],box,func(): answer_requested.emit(index,answer))
			preload("res://scripts/ui/quiz_style.gd").option(choice,i,i == selected_answer,i == task.correct)
			answer_buttons.append(choice)
		if task_feedback.has(task.id):
			var hint := label(task_feedback[task.id],box,16)
			preload("res://scripts/ui/quiz_style.gd").feedback(hint,false)
	button("完成并返回任务" if data.tasks.has(task.id) else "返回任务",box,quiz.dismiss,true)
	quiz.present()
	if not answer_buttons.is_empty(): answer_buttons[0].grab_focus()
func adapt() -> void:
	var compact := size.x < 900
	for value in metric_counts: value.add_theme_font_size_override("font_size",20 if compact else 31)
	for icon in metric_icons: icon.custom_minimum_size = Vector2(24,24) if compact else Vector2(38,38)
	heading.vertical = compact
	summary.vertical = size.x < 1100
	planets.columns = 4 if compact else 8
	experiments.vertical = compact
	tasks.vertical = size.x < 1100
	footer.vertical = compact
	for action in lesson_buttons+task_buttons: action.custom_minimum_size.y = 44 if compact else 32
	reset_button.custom_minimum_size.y = 44 if compact else 32
	for row in task_rows: row.vertical = compact
