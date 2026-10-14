extends TextureRect
var scene_view: SubViewport
var active := true
const Visual = preload("res://scripts/planet_visual.gd")
func _ready() -> void:
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var viewport := SubViewport.new()
	scene_view = viewport
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	texture = viewport.get_texture()
	var planet := Visual.create(1,Color("d8bd88"),"saturn")
	viewport.add_child(planet)
	planet.material_override.set_shader_parameter("portrait_light",true)
	var ring := Visual.ring(1)
	ring.rotation.z = .30
	ring.material_override.set_shader_parameter("portrait_light",true)
	viewport.add_child(ring)
	var camera := Camera3D.new()
	camera.position = Vector3(0,.8,4.1)
	camera.fov = 40
	viewport.add_child(camera)
	camera.look_at(Vector3.ZERO)

	resized.connect(_request_frame)
	_request_frame.call_deferred()

func _request_frame() -> void:
	if is_instance_valid(scene_view):
		scene_view.size = Vector2i(maxi(2,int(size.x)),maxi(2,int(size.y)))
		scene_view.render_target_update_mode = SubViewport.UPDATE_ONCE if active else SubViewport.UPDATE_DISABLED
		if active and not RenderingServer.frame_post_draw.is_connected(_finish_frame):
			RenderingServer.frame_post_draw.connect(_finish_frame,CONNECT_ONE_SHOT)

func set_quality(msaa: int) -> void:
	scene_view.msaa_3d = msaa
	_request_frame.call_deferred()

func set_active(enabled: bool) -> void:
	active = enabled
	_request_frame()

func _finish_frame() -> void:
	if is_instance_valid(scene_view): scene_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
