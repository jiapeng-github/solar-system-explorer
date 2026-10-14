extends RefCounted
const NAMES = ["三月分日","六月至日","九月分日","十二月至日"]
static func sunlight(angle: float, latitude: float, tilt: float) -> Dictionary:
	var declination := asin(sin(deg_to_rad(tilt))*sin(deg_to_rad(angle)))
	var argument := -tan(deg_to_rad(latitude))*tan(declination)
	return {"hours":24.0*acos(clampf(argument,-1,1))/PI,"altitude":90-absf(latitude-rad_to_deg(declination)),"declination":rad_to_deg(declination)}
static func defaults() -> Dictionary:
	return {"angle":90.0,"south":false,"tilt":23.4,"step":0,"answer":-1,"visited":[],"contrast":false}
static func normalized(raw: Variant) -> Dictionary:
	var result := defaults()
	if not raw is Dictionary: return result
	for key in ["angle","tilt"]:
		if raw.get(key) is float or raw.get(key) is int:
			if is_finite(float(raw[key])): result[key] = clampf(float(raw[key]),0,360) if key == "angle" else (0.0 if raw[key] == 0 else 23.4)
	if raw.get("south") is bool: result.south = raw.south
	if raw.get("contrast") is bool: result.contrast = raw.contrast
	for key in ["step","answer"]:
		if raw.get(key) is int or raw.get(key) is float: result[key] = clampi(int(raw[key]),0 if key == "step" else -1,2)
	if raw.get("visited") is Array:
		for i in raw.visited:
			if (i is int or i is float) and i in [0,1,2,3] and not result.visited.has(int(i)): result.visited.append(int(i))
	return result
static func complete(state: Dictionary) -> bool:
	return state.visited.size() == 4 and state.contrast and state.answer == 0
