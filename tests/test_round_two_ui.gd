extends SceneTree
## Ordinary paired Viewport input and explicit synthetic layout fixtures.
## Capture output is opt-in development evidence, never native/store acceptance.
const App=preload("res://main.tscn")
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(value: bool, text: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(text)
func frames() -> void:
	for i in range(4):await process_frame
func pointer(point: Vector2, pressed: bool) -> void:
	var mouse=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=point;mouse.global_position=point;mouse.pressed=pressed;mouse.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;mouse.device=-1
	root.push_input(mouse,true)
	var touch=InputEventScreenTouch.new();touch.index=0;touch.position=point;touch.pressed=pressed;root.push_input(touch,true)
func tap_control(control: Control) -> void:
	var parent: Node=control.get_parent()
	while parent!=null:
		if parent is ScrollContainer:parent.ensure_control_visible(control);break
		parent=parent.get_parent()
	await frames();var at: Vector2=control.get_global_rect().get_center()
	pointer(at,true);await process_frame;pointer(at,false);await frames()
func capture(name_value: String) -> void:
	var folder: String=OS.get_environment("ROOM_R2_CAPTURE_DIR")
	if folder.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(folder)
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder.path_join(name_value+".png"))==OK,"actual Compatibility development frame "+name_value)
func run() -> void:
	create_timer(55).timeout.connect(func():push_error("Room round-two UI timeout");quit(2))
	root.size=Vector2i(540,960);root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var app: Control=App.instantiate();app.test_mode=true;root.add_child(app);await frames()
	app.start_room(60,false);await frames()
	var key: String=""
	for item in app.puzzle.room.items:
		if str(item).begins_with("kit_"):key=str(item);break
	check(not key.is_empty(),"new commission exposes supplied model beyond original twelve")
	var target: Dictionary={}
	for piece in app.puzzle.room.solution:
		if str(piece.key)==key:target=piece;break
	await tap_control(app.find_child("Furniture"+key,true,false))
	check(app.selected==key,"ordinary paired input selects new catalogue art")
	for i in range(int(target.r)):await tap_control(app.find_child("Rotate",true,false))
	check(app.quarter_turn==int(target.r),"ordinary Rotate selects recorded footprint orientation")
	var before: int=int(app.progress.data.quest_actions)
	var at: Vector2=app.board.get_global_transform_with_canvas()*app.board.project(float(target.x)+.5,float(target.y)+.5)
	pointer(at,true);await process_frame;pointer(at,false);await frames()
	check(app.puzzle.has_item(key) and app.puzzle.placed.size()==1,"ordinary paired floor input places exactly one new model")
	check(int(app.progress.data.quest_actions)==before+1,"one paired tap records exactly one placement action")
	await tap_control(app.find_child("Undo",true,false))
	check(app.puzzle.placed.is_empty(),"new-model placement undo remains free")
	app.start_room(0,false);await frames()
	app.puzzle.room.blocked=[[0,2],[1,2],[2,2],[3,2],[4,2]]
	app.puzzle.placed=[{"key":"chair","x":0,"y":0,"r":0}]
	app.refresh_puzzle();app.plan_tip();await frames()
	# Once all required items are present, the tip explains the actual failed edge.
	app.puzzle.room.items=["chair"];app.plan_tip()
	check("cut off" in app.message_label.text and "Reading chair" in app.message_label.text,"Plan tip names the disconnected furniture and exact cause")
	await capture("phone-front-why-fail")
	for profile in [{"name":"phone","size":Vector2i(540,960),"room":60},{"name":"tablet7","size":Vector2i(600,960),"room":78},{"name":"tablet10","size":Vector2i(800,1280),"room":119}]:
		root.content_scale_size=Vector2i.ZERO;root.size=profile.size
		app.start_room(int(profile.room),false);app.puzzle.placed=app.puzzle.room.solution.duplicate(true);app.refresh_puzzle();app.board.show_paths=true;await frames()
		check(app.puzzle.evaluate().complete,"rendered shaped room uses the same valid rules "+str(profile.name))
		check(app.submit_button.get_global_rect().end.y<=root.size.y,"shaped-room primary action fits "+str(profile.name))
		await capture(str(profile.name)+"-shaped-room")
	app.start_decoration();await frames()
	var selector: OptionButton=app.find_child("FurnitureCategory",true,false)
	check(selector!=null and selector.item_count>=10,"140-piece decoration palette has category navigation")
	for i in range(selector.item_count):
		if selector.get_item_text(i)=="Architecture":selector.select(i);selector.item_selected.emit(i);break
	await frames()
	check(app.tray.get_child_count()>10 and app.tray.get_child_count()<140,"category filter exposes architecture without an endless mixed strip")
	await capture("tablet10-catalogue-architecture")
	app.queue_free();await frames()
	print("ROOM ROUND TWO UI checks=%d failures=%d; isolated paired Viewport input; not native acceptance"%[checks,failures])
	quit(1 if failures else 0)
