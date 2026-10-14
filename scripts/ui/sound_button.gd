extends Button
## Compact global preference control; the surrounding header handles placement.
const Style := preload("res://scripts/ui/visual_style.gd")
var service: Node

func setup(audio_service: Node) -> void:
	if is_instance_valid(service) and service.enabled_changed.is_connected(_update_state):
		service.enabled_changed.disconnect(_update_state)
	service = audio_service
	service.enabled_changed.connect(_update_state)
	_update_state(service.enabled)

func _ready() -> void:
	custom_minimum_size = Vector2(44, 44)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL
	add_theme_stylebox_override("normal", Style.box(Color(0, 0, 0, 0), 12, 0))
	add_theme_stylebox_override("hover", Style.box(Color("122f43"), 12, 0))
	add_theme_stylebox_override("pressed", Style.box(Color("1c4055"), 12, 0))
	var focus_box := Style.box(Color(0, 0, 0, 0), 12, 0)
	focus_box.border_color = Style.ACCENT
	focus_box.set_border_width_all(2)
	add_theme_stylebox_override("focus", focus_box)
	pressed.connect(func() -> void:
		if is_instance_valid(service): service.set_enabled(not service.enabled)
	)
	resized.connect(queue_redraw)

func _update_state(is_enabled: bool) -> void:
	tooltip_text = "声音开启 · 点击静音" if is_enabled else "已静音 · 点击开启声音"
	accessibility_name = "声音开启" if is_enabled else "已静音"
	accessibility_description = "切换背景音乐和界面音效，偏好保存在本机。"
	queue_redraw()

func _draw() -> void:
	var is_enabled: bool = is_instance_valid(service) and service.enabled
	var color := Color("70e4f5") if is_enabled else Color("91a5b9")
	var center := size * 0.5
	var shape := PackedVector2Array([
		center + Vector2(-12, -4), center + Vector2(-7, -4),
		center + Vector2(-1, -9), center + Vector2(-1, 9),
		center + Vector2(-7, 4), center + Vector2(-12, 4),
		center + Vector2(-12, -4),
	])
	draw_polyline(shape, color, 1.8, true)
	if is_enabled:
		draw_arc(center + Vector2(-1, 0), 7, -PI * 0.29, PI * 0.29, 18, color, 1.8, true)
		draw_arc(center + Vector2(-1, 0), 12, -PI * 0.29, PI * 0.29, 24, color, 1.8, true)
	else:
		draw_line(center + Vector2(5, -4), center + Vector2(12, 4), color, 1.8, true)
		draw_line(center + Vector2(5, 4), center + Vector2(12, -4), color, 1.8, true)
