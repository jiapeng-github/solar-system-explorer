extends RefCounted
static func load_planets() -> Array:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/planets.json"))
	if not parsed is Dictionary or not parsed.get("planets") is Array:
		push_error("Invalid celestial catalog")
		return []
	var seen := {}
	for entry in parsed.planets:
		if not entry is Dictionary:
			return []
		for key in ["id", "name", "radius_km", "period_years", "a_au", "eccentricity", "display_radius", "display_a", "phase", "color", "rotation_days", "kind", "description"]:
			if not entry.has(key):
				push_error("Missing catalog field: " + key)
				return []
		if seen.has(entry.id) or float(entry.radius_km) <= 0 or float(entry.period_years) <= 0 or float(entry.eccentricity) < 0 or float(entry.eccentricity) >= 1:
			push_error("Invalid catalog values")
			return []
		seen[entry.id] = true
	return parsed.planets

static func orbital_position(a: float, eccentricity: float, mean_anomaly: float) -> Vector3:
	var m := fposmod(mean_anomaly, TAU)
	var eccentric_anomaly := m
	for step in range(12):
		var correction := (eccentric_anomaly - eccentricity * sin(eccentric_anomaly) - m) / (1.0 - eccentricity * cos(eccentric_anomaly))
		eccentric_anomaly -= correction
		if absf(correction) < 1e-10:
			break
	return Vector3(a * (cos(eccentric_anomaly) - eccentricity), 0, -a * sqrt(1.0 - eccentricity * eccentricity) * sin(eccentric_anomaly))

static func mean_anomaly(days: float, period_years: float, phase: float = 0.0) -> float:
	return phase + fposmod(days, period_years * 365.25) / (period_years * 365.25) * TAU
