extends RefCounted
const SURFACE = preload("res://assets/shaders/planet.gdshader")
const ATMOSPHERE = preload("res://assets/shaders/atmosphere.gdshader")
const CLOUD_SHADER = preload("res://assets/shaders/clouds.gdshader")
const CLOUD_MAP = preload("res://assets/textures/clouds.jpg")
const RING = preload("res://assets/shaders/ring.gdshader")
const EARTH = preload("res://assets/textures/earth.png")
const MOON = preload("res://assets/textures/moon.jpg")
const MAPS = {
	"mercury": preload("res://assets/textures/mercury.jpg"),
	"venus": preload("res://assets/textures/venus_atmosphere.jpg"),
	"mars": preload("res://assets/textures/mars.jpg"),
	"jupiter": preload("res://assets/textures/jupiter.jpg"),
	"saturn": preload("res://assets/textures/saturn.jpg"),
	"uranus": preload("res://assets/textures/uranus.jpg"),
	"neptune": preload("res://assets/textures/neptune.jpg")
}

static func create(radius: float, color: Color, id: String) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2
	mesh.radial_segments = 96
	mesh.rings = 48
	body.mesh = mesh
	var mat := ShaderMaterial.new()
	mat.shader = SURFACE
	mat.set_shader_parameter("base_color",color)
	var style := 0
	if id == "earth": style = 1
	elif id in ["jupiter","saturn"]: style = 2
	elif id == "sun": style = 3
	elif id == "venus": style = 4
	elif id in ["uranus","neptune"]: style = 5
	mat.set_shader_parameter("style",style)
	if id in ["earth","moon"]:
		mat.set_shader_parameter("textured",true)
		mat.set_shader_parameter("surface_map",EARTH if id == "earth" else MOON)
	if MAPS.has(id):
		mat.set_shader_parameter("textured",true)
		mat.set_shader_parameter("surface_map",MAPS[id])
	body.material_override = mat
	if id == "earth":
		var glow := MeshInstance3D.new()
		glow.name = "Atmosphere"
		var shell := SphereMesh.new()
		shell.radius = radius*1.018
		shell.height = shell.radius*2
		shell.radial_segments = 96
		shell.rings = 48
		glow.mesh = shell
		var atmosphere := ShaderMaterial.new()
		atmosphere.shader = ATMOSPHERE
		glow.material_override = atmosphere
		body.add_child(glow)
		var clouds := MeshInstance3D.new()
		clouds.name = "Clouds"
		var cloud_sphere := SphereMesh.new()
		cloud_sphere.radius = radius*1.006
		cloud_sphere.height = cloud_sphere.radius*2
		cloud_sphere.radial_segments = 96
		cloud_sphere.rings = 48
		clouds.mesh = cloud_sphere
		var cloud_mat := ShaderMaterial.new()
		cloud_mat.shader = CLOUD_SHADER
		cloud_mat.set_shader_parameter("cloud_map",CLOUD_MAP)
		clouds.material_override = cloud_mat
		body.add_child(clouds)
	return body

static func ring(radius: float) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(192):
		var a := float(i)/192*TAU
		var b := float(i+1)/192*TAU
		for pair in [[a,0.0],[a,1.0],[b,1.0],[a,0.0],[b,1.0],[b,0.0]]:
			var r := radius*lerpf(1.35,2.25,pair[1])
			mesh.surface_set_uv(Vector2(pair[1],0))
			mesh.surface_add_vertex(Vector3(cos(pair[0])*r,0,sin(pair[0])*r))
	mesh.surface_end()
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var mat := ShaderMaterial.new()
	mat.shader = RING
	node.material_override = mat
	return node
