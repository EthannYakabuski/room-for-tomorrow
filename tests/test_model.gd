extends SceneTree

const Puzzle = preload("res://game/puzzle.gd")
const Progress = preload("res://game/progress.gd")
var checks: int = 0
var failures: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition: failures += 1; push_error(message)

func _initialize() -> void:
	var puzzle: RefCounted = Puzzle.new()
	var shapes: Dictionary = {}
	var optional_count: int = 0
	for id in range(60):
		puzzle.load_room(id)
		var solution: Array = puzzle.room.solution
		check(puzzle.evaluate(solution).complete,"Recorded arrangement must solve commission %d" % id)
		check(not puzzle.evaluate().complete,"An empty commission cannot complete: %d"%id)
		check(solution.size() == puzzle.room.items.size(),"Every specified piece occurs: %d"%id)
		if puzzle.evaluate(solution).optional: optional_count += 1
		var signature: String = JSON.stringify([puzzle.room.w,puzzle.room.h,puzzle.room.items,puzzle.room.blocked,puzzle.room.daylight,puzzle.room.optional])
		check(not shapes.has(signature),"Commission geometry/brief must be distinct: %d"%id)
		shapes[signature] = true
		for p in solution: check(puzzle.place(str(p.key),int(p.x),int(p.y),int(p.r)),"Recorded furniture can be placed %d"%id)
		check(puzzle.evaluate().complete,"Placement validator agrees with arrangement evaluator: %d"%id)
		var alternative_found: bool = false
		for piece in solution:
			if alternative_found: break
			for y in range(int(puzzle.room.h)):
				if alternative_found: break
				for x in range(int(puzzle.room.w)):
					if x==int(piece.x) and y==int(piece.y): continue
					var candidate: Array = solution.duplicate(true)
					for value in candidate:
						if str(value.key)==str(piece.key): value.x=x; value.y=y
					if puzzle.evaluate(candidate).complete: alternative_found = true; break
		check(alternative_found,"Another accepted arrangement exists for commission %d"%id)
		var snapshot: String = JSON.stringify(puzzle.placed)
		puzzle.reset()
		check(puzzle.placed.is_empty() and puzzle.undo() and JSON.stringify(puzzle.placed)==snapshot,"Reset is fully undoable: %d"%id)
	check(optional_count == 60,"All recorded arrangements include their optional wish (observed %d)"%optional_count)
	puzzle.load_room(1)
	check(not puzzle.place("desk",-1,0,0),"Negative coordinates rejected")
	check(not puzzle.place("desk",4,4,0),"Bounds and doorway rejected")
	check(puzzle.place("desk",0,0,0),"Valid placement")
	check(not puzzle.place("lamp",0,0,0),"Furniture collision rejected")
	check(puzzle.place("desk",2,0,1),"Existing piece moves and rotates without duplicate")
	check(puzzle.placed.size()==1 and puzzle.dimensions("desk",1)==Vector2i(2,1),"Rotation changes rectangular footprint")
	check(puzzle.undo() and int(puzzle.placed[0].r)==0,"Undo restores rotation and placement")
	var invalid: Array = puzzle.room.solution.duplicate(true)
	invalid[0].x = int(puzzle.room.door[0]); invalid[0].y = int(puzzle.room.door[1])
	check(not puzzle.evaluate(invalid).complete,"Doorway collision prevents completion")
	puzzle.placed = puzzle.room.solution.duplicate(true)
	for p in puzzle.placed:
		if str(p.key)=="desk": p.r = 2; p.x = 0; p.y = 0
	check(not puzzle.evaluate().paths,"Furniture front against exterior wall is unusable")
	puzzle.load_room(0)
	puzzle.room.blocked = [[0,2],[1,2],[2,2],[3,2],[4,2]]
	puzzle.placed = [{"key":"chair","x":0,"y":0,"r":0},{"key":"lamp","x":1,"y":0,"r":0}]
	check(not puzzle.evaluate().paths,"A disconnected island cannot satisfy usable-side walkability")
	puzzle.load_room(0)
	var alternative: Array = [{"key":"chair","x":0,"y":0,"r":1},{"key":"lamp","x":1,"y":0,"r":1},{"key":"plant","x":2,"y":0,"r":1},{"key":"shelf","x":3,"y":0,"r":1}]
	check(puzzle.evaluate(alternative).complete,"Different accepted arrangement exists")
	alternative[0].x=0; alternative[0].y=2; alternative[1].y=2
	check(puzzle.evaluate(alternative).complete,"Second distinct accepted arrangement exists")
	var progress: RefCounted = Progress.new()
	var instant: int = 20000*86400+123
	check(progress.chapter_unlocked(0) and not progress.chapter_unlocked(1),"Chapter gating starts with chapter one")
	var reward: Dictionary = progress.complete(0,true,false,instant)
	check(reward.coins==60 and reward.xp==45,"First commission and detail pay once")
	check(progress.complete(0,true,false,instant).coins==0,"Replaying a completed commission cannot mint rewards")
	progress.complete(1,false,false,instant)
	check(progress.complete(1,true,false,instant).coins==15,"Optional improvement pays separately once")
	for id in range(2,8): progress.complete(id,false,false,instant)
	check(progress.chapter_unlocked(1) and not progress.chapter_unlocked(2),"Eight homes open the next chapter")
	var daily: int = progress.daily_id(instant)
	check(progress.complete(daily,true,true,instant).daily,"Daily completion pays today")
	check(not progress.complete(daily,true,true,instant).daily,"Daily completion cannot double claim")
	check(progress.daily_id(instant-86400)==daily,"Clock rewind does not create earlier daily")
	check(progress.daily_id(instant+86400)!=daily,"Next UTC day rotates deterministic commission")
	for i in range(6): progress.action("place",instant+86400)
	check(progress.claim_quest(0,instant+86400) and not progress.claim_quest(0,instant+86400),"Action quest claim idempotent")
	var token: int = progress.begin_reward()
	check(token>0 and progress.begin_reward()==0,"One reward request can be pending")
	check(not progress.finish_reward(token,false),"Unfinished native reward earns no hint")
	token = progress.begin_reward()
	check(progress.finish_reward(token,true) and not progress.finish_reward(token,true),"Earned callback is applied once")
	check(not progress.finish_reward(token+100,true),"Unrelated reward token ignored")
	var before: int = int(progress.data.coins)
	check(progress.buy_palette(1),"Earned currency buys an optional palette")
	check(progress.buy_palette(1) and int(progress.data.coins)==before-120,"Owned palette selection costs nothing")
	var raw: String = progress.encode()
	var reloaded: RefCounted = Progress.new()
	check(reloaded.decode(raw) and reloaded.encode()==raw,"Save roundtrip retains progress and numeric types")
	check(not reloaded.decode("{broken") and not reloaded.decode('{"version":999}'),"Corrupt and unknown saves rejected")
	check(not reloaded.decode('{"version":{}}'),"Invalid version field type is rejected safely")
	check(reloaded.decode('{"version":1,"coins":-99,"xp":1e99,"palette":99,"cleared":{"999":true,"2":true},"owned_palettes":[999,0]}'),"Known fields migrate from partial saves")
	check(reloaded.data.coins==0 and reloaded.data.palette==0 and reloaded.completed()==1,"Malformed saved values are constrained")
	var file_path: String = OS.get_environment("TEMP").path_join("room-test-isolated-%d.json" % OS.get_process_id())
	check(progress.save_to(file_path) and reloaded.load_from(file_path),"Atomic save/load works in isolated test file")
	progress.data.coins = int(progress.data.coins)+3
	check(progress.save_to(file_path) and reloaded.load_from(file_path) and reloaded.data.coins==progress.data.coins,"Replacing an existing save retains newest progress")
	check(reloaded.decode('{"version":1,"drafts":{"1":999,"2":[{"key":"bed","x":0,"y":0,"r":0}],"999":[]},"decor_layout":[{"key":"unknown","x":0,"y":0,"r":0}]}') and reloaded.data.drafts["1"].is_empty() and reloaded.data.drafts["2"].size()==1 and not reloaded.data.drafts.has("999") and reloaded.data.decor_layout.is_empty(),"Malformed saved layouts are bounded and sanitized")
	DirAccess.remove_absolute(file_path)
	check(not FileAccess.file_exists(file_path),"Isolated test save removed")
	print("ROOM_MODEL_TESTS: %d checks, %d failures; %d optional recorded arrangements" % [checks,failures,optional_count])
	quit(0 if failures==0 else 1)
