extends SceneTree
## Synthetic layout/save regressions. No real save, native callback or payout proof.
const Puzzle=preload("res://game/puzzle.gd")
const Progress=preload("res://game/progress.gd")
var checks: int=0
var failures: int=0
func check(value: bool, text: String) -> void:
	checks+=1
	if not value: failures+=1;push_error(text)
func _initialize() -> void:
	var p: RefCounted=Puzzle.new()
	check(p.content.rooms.size()==120 and p.content.chapters.size()==12,"120 commissions in 12 chapters")
	check(p.furniture.size()==140,"All 140 supplied model options represented without alias collisions")
	var models: Dictionary={};var used: Dictionary={};var shapes: Dictionary={}
	for key in p.furniture:
		var item: Dictionary=p.furniture[key]
		check(not models.has(item.model),"Unique supplied model "+str(item.model));models[item.model]=true
		check(int(item.w)>=1 and int(item.h)>=1 and int(item.w)<=4 and int(item.h)<=4,"Bounded explicit footprint "+str(key))
		for direction in ["SE","SW","NW","NE"]:
			check(ResourceLoader.exists("res://assets/furniture/%s_%s.png"%[key,direction]),"Real directional art "+str(key)+direction)
	for id in range(120):
		p.load_room(id)
		for key in p.room.items:used[key]=true
		if id>=60:
			check(p.room.has("floor") and p.floor_cells.size()<int(p.room.w)*int(p.room.h),"New commission has actual nonrectangular floor "+str(id))
			check(p.reachable([]).size()==p.floor_cells.size(),"Empty shaped room has connected floor "+str(id))
			var signature: String=JSON.stringify([p.room.w,p.room.h,p.room.floor])
			shapes[signature]=true
			var outside: Vector2i=Vector2i(-1,-1)
			for y in range(int(p.room.h)):
				for x in range(int(p.room.w)):
					if not p.in_room(Vector2i(x,y)):outside=Vector2i(x,y)
			check(not p.placement_issue("plant",outside.x,outside.y,0).is_empty(),"Placement cannot fill the missing room corner "+str(id))
	check(used.size()==140,"All supplied model options occur in actual commissions as well as decoration")
	check(shapes.size()>=20,"New content includes at least 20 distinct visible floor masks")
	p.load_room(1)
	var long_front: Array=[{"key":"desk","x":0,"y":0,"r":0},{"key":"plant","x":1,"y":0,"r":0}]
	check(p.evaluate(long_front).paths,"One reachable tile along a long facing edge is enough; no full-edge clearance false negative")
	check(p.front_cells({"key":"desk","x":1,"y":1,"r":0})==[Vector2i(2,1),Vector2i(2,2)],"Desk front rotates with footprint: SE")
	check(p.front_cells({"key":"desk","x":1,"y":1,"r":1})==[Vector2i(1,2),Vector2i(2,2)],"Desk front rotates with footprint: SW")
	check(p.front_cells({"key":"desk","x":1,"y":1,"r":2})==[Vector2i(0,1),Vector2i(0,2)],"Desk front rotates with footprint: NW")
	check(p.front_cells({"key":"desk","x":1,"y":1,"r":3})==[Vector2i(1,0),Vector2i(2,0)],"Desk front rotates with footprint: NE")
	p.load_room(0)
	var lamp_at_wall: Array=[{"key":"chair","x":0,"y":0,"r":0},{"key":"lamp","x":4,"y":0,"r":0}]
	check(p.evaluate(lamp_at_wall).paths,"Decorative floor lamp has no imaginary operating-front requirement at the outside wall")
	var bed: Dictionary={"key":"bed","x":0,"y":0,"r":2}
	check(p.evaluate([bed]).paths,"Bed may be reached from its long side even when the foot faces an outside wall")
	check(p.front_cells({"key":"bed","x":1,"y":1,"r":1}).has(Vector2i(2,1)),"Bed side access follows a quarter turn")
	p.room.blocked=[[0,2],[1,2],[2,2],[3,2],[4,2]]
	var island: Array=[{"key":"chair","x":0,"y":0,"r":0}]
	var evaluation: Dictionary=p.evaluate(island)
	check(not evaluation.paths and evaluation.front_issues.size()==1 and "cut off" in str(evaluation.front_issues[0].reason),"Empty-looking but disconnected access tile fails with an explicit reason")
	p.load_room(0)
	var blocked: Array=[{"key":"chair","x":0,"y":0,"r":2}]
	evaluation=p.evaluate(blocked)
	check(not evaluation.paths and "boundary" in str(evaluation.front_issues[0].reason),"Outside-facing access still fails; constraints not arbitrarily loosened")
	var old: RefCounted=Progress.new();old.data.coins=235;old.data.xp=130;old.data.cleared={"0":true,"13":true};old.data.drafts={"1":[{"key":"desk","x":2,"y":0,"r":0}]}
	var restored: RefCounted=Progress.new()
	check(restored.decode(old.encode()) and restored.data==old.data,"Legacy version1 banked progress and draft identifiers preserved")
	restored.data.cleared["119"]=true
	var layout: Array=[]
	for key in p.furniture:layout.append({"key":str(key),"x":0,"y":0,"r":0})
	restored.data.decor_layout=layout;restored.data.drafts["119"]=[{"key":"kit_bathtub","x":5,"y":4,"r":1}]
	var newest: RefCounted=Progress.new()
	check(newest.decode(restored.encode()) and newest.data==restored.data and newest.data.decor_layout.size()==140,"New model options, final commission and all typed progress roundtrip")
	check(not newest.complete(120,true,false,20000*86400).first,"Out-of-range room cannot mint progress")
	print("ROOM ROUND TWO checks=%d failures=%d; synthetic isolated model, not native acceptance"%[checks,failures])
	quit(1 if failures else 0)
