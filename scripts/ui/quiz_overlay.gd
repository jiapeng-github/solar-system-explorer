extends Control
signal closed
const Style = preload("res://scripts/ui/visual_style.gd")
const Audio = preload("res://scripts/ui_audio.gd")
var card: PanelContainer
var content: VBoxContainer
var fixed_header: HBoxContainer
var scroll: ScrollContainer
var _return_focus: WeakRef
var _focus_targets: Array[Control] = []
var _redirecting_focus := false
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("010914dc")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	card = PanelContainer.new()
	var skin := Style.box(Color("071b2e"),20,22)
	skin.border_color = Color("4ba0ba")
	card.add_theme_stylebox_override("panel",skin)
	add_child(card)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation",10)
	card.add_child(layout)
	fixed_header = HBoxContainer.new()
	layout.add_child(fixed_header)
	fixed_header.hide()
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",14)
	scroll.add_child(content)
	resized.connect(arrange)
	visibility_changed.connect(func(): if visible: call_deferred("arrange"))
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	hide()
func set_heading(value: String) -> void:
	fixed_header.show()
	var title := Label.new()
	title.text = value
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size",24)
	title.add_theme_color_override("font_color",Color("e6f2ff"))
	fixed_header.add_child(title)
	var close := Button.new()
	close.text = "✕"
	close.tooltip_text = "关闭"
	close.custom_minimum_size = Vector2(44,44)
	for state in ["normal","hover","pressed","focus"]:
		var skin := Style.box(Color("0c263a"),12,8)
		skin.border_color = Color("75e6f1") if state != "normal" else Color("40677e")
		close.add_theme_stylebox_override(state,skin)
	close.pressed.connect(dismiss)
	fixed_header.add_child(close)
func arrange() -> void:
	if not is_instance_valid(card): return
	var width := minf(620,size.x-32)
	card.size.x = width
	content.custom_minimum_size.x = maxf(0,width-46)
	var header_height := fixed_header.get_combined_minimum_size().y+10 if fixed_header.visible else 0.0
	var height := minf(content.get_combined_minimum_size().y+44+header_height,size.y-40)
	card.size = Vector2(width,height)
	card.position = (size-card.size)*.5
func present() -> void:
	if not visible:
		var owner := get_viewport().gui_get_focus_owner()
		_return_focus = weakref(owner) if is_instance_valid(owner) and not is_ancestor_of(owner) else null
	show()
	_prepare_focus()
	scroll.scroll_vertical = 0
	arrange()
	call_deferred("arrange")
func dismiss() -> void:
	if not visible: return
	hide()
	Audio.play_from(self, "back")
	var previous = _return_focus.get_ref() if _return_focus != null else null
	# Answering can rebuild the entire page. Never restore a detached or queued node.
	if _can_focus(previous):
		previous.grab_focus()
	else:
		var page := get_parent()
		while page != null and not page is Control: page = page.get_parent()
		var candidates: Array[Control] = []
		if page != null: _collect_focus_targets(page,candidates)
		if not candidates.is_empty(): candidates[0].grab_focus()
	_return_focus = null
	closed.emit()
func _can_focus(node) -> bool:
	return is_instance_valid(node) and node is Control and not node.is_queued_for_deletion() and node.is_inside_tree() and node.is_visible_in_tree() and node.focus_mode != Control.FOCUS_NONE and (not node is BaseButton or not node.disabled)
func _collect_focus_targets(node: Node, targets: Array[Control], enlarge_buttons := false) -> void:
	if enlarge_buttons and node is Button:
		node.custom_minimum_size.x = maxf(node.custom_minimum_size.x,44)
		node.custom_minimum_size.y = maxf(node.custom_minimum_size.y,44)
	if _can_focus(node): targets.append(node)
	for child in node.get_children(): _collect_focus_targets(child,targets,enlarge_buttons)
func _prepare_focus() -> void:
	_focus_targets.clear()
	_collect_focus_targets(card,_focus_targets,true)
	for i in range(_focus_targets.size()):
		var control := _focus_targets[i]
		var previous := control.get_path_to(_focus_targets[posmod(i-1,_focus_targets.size())])
		var next := control.get_path_to(_focus_targets[(i+1)%_focus_targets.size()])
		control.focus_previous = previous
		control.focus_next = next
		control.focus_neighbor_top = previous
		control.focus_neighbor_left = previous
		control.focus_neighbor_bottom = next
		control.focus_neighbor_right = next
	if not _focus_targets.is_empty(): _focus_targets[0].grab_focus()
func _on_focus_changed(node: Control) -> void:
	if not visible or _redirecting_focus or (is_instance_valid(node) and is_ancestor_of(node)): return
	_redirecting_focus = true
	for target in _focus_targets:
		if _can_focus(target):
			target.grab_focus()
			break
	_redirecting_focus = false
func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()
