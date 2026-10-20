extends Control

signal cell_chosen(cell: Vector2i)
signal item_chosen(key: String)
var puzzle: RefCounted
var selected: String = ""
var quarter_turn: int = 0
var hover: Vector2i = Vector2i(-1,-1)
var preview: bool = false
var show_paths: bool = false
var hints: Dictionary = {}
var textures: Dictionary = {}
var tile: Vector2 = Vector2(28,16)
var origin: Vector2 = Vector2.ZERO
var drag: bool = false
var time: float = 0.0
var palette: int = 0
var flash_cell: Vector2i = Vector2i(-1,-1)
var flash_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	set_process(true)

func _process(delta: float) -> void:
	time += delta
	flash_time = maxf(0.0,flash_time-delta)
	queue_redraw()

func project(x: float, y: float) -> Vector2:
	return origin + Vector2((x-y)*tile.x,(x+y)*tile.y)

func coordinates(point: Vector2) -> Vector2i:
	var p: Vector2 = point-origin
	return Vector2i(floori((p.x/tile.x+p.y/tile.y)/2.0),floori((p.y/tile.y-p.x/tile.x)/2.0))

func polygon(x: int, y: int, w: int = 1, h: int = 1) -> PackedVector2Array:
	return PackedVector2Array([project(x,y),project(x+w,y),project(x+w,y+h),project(x,y+h)])

