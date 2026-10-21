extends SceneTree
const App = preload("res://main.tscn")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	create_timer(30.0).timeout.connect(func() -> void: push_error("UI suite timed out"); quit(2))
	run.call_deferred()

func check(condition: bool, text: String) -> void:
	checks += 1
	if not condition: failures += 1; push_error(text)

func press(app: Control, key: String) -> void:
	var node: Node = app.find_child(key,true,false)
	check(node is Button,"Button exists: "+key)
	if node is Button: node.pressed.emit()
	await layout()

func layout() -> void:
	await process_frame
	await process_frame
	await process_frame
	await process_frame

func tap(global_position: Vector2) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = 0
	event.position = global_position
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventScreenTouch.new()
	event.index = 0
	event.position = global_position
	event.pressed = false
	Input.parse_input_event(event)
	await layout()

func run() -> void:
	root.size = Vector2i(540,960)
	root.content_scale_size = Vector2i(540,960)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var app: Control = App.instantiate()
	app.test_mode = true
	root.add_child(app)
	await layout()
	check(app.test_mode and app.progress.completed()==0,"UI tests use fresh isolated state")
	check(app.page=="home","App opens at the doorstep")
	await tap(app.find_child("GoCommissions",true,false).get_global_rect().get_center())
	await layout()
	check(app.page=="commissions","A dispatched screen touch opens the commission book")
	if app.page != "commissions": quit(1); return
	check(not app.find_child("Commission0",true,false).disabled and app.find_child("Commission10",true,false).disabled,"Chapter UI follows progression gating")
	await press(app,"Commission0")
	await layout()
	check(app.page=="puzzle" and app.puzzle.placed.is_empty(),"Commission starts on an empty floor")
	check(app.submit_button.get_global_rect().end.y<=960,"Puzzle controls fit portrait viewport (end=%.1f)"%app.submit_button.get_global_rect().end.y)
	check(app.body.get_global_rect().position.y>=0,"Puzzle header stays inside portrait viewport")
	await press(app,"Furniturechair")
	await layout()
	check(app.selected=="chair","Furniture card selects a piece")
	await tap(app.board.get_global_transform()*app.board.project(.5,.5))
	await layout()
	check(app.puzzle.has_item("chair"),"Touching floor places selected piece")
	await press(app,"Undo")
	await layout()
	check(not app.puzzle.has_item("chair") and app.progress.data.undos==1,"Undo removes one placement and tracks action")
	await press(app,"Furniturelamp")
	await press(app,"Rotate")
	check(app.quarter_turn==1,"Rotate button changes pending orientation")
	app.place_selected(Vector2i(1,0))
	await press(app,"Reset")
	check(app.puzzle.placed.is_empty(),"Reset clears arrangement")
	await press(app,"Undo")
	check(app.puzzle.has_item("lamp"),"Reset can be undone without cost")
	app.puzzle.placed = app.puzzle.room.solution.duplicate(true)
	app.refresh_puzzle()
	check(not app.submit_button.disabled,"Validated room enables welcome action")
	await press(app,"Complete")
	await layout()
	check(app.page=="result" and app.progress.completed()==1,"Welcoming a room grants persistent progress")
	var coins: int = int(app.progress.data.coins)
	app.finish_room()
	check(int(app.progress.data.coins)==coins,"Repeated completion UI cannot duplicate rewards")
	app.start_daily()
	await layout()
	check(app.daily_mode,"Daily enters deterministic room")
	app.puzzle.placed = app.puzzle.room.solution.duplicate(true)
	app.finish_room()
	check(app.progress.data.dailies==1,"Daily completion counted once")
	app.start_tutorial(0)
	app.puzzle.placed = app.puzzle.room.solution.duplicate(true)
	app.finish_room()
	await layout()
	check(app.tutorial==1,"First tutorial leads to daylight tutorial")
	app.puzzle.placed = app.puzzle.room.solution.duplicate(true)
	app.finish_room()
	check(app.page=="home" and app.progress.data.tutorials.size()==2,"Two tutorials complete with free progression")
	app.start_decoration()
	await layout()
	app.select_item("sofa")
	app.place_selected(Vector2i(0,0))
	app.finish_room()
	app.start_decoration()
	await layout()
	check(app.puzzle.has_item("sofa") and app.progress.data.decorations==1,"Decoration room saves its layout")
	app.start_room(1,false)
	await layout()
	var token: int = app.progress.begin_reward()
	app.receive_hint(token,false,1)
	check(app.board.hints.is_empty(),"Unrewarded callback reveals no precise hint")
	token = app.progress.begin_reward()
	app.receive_hint(token,true,1)
	check(not app.board.hints.is_empty(),"Earned callback reveals a precise placement hint")
	app.board.hints = {}
	app.receive_hint(token,true,1)
	check(app.board.hints.is_empty(),"Duplicate rewarded callback cannot reveal another hint")
	app.show_journal()
	await layout()
	check(app.page=="journal" and app.find_child("Palette0",true,false)!=null,"Journal shows cosmetics and milestones")
	for id in range(app.puzzle.content.rooms.size()):
		app.start_room(id,false)
		await layout()
		check(app.submit_button.get_global_rect().end.y<=960 and app.body.get_global_rect().position.y>=0,"Commission %d fits all portrait controls: submit=%.1f body=%s board=%s scroll=%d"%[id,app.submit_button.get_global_rect().end.y,str(app.body.get_global_rect()),str(app.board.size),app.page_scroll.scroll_vertical])
	app.start_room(0,false)
	app.puzzle.placed = app.puzzle.room.solution.duplicate(true)
	app.refresh_puzzle()
	await layout()
	for piece in app.puzzle.placed:
		if str(piece.key)=="shelf":
			var rect: Rect2 = app.board.furniture_rect(piece)
			await tap(app.board.get_global_transform()*(rect.position+Vector2(rect.size.x*.5,rect.size.y*.3)))
	check(app.selected=="shelf","A touch on tall furniture selects its visible sprite")
	check(not FileAccess.file_exists("user://room-test-isolated.json"),"UI flow did not write a gameplay test save")
	root.remove_child(app)
	app.free()
	await layout()
	print("ROOM_UI_TESTS: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
