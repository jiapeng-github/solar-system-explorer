extends ColorRect
const Visual = preload("res://scripts/planet_visual.gd")
var _key := ""
func configure(id: String, polar := false) -> void:
	var key := id+str(polar)
	if key == _key: return
	_key = key
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/planet_disc.gdshader")
	mat.set_shader_parameter("surface_map",Visual.EARTH if id == "earth" else Visual.MAPS.get(id,Visual.MOON))
	mat.set_shader_parameter("clouds",Visual.CLOUD_MAP)
	mat.set_shader_parameter("earth",id == "earth")
	mat.set_shader_parameter("solar",id == "sun")
	mat.set_shader_parameter("polar",polar)
	material = mat
