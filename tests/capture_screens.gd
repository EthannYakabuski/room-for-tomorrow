extends SceneTree
const App = preload("res://main.tscn")

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var output: String = OS.get_environment("TEMP").path_join("room-captures")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(output)
	var app: Control = App.instantiate()
	app.test_mode = true
	root.add_child(app)
	await process_frame
	for state in ["home","commissions","planning","pathways","result","courtyard","tomorrow","decoration","journal","tutorial"]:
		match state:
			"home": app.show_home()
			"commissions": app.show_commissions()
			"planning":
				app.start_room(9,false)
				app.puzzle.placed = app.puzzle.room.solution.duplicate(true)
				app.puzzle.placed.pop_back()
				app.refresh_puzzle()
			"pathways":
				app.start_room(17,false)
				app.puzzle.placed = app.puzzle.room.solution.duplicate(true)
				app.board.show_paths = true
				app.refresh_puzzle()
			"result": app.finish_room()
			"courtyard":
				app.start_room(45,false)
				app.puzzle.placed = app.puzzle.room.solution.duplicate(true)
				app.board.show_paths = true
				app.refresh_puzzle()
			"tomorrow":
				app.start_room(59,false)
				app.puzzle.placed = app.puzzle.room.solution.duplicate(true)
				app.puzzle.placed.pop_back()
				app.refresh_puzzle()
			"decoration":
				app.start_decoration()
				for p in app.puzzle.content.rooms[9].solution: app.puzzle.place(str(p.key),int(p.x),int(p.y),int(p.r))
				app.refresh_puzzle()
			"journal": app.show_journal()
			"tutorial": app.start_tutorial(0)
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var path: String = output.path_join(state+".png")
		var error: Error = root.get_texture().get_image().save_png(path)
		print("ROOM_CAPTURE ",path," result=",error)
		if error != OK: quit(1); return
	root.remove_child(app)
	app.free()
	await process_frame
	await process_frame
	quit(0)
