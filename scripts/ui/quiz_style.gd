extends RefCounted
const Style = preload("res://scripts/ui/visual_style.gd")
static func option(node: Button, index: int, selected := false, correct := false) -> void:
	if not node.has_meta("answer_text"): node.set_meta("answer_text",node.text)
	node.text = ("✓  " if selected and correct else "↻  " if selected else ["A  ","B  ","C  "][index])+str(node.get_meta("answer_text"))
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.custom_minimum_size.y = 54
	node.add_theme_font_size_override("font_size",17)
	var accent := Color("62e6f5") if not selected or correct else Color("ffd38a")
	for key in ["normal","hover","pressed","focus"]:
		var skin := Style.box(Color("123747") if selected else Color("0a2033"),12,12)
		skin.border_color = accent if selected or key != "normal" else Color("416079")
		if key == "hover": skin.bg_color = skin.bg_color.lightened(.08)
		node.add_theme_stylebox_override(key,skin)
		node.add_theme_color_override("font_color" if key == "normal" else "font_"+key+"_color",accent if selected else Color("e5f1ff"))
static func feedback(node: Label, correct: bool) -> void:
	var skin := Style.box(Color("10333b") if correct else Color("342b20"),12,12)
	skin.border_color = Color("60dce8") if correct else Color("b99458")
	node.add_theme_stylebox_override("normal",skin)
	node.add_theme_color_override("font_color",Color("8ceaf2") if correct else Color("ffdb9d"))
	node.add_theme_font_size_override("font_size",16)