func _gui_input(event: InputEvent) -> void:
	if preview or puzzle == null: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		drag = event.pressed
		hover = coordinates(event.position)
		if not event.pressed: choose_at(event.position)
		accept_event()
	elif event is InputEventMouseMotion:
		hover = coordinates(event.position)
		queue_redraw()
	elif event is InputEventScreenTouch:
		drag = event.pressed
		hover = coordinates(event.position)
		if not event.pressed: choose_at(event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		hover = coordinates(event.position)
		queue_redraw()

func choose(c: Vector2i) -> void:
	if not puzzle.in_room(c): return
	if selected.is_empty():
		for p in puzzle.placed:
			if puzzle.occupied_cells(p).has(c): item_chosen.emit(str(p.key)); return
	else: cell_chosen.emit(c)

func choose_at(point: Vector2) -> void:
	if selected.is_empty():
		var ordered: Array = puzzle.placed.duplicate()
		ordered.sort_custom(func(p: Dictionary,q: Dictionary) -> bool: return int(p.x)+int(p.y) < int(q.x)+int(q.y))
		ordered.reverse()
		for p in ordered:
			if furniture_rect(p).has_point(point): item_chosen.emit(str(p.key)); return
	choose(coordinates(point))

func texture(key: String, r: int) -> Texture2D:
	var path: String = "res://assets/furniture/%s_%s.png" % [key,["SE","SW","NW","NE"][r%4]]
	if not textures.has(path): textures[path] = load(path)
	return textures[path]

func furniture_rect(p: Dictionary) -> Rect2:
	var tex: Texture2D = texture(str(p.key),int(p.r))
	var size_in_cells: Vector2i = puzzle.dimensions(str(p.key),int(p.r))
	var base: Vector2 = project(float(p.x)+size_in_cells.x/2.0,float(p.y)+size_in_cells.y/2.0)
	# Original images are tightly trimmed. Centre the footprint, anchor its bottom
	# at the front floor vertex, and use one projection scale for every sprite.
	var scale_factor: float = tile.x/52.0
	var sprite_size: Vector2 = tex.get_size()*scale_factor
	var front: float = base.y + (size_in_cells.x+size_in_cells.y)*tile.y/2.0
	return Rect2(Vector2(base.x-sprite_size.x/2.0,front-sprite_size.y-2),sprite_size)

func _draw() -> void:
	if puzzle == null or puzzle.room.is_empty(): return
	var w: int = int(puzzle.room.w)
	var h: int = int(puzzle.room.h)
	var unit: float = minf((size.x-52)/(w+h), (size.y-100)/(float(w+h)*.575))
	tile = Vector2(unit,unit*.575)
	origin = Vector2(size.x/2.0+(h-w)*unit/2.0,69)
	var colors: Array = [Color("e7c5a1"),Color("cbd9ce"),Color("d7cadf"),Color("edd49e")]
	var floor_color: Color = colors[clampi(palette,0,3)]
	var wall: Color = Color("ddd8cc")
	var edge: Color = Color("bec5b9")
	var a: Vector2 = project(0,0)
	var b: Vector2 = project(w,0)
	var c: Vector2 = project(0,h)
	draw_colored_polygon(PackedVector2Array([a,b,b-Vector2(0,42),a-Vector2(0,42)]),wall)
	draw_colored_polygon(PackedVector2Array([a,c,c-Vector2(0,42),a-Vector2(0,42)]),Color("c7d2c7"))
	draw_line(a-Vector2(0,42),b-Vector2(0,42),Color("f9f4e9"),4,true)
	draw_line(a-Vector2(0,42),c-Vector2(0,42),Color("f9f4e9"),4,true)
	for wx in puzzle.room.windows:
		var pos: Vector2 = project(float(wx)+.15,0)-Vector2(0,34)
		var end: Vector2 = project(float(wx)+.85,0)-Vector2(0,10)
		draw_colored_polygon(PackedVector2Array([pos,Vector2(end.x,pos.y+(end.x-pos.x)*.575),end,Vector2(pos.x,end.y-(end.x-pos.x)*.575)]),Color("b9dcdf"))
	var blocked: Dictionary = {}
	for value in puzzle.room.blocked: blocked[puzzle.cell(value)] = true
	var paths: Dictionary = puzzle.reachable(puzzle.placed)
	for y in range(h):
		for x in range(w):
			var q: Vector2i = Vector2i(x,y)
			var poly: PackedVector2Array = polygon(x,y)
			var color: Color = floor_color.lightened(.035 if (x+y)%2 == 0 else 0)
			if blocked.has(q): color = Color("849b8d")
			draw_colored_polygon(poly,color)
			draw_polyline(PackedVector2Array([poly[0],poly[1],poly[2],poly[3],poly[0]]),Color(1,1,1,.22),1,true)
			if blocked.has(q):
				draw_line(project(x+.5,y+.5),project(x+.5,y+.5)-Vector2(0,35),Color("658174"),9,true)
			elif show_paths and paths.has(q): draw_circle(project(x+.5,y+.5),2.5,Color("658f83"))
	var door: Vector2i = puzzle.cell(puzzle.room.door)
	var dp: PackedVector2Array = polygon(door.x,door.y)
	draw_colored_polygon(dp,Color("779b8b"))
	draw_line(project(door.x,door.y+1),project(door.x+1,door.y+1),Color("234a43"),5,true)
	var clear: Vector2i = puzzle.cell(puzzle.room.clearance)
	var cp: PackedVector2Array = polygon(clear.x,clear.y)
	draw_polyline(PackedVector2Array([cp[0],cp[1],cp[2],cp[3],cp[0]]),Color("779b8b"),2,true)
	if flash_time > 0:
		var fp: PackedVector2Array = polygon(flash_cell.x,flash_cell.y)
		draw_colored_polygon(fp,Color(1.0,.91,.55,flash_time*.55))
	var ordered: Array = puzzle.placed.duplicate()
	ordered.sort_custom(func(p: Dictionary,q: Dictionary) -> bool: return int(p.x)+int(p.y) < int(q.x)+int(q.y))
	for p in ordered:
		var rect: Rect2 = furniture_rect(p)
		if str(p.key) == selected:
			var dim: Vector2i = puzzle.dimensions(str(p.key),int(p.r))
			draw_colored_polygon(polygon(int(p.x),int(p.y),dim.x,dim.y),Color(1,1,1,.38))
		draw_texture_rect(texture(str(p.key),int(p.r)),rect,false)
		if show_paths:
			for f in puzzle.front_cells(p):
				if puzzle.in_room(f): draw_circle(project(f.x+.5,f.y+.5),3.5,Color("426c5b") if paths.has(f) else Color("b35f58"))
	if not hints.is_empty():
		var dim: Vector2i = puzzle.dimensions(str(hints.key),int(hints.r))
		var poly: PackedVector2Array = polygon(int(hints.x),int(hints.y),dim.x,dim.y)
		draw_colored_polygon(poly,Color(.95,.78,.34,.35+.15*sin(time*3)))
		draw_texture_rect(texture(str(hints.key),int(hints.r)),furniture_rect(hints),false,Color(1,1,1,.55))
	if not selected.is_empty() and puzzle.in_room(hover):
		var candidate: Dictionary = {"key":selected,"x":hover.x,"y":hover.y,"r":quarter_turn}
		var dim: Vector2i = puzzle.dimensions(selected,quarter_turn)
		var okay: bool = puzzle.placement_issue(selected,hover.x,hover.y,quarter_turn).is_empty()
		var poly: PackedVector2Array = polygon(hover.x,hover.y,dim.x,dim.y)
		draw_colored_polygon(poly,Color(.33,.65,.51,.55) if okay else Color(.8,.35,.3,.6))
		draw_texture_rect(texture(selected,quarter_turn),furniture_rect(candidate),false,Color(1,1,1,.55))
