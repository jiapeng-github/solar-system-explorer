extends RefCounted
const PRESETS := ["流畅", "均衡", "高清"]
var path := "user://settings.cfg"
var level := 2
var error_message := ""

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(path) == OK:
		var value = config.get_value("graphics","quality",2)
		if value is int and value >= 0 and value < PRESETS.size(): level = value

func set_level(value: int) -> void:
	level = clampi(value,0,2)
	var config := ConfigFile.new()
	config.set_value("graphics","quality",level)
	error_message = "" if config.save(path) == OK else "设置暂未保存，重新打开后会使用原设置。"

func msaa() -> int:
	return [Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X][level]
