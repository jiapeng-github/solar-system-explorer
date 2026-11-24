extends Camera3D
signal tapped(screen_position: Vector2)
var target := Vector3.ZERO
var follow_node: Node3D
var distance := 210.0
var overview_radius := 156.0
var _overview_distance := 1.0
var _overview_size := 1.0
var _body_radius := 1.0
var max_distance := 400.0
var _focus_radius := 1.0
var _last_size := Vector2.ZERO
var min_distance := 3.0
var yaw := 0.15
var pitch := 0.85
var _dragging := false
var _start := Vector2.ZERO
var _moved := false
var _touches: Dictionary = {}
var transition_duration := 0.6
var _transition_left := 0.0
var _from_target := Vector3.ZERO
var _from_distance := 1.0
var _from_yaw := 0.0
var _from_pitch := 0.0
var _presented := false
var _display_target := Vector3.ZERO
var _display_distance := 1.0
var _display_yaw := 0.0
var _display_pitch := 0.0

func is_transitioning() -> bool:
	return _transition_left > 0.0

func _begin_transition() -> void:
	cancel_gestures()
	_from_target = _display_target
	_from_distance = maxf(_display_distance,0.01)
	_from_yaw = _display_yaw
	_from_pitch = _display_pitch
	_transition_left = transition_duration if _presented else 0.0
	_presented = true

func restore_view() -> void:
	if is_instance_valid(follow_node):
		focus_body(follow_node,_body_radius)
	else:
		reset_view()

func _interrupt_transition() -> void:
	if not is_transitioning(): return
	# Preserve the visible pose when the user takes over mid-flight.
	_transition_left = 0.0
	var offset := position-target
	distance = maxf(offset.length(),0.01)
	yaw = atan2(offset.x,offset.z)
	pitch = asin(clampf(offset.y/distance,-1,1))


func _ready() -> void:
	current = true
	far = 1500.0
	fov = 44.0
	_update_transform()

func _process(delta: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size != _last_size:
		_last_size = viewport_size
		_fit_view()
		_transition_left = 0.0
	if is_instance_valid(follow_node):
		target = follow_node.global_position + Vector3.UP*_focus_radius*.12
	_transition_left = maxf(0.0,_transition_left-delta)
	_update_transform()

func focus_body(body: Node3D, radius: float) -> void:
	_begin_transition()
	follow_node = body
	target = body.global_position
	_body_radius = radius
	_focus_radius = radius * (2.25 if body.name == "saturn" else 1.04)
	min_distance = _focus_radius * 1.65
	_fit_view()
	# View from the sunlit side, with the terminator on the right.
	var to_sun := -body.global_position
	yaw = atan2(to_sun.x,to_sun.z) + .65
	pitch = .18
	_update_transform()

func reset_view() -> void:
	_begin_transition()
	follow_node = null
	target = Vector3.ZERO
	distance = 210.0
	min_distance = 3.0
	yaw = 0.0
	pitch = .40
	_fit_view()
	_update_transform()

func _fit_view() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y,1)
	var vertical := deg_to_rad(fov)*.5
	var horizontal := atan(tan(vertical)*aspect)
	if is_instance_valid(follow_node):
		distance = maxf(_body_radius*1.06/sin(vertical),_focus_radius/sin(horizontal))*1.04
	else:
		# Solve the frustum bounds for sampled points on the orbital disk.
		var forward := Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))
		var right := Vector3(cos(yaw),0,-sin(yaw))
		var up := forward.cross(right)
		distance = 0.0
		for i in range(128):
			var angle := TAU*i/128.0
			var point := Vector3(cos(angle),0,sin(angle))*overview_radius
			distance = maxf(distance,point.dot(forward)+maxf(absf(point.dot(right))/tan(horizontal),absf(point.dot(up))/tan(vertical)))
		distance *= 1.10
		_overview_distance = distance
		_overview_size = maxf(overview_radius*2/aspect,overview_radius*2*sin(pitch))*1.04
	if is_instance_valid(follow_node):
		max_distance = distance*3.0
	else:
		min_distance = overview_radius*.3
		max_distance = distance*1.8

func zoom_by(factor: float) -> void:
	_interrupt_transition()
	distance = clampf(distance*factor,min_distance,max_distance)
	_update_transform()

func _input(event: InputEvent) -> void:
	# GUI buttons use emulated mouse clicks. The camera already handles native touches.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_interrupt_transition()
			_dragging = true
			_start = event.position
			_moved = false
		else:
			if _dragging and not _moved:
				tapped.emit(event.position)
			_dragging = false
	elif event is InputEventMouseButton and event.pressed:
		_interrupt_transition()
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance * 0.90, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance * 1.1, min_distance, max_distance)
	elif event is InputEventMagnifyGesture:
		zoom_by(1.0/maxf(event.factor,.01))
	elif event is InputEventMouseMotion and _dragging:
		if event.position.distance_to(_start) > 7:
			_moved = true
		_rotate(event.relative)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_interrupt_transition()
			_touches[event.index] = event.position
			if _touches.size() == 1:
				_start = event.position
				_moved = false
			else:
				_moved = true
		else:
			if _touches.size() == 1 and _touches.has(event.index) and not _moved:
				tapped.emit(event.position)
			_touches.erase(event.index)
	elif event is InputEventScreenDrag and _touches.has(event.index):
		if event.position.distance_to(_start) > 7:
			_moved = true
		if _touches.size() == 1:
			_rotate(event.relative)
		elif _touches.size() == 2:
			var keys := _touches.keys()
			var before: float = (_touches[keys[0]] as Vector2).distance_to(_touches[keys[1]])
			_touches[event.index] = event.position
			var after: float = (_touches[keys[0]] as Vector2).distance_to(_touches[keys[1]])
			if after > 2:
				distance = clampf(distance * before / after, min_distance, max_distance)
		_touches[event.index] = event.position
	_update_transform()

func _rotate(delta: Vector2) -> void:
	yaw -= delta.x * 0.006
	pitch = clampf(pitch + delta.y * 0.006, -1.35, 1.40)

func cancel_gestures() -> void:
	_dragging = false
	_touches.clear()

func _update_transform() -> void:
	projection = Camera3D.PROJECTION_PERSPECTIVE if is_instance_valid(follow_node) else Camera3D.PROJECTION_ORTHOGONAL
	if not is_instance_valid(follow_node): size = maxf(1.0,_overview_size*distance/maxf(_overview_distance,1.0))
	var weight := 1.0
	if is_transitioning():
		var t := 1.0-_transition_left/maxf(transition_duration,.001)
		weight = t*t*(3.0-2.0*t)
	_display_target = _from_target.lerp(target,weight) if is_transitioning() else target
	_display_distance = exp(lerpf(log(_from_distance),log(maxf(distance,.01)),weight)) if is_transitioning() else distance
	_display_yaw = lerp_angle(_from_yaw,yaw,weight) if is_transitioning() else yaw
	_display_pitch = lerpf(_from_pitch,pitch,weight) if is_transitioning() else pitch
	position = _display_target + Vector3(sin(_display_yaw)*cos(_display_pitch),sin(_display_pitch),cos(_display_yaw)*cos(_display_pitch))*_display_distance
	look_at(_display_target, Vector3.UP)
