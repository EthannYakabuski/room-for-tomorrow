extends SceneTree
## Synthetic desktop journal input/presentation. No native/store evidence or genuine save writes.
const App=preload("res://main.tscn")
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,text: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(text)
func frames() -> void:
	for i in range(5):await process_frame
func tap(control: Control) -> void:
	var at: Vector2=control.get_global_rect().get_center()
	for down in [true,false]:
		var mouse:=InputEventMouseButton.new();mouse.button_index=MOUSE_BUTTON_LEFT;mouse.position=at;mouse.global_position=at;mouse.pressed=down;mouse.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0;mouse.device=-1;root.push_input(mouse,true)
		var touch:=InputEventScreenTouch.new();touch.index=0;touch.position=at;touch.pressed=down;root.push_input(touch,true);await process_frame
	await frames()
func capture(name_value: String) -> void:
	var folder: String=OS.get_environment("ROOM_R2_ART_CAPTURE_DIR")
	if folder.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(folder);await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(folder.path_join(name_value+".png"))==OK,"actual Compatibility journal frame")
func run() -> void:
	create_timer(50).timeout.connect(func():push_error("Room badge UI timeout");quit(2))
	root.size=Vector2i(540,960);root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	var app: Control=App.instantiate();app.test_mode=true;root.add_child(app);await frames()
	var before: String=JSON.stringify(app.progress.data)
	await tap(app.find_child("Journal",true,false));check(app.page=="journal","ordinary paired Journal input opens illustrated collection once")
	check(JSON.stringify(app.progress.data)==before,"journal presentation leaves typed synthetic progress unchanged")
	var icons: Array[Node]=app.find_children("Badge*","TextureRect",true,false);check(icons.size()==23,"all20achievements and3boards have runtime badge textures")
	for item in icons:
		check(item.texture!=null and item.texture.get_width()==512 and item.texture.get_height()==512,"catalogue texture loads full512: "+item.name)
		check(item.mouse_filter==Control.MOUSE_FILTER_IGNORE,"art does not intercept scrolling/input: "+item.name)
	for profile in [["phone",540,960],["tablet7",600,960],["tablet10",640,1024]]:
		root.size=Vector2i(profile[1],profile[2]);root.content_scale_size=root.size;await frames()
		var first: Control=app.find_child("Badgefirst_home",true,false)
		var ancestor: Node=first.get_parent()
		while ancestor!=null and not ancestor is ScrollContainer:ancestor=ancestor.get_parent()
		check(ancestor!=null,"milestone has real scroll parent")
		ancestor.ensure_control_visible(first);await frames();check(first.size.x>=64 and first.size.y>=64,"phone/tablet badge readable64px minimum")
		check(first.get_global_rect().end.x<=float(root.size.x),"badge fits viewport width")
		await capture(str(profile[0])+"-journal-achievements")
		var last: Control=app.find_child("Badgeplanner_xp",true,false);ancestor.ensure_control_visible(last);await frames()
		check(last.get_global_rect().end.x<=float(root.size.x),"leaderboard badge fits viewport width")
		await capture(str(profile[0])+"-journal-leaderboards")
	app.queue_free();await frames();print("ROOM_R2_ART ",checks," checks / ",failures," failures");quit(1 if failures else 0)
