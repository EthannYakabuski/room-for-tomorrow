extends RefCounted

var furniture: Dictionary = {}
var content: Dictionary = {}
var room: Dictionary = {}
var placed: Array = []
var history: Array = []
var floor_cells: Dictionary = {}

func _init() -> void:
	furniture = JSON.parse_string(FileAccess.get_file_as_string("res://game/furniture.json"))
	content = JSON.parse_string(FileAccess.get_file_as_string("res://game/commissions.json"))
	# JSON numbers are floats; normalize identifiers and membership arrays once.
	for entry in content.rooms:
		for key in ["id","chapter","w","h"]: entry[key] = int(entry[key])
		entry.windows = entry.windows.map(func(v: Variant) -> int: return int(v))
		for p in entry.solution:
			for key in ["x","y","r"]: p[key] = int(p[key])

func load_room(index: int) -> void:
	room = content.rooms[clampi(index, 0, content.rooms.size()-1)].duplicate(true)
	_cache_floor()
	placed = []
	history = []

func load_decoration() -> void:
	room = {"id": -1, "name": "Your Quiet Corner", "chapter": 0, "w": 8, "h": 8,
		"door": [6, 7], "clearance": [6, 6], "blocked": [], "windows": [0,1,2,3,4,5,6,7],
		"items": furniture.keys(), "daylight": false, "optional": "plant", "brief": "A space of your own. Arrange it however you like.", "solution": []}
	_cache_floor()
	placed = []
	history = []

func dimensions(key: String, rotation: int) -> Vector2i:
	var d: Dictionary = furniture[key]
	return Vector2i(int(d.h), int(d.w)) if rotation % 2 else Vector2i(int(d.w), int(d.h))

