extends "res://scripts/ui/quiz_overlay.gd"
signal confirmed
func _ready() -> void:
	super._ready()
	var title := Label.new()
	title.text = "重置学习记录？"
	title.add_theme_font_size_override("font_size",26)
	content.add_child(title)
	var explanation := Label.new()
	explanation.text = "将清除本机的行星足迹、实验和任务进度。\n此操作无法撤销。"
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	explanation.add_theme_font_size_override("font_size",18)
	content.add_child(explanation)
	for caption in ["保留记录","确认重置"]:
		var action := Button.new()
		action.text = caption
		action.custom_minimum_size.y = 48
		for state in ["normal","hover","pressed","focus"]:
			var skin := Style.box(Color("123345") if caption == "保留记录" else Color("271f19"),12,12)
			skin.border_color = Color("68dcec") if caption == "保留记录" else Color("aa8751")
			if state == "focus": skin.set_border_width_all(2)
			action.add_theme_stylebox_override(state,skin)
		content.add_child(action)
		if caption == "保留记录": action.pressed.connect(dismiss)
		else:
			action.add_theme_color_override("font_color",Color("ffcf92"))
			action.pressed.connect(func(): dismiss(); confirmed.emit())
func popup_centered(_requested_size := Vector2i.ZERO) -> void:
	if not visible: Audio.play_from(self, "tap")
	present()
