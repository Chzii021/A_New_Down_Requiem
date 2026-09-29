extends RefCounted

# One road graph drives the visible paths and the villager positions.
# Every level has left, right, and central routes that reconnect near the far end.

static func limits(map_id: int) -> Vector2:
	var map_limits = [Vector2(38, 70), Vector2(47, 88), Vector2(56, 103), Vector2(63, 118)]
	return map_limits[map_id - 1]


static func routes(map_id: int) -> Array:
	var border = limits(map_id)
	var width = border.x - 8.0
	var depth = border.y - 8.0
	var entrance = Vector2(0, 15)
	var hub = Vector2(0, -7)
	var west_near = Vector2(-width * .65, -18)
	var east_near = Vector2(width * .65, -18)
	var west_middle = Vector2(-width * .88, -depth * .55)
	var east_middle = Vector2(width * .88, -depth * .55)
	var west_end = Vector2(-width * .45, -depth * .82)
	var east_end = Vector2(width * .45, -depth * .82)
	var middle = Vector2(0, -depth * .52)
	var far_end = Vector2(0, -depth + 5)
	return [
		[entrance, hub], [hub, west_near], [hub, east_near],
		[west_near, west_middle], [east_near, east_middle],
		[west_middle, west_end], [east_middle, east_end],
		[west_end, far_end], [east_end, far_end],
		[hub, middle], [middle, far_end],
		[west_middle, middle], [east_middle, middle]
	]


static func road_distance(point: Vector2, map_id: int) -> float:
	var nearest = INF
	for segment in routes(map_id):
		var start: Vector2 = segment[0]
		var end: Vector2 = segment[1]
		var edge = end - start
		var t = clampf((point - start).dot(edge) / maxf(edge.length_squared(), .001), 0.0, 1.0)
		nearest = minf(nearest, point.distance_to(start + edge * t))
	return nearest


static func villager_positions(map_id: int, amount: int) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var rng = RandomNumberGenerator.new()
	rng.seed = 46721 + map_id * 307
	var all_roads = routes(map_id)
	var paths = all_roads.slice(1)
	var path_count = paths.size()
	var rows = ceili(float(amount) / float(path_count))
	for index in range(amount):
		var segment = paths[index % path_count]
		var start: Vector2 = segment[0]
		var end: Vector2 = segment[1]
		var direction = (end - start).normalized()
		var sideways = Vector2(-direction.y, direction.x)
		var row = floori(float(index) / float(path_count))
		var fraction = (float(row) + 1.0) / (float(rows) + 1.0)
		fraction = clampf(fraction + rng.randf_range(-.045, .045), .11, .89)
		var candidate = Vector3.ZERO
		for attempt in range(7):
			var spot = start.lerp(end, fraction) + sideways * rng.randf_range(-1.5, 1.5)
			candidate = Vector3(spot.x, 0, spot.y)
			var spaced = true
			for other in result:
				if candidate.distance_to(other) < 2.3:
					spaced = false
					break
			if spaced:
				break
			fraction = clampf(fraction + .065, .11, .89)
		result.append(candidate)
	return result