func occupied_cells(p: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var size: Vector2i = dimensions(str(p.key), int(p.r))
	for x in range(size.x):
		for y in range(size.y): out.append(Vector2i(int(p.x) + x, int(p.y) + y))
	return out

func _cache_floor() -> void:
	floor_cells.clear()
	for raw in room.get("floor",[]): floor_cells[cell(raw)] = true

func access_rule(key: String) -> String:
	match str(furniture[key].get("access","front")):
		"none": return "No operating front; this is a decorative or architectural piece."
		"perimeter": return "Reach any one tile beside the footprint."
		"long_sides": return "Reach either long side of the bed, not only its foot."
	return "Reach any one tile along the highlighted facing edge. Rotate changes that edge."

func front_cells(p: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var size: Vector2i = dimensions(str(p.key), int(p.r))
	var x: int = int(p.x)
	var y: int = int(p.y)
	var edges: Array = [[],[],[],[]]
	for i in range(size.y):
		edges[0].append(Vector2i(x+size.x,y+i))
		edges[2].append(Vector2i(x-1,y+i))
	for i in range(size.x):
		edges[1].append(Vector2i(x+i,y+size.y))
		edges[3].append(Vector2i(x+i,y-1))
	var mode: String=str(furniture[p.key].get("access","front"))
	if mode=="none": return out
	var sides: Array=[int(p.r)%4]
	if mode=="perimeter": sides=[0,1,2,3]
	elif mode=="long_sides": sides=[1,3] if (int(furniture[p.key].w)>=int(furniture[p.key].h)) != bool(int(p.r)%2) else [0,2]
	for side in sides:
		for value in edges[side]: out.append(value)
	return out

func front_status(p: Dictionary, paths: Dictionary, input: Variant = null) -> Dictionary:
	var candidates: Array[Vector2i]=front_cells(p)
	var okay: bool=candidates.is_empty() or candidates.any(func(c: Vector2i) -> bool: return paths.has(c))
	var reason: String="Usable: at least one highlighted tile connects to the door."
	if not okay:
		var occ: Dictionary=occupied(placed if input==null else input,true)
		var free: bool=candidates.any(func(c: Vector2i) -> bool: return in_room(c) and not occ.has(c))
		reason="The highlighted edge has empty floor, but it is cut off from the entrance." if free else "The highlighted edge meets furniture, a column, or the room boundary."
	return {"key":str(p.key),"name":str(furniture[p.key].name),"usable":okay,"reason":reason,"rule":access_rule(str(p.key)),"cells":candidates}

func cell(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))

func in_room(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < int(room.w) and c.y < int(room.h) and (not room.has("floor") or floor_cells.has(c))

func occupied(layout: Array, walking: bool = false) -> Dictionary:
	var out: Dictionary = {}
	for value in room.blocked: out[cell(value)] = "wall"
	for p in layout:
		if walking and furniture.has(str(p.key)) and bool(furniture[p.key].get("walkable",false)): continue
		for c in occupied_cells(p): out[c] = p.key
	return out

func placement_issue(key: String, x: int, y: int, rotation: int) -> String:
	var p: Dictionary = {"key": key, "x": x, "y": y, "r": rotation}
	var other: Array = placed.filter(func(item: Dictionary) -> bool: return str(item.key) != key)
	var occ: Dictionary = occupied(other)
	for c in occupied_cells(p):
		if not in_room(c): return "Keep the whole footprint inside the room."
		if c == cell(room.door) or c == cell(room.clearance): return "Leave the doorway and its welcome tile clear."
		if occ.has(c): return "That footprint overlaps furniture or a column."
	return ""

func place(key: String, x: int, y: int, rotation: int) -> bool:
	if not furniture.has(key) or not room.items.has(key): return false
	if not placement_issue(key,x,y,rotation).is_empty(): return false
	history.append(placed.duplicate(true))
	placed = placed.filter(func(item: Dictionary) -> bool: return str(item.key) != key)
	placed.append({"key":key, "x":x, "y":y, "r":rotation})
	return true

func remove(key: String) -> bool:
	if not has_item(key): return false
	history.append(placed.duplicate(true))
	placed = placed.filter(func(item: Dictionary) -> bool: return str(item.key) != key)
	return true

func undo() -> bool:
	if history.is_empty(): return false
	placed = history.pop_back()
	return true

func reset() -> void:
	if placed.is_empty(): return
	history.append(placed.duplicate(true))
	placed = []

func has_item(key: String) -> bool:
	return placed.any(func(p: Dictionary) -> bool: return str(p.key) == key)

func reachable(layout: Array) -> Dictionary:
	var occ: Dictionary = occupied(layout,true)
	var start: Vector2i = cell(room.door)
	var visited: Dictionary = {}
	if occ.has(start): return visited
	visited[start] = true
	var queue: Array[Vector2i] = [start]
	var index: int = 0
	while index < queue.size():
		var c: Vector2i = queue[index]
		index += 1
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = c + d
			if in_room(next) and not occ.has(next) and not visited.has(next):
				visited[next] = true
				queue.append(next)
	return visited

func distance(a: Dictionary, b: Dictionary) -> int:
	var best: int = 999
	for ca in occupied_cells(a):
		for cb in occupied_cells(b): best = mini(best, absi(ca.x-cb.x) + absi(ca.y-cb.y))
	return best

func optional_ok(layout: Array) -> bool:
	for p in layout:
		if str(p.key) != str(room.optional): continue
		if str(p.key) == "plant": return int(p.y) == 0 and room.windows.has(int(p.x))
		if str(p.key) == "shelf": return int(p.x) == 0 or int(p.y) == 0
		if str(p.key) == "cabinet":
			for b in layout:
				if str(b.key) == "bed" and distance(p,b) <= 2: return true
	return false

func evaluate(input: Variant = null) -> Dictionary:
	var layout: Array = placed if input == null else input
	var collision: bool = false
	var seen: Dictionary = {}
	var names: Dictionary = {}
	for b in room.blocked: seen[cell(b)] = true
	if seen.has(cell(room.door)) or seen.has(cell(room.clearance)): collision = true
	for p in layout:
		if not furniture.has(str(p.get("key", ""))): collision = true; continue
		if names.has(p.key): collision = true
		names[p.key] = true
		for c in occupied_cells(p):
			if not in_room(c) or seen.has(c) or c == cell(room.door) or c == cell(room.clearance): collision = true
			seen[c] = true
	var all_placed: bool = room.items.all(func(k: String) -> bool: return names.has(k))
	var paths: Dictionary = reachable(layout)
	var usable: bool = not collision
	var dark: bool = false
	var lamp: Dictionary = {}
	var seats: Array = []
	var front_issues: Array = []
	for p in layout:
		if not furniture.has(str(p.get("key", ""))): continue
		var access: Dictionary=front_status(p,paths,layout)
		if not access.usable:
			usable = false
			front_issues.append(access)
		if bool(room.daylight) and str(p.key) == "desk":
			if not occupied_cells(p).any(func(c: Vector2i) -> bool: return c.y == 0 and room.windows.has(c.x)): dark = true
		if str(p.key) == "lamp": lamp = p
		if str(p.key) in ["chair", "sofa", "bed", "stool"]: seats.append(p)
	var lit: bool = not lamp.is_empty() and not seats.is_empty() and seats.any(func(p: Dictionary) -> bool: return distance(lamp,p) <= 2)
	var complete: bool = all_placed and not collision and usable and not dark and lit
	return {"all_placed":all_placed,"clear":not collision,"paths":usable,"daylight":not dark,"reading":lit,"optional":optional_ok(layout),"complete":complete,"reachable":paths,"front_issues":front_issues}

func next_hint() -> Dictionary:
	for target in room.solution:
		var match_found: bool = placed.any(func(p: Dictionary) -> bool: return p == target)
		if not match_found: return target.duplicate(true)
	return {}
