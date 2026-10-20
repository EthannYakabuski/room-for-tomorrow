extends Control

const Puzzle = preload("res://game/puzzle.gd")
const Progress = preload("res://game/progress.gd")
const RoomView = preload("res://game/room_view.gd")
const SAVE_PATH: String = "user://rooms-v1.json"
const INK: Color = Color("234a43")
const PAPER: Color = Color("f4efe3")
const MUTED: Color = Color("6a7e72")
var puzzle: RefCounted = Puzzle.new()
var progress: RefCounted = Progress.new()
var catalog: Dictionary = {}
var body: VBoxContainer
var board: Control
var tray: HBoxContainer
var message_label: Label
var criteria: VBoxContainer
var submit_button: Button
var selected: String = ""
var quarter_turn: int = 0
var page: String = "home"
var active_id: int = 0
var daily_mode: bool = false
var tutorial: int = -1
var test_mode: bool = false
var completed_this_visit: bool = false
var toast: String = ""
var music: AudioStreamPlayer
var click_sound: AudioStreamPlayer
var now_override: int = -1
var page_margin: MarginContainer
var page_scroll: ScrollContainer

func _ready() -> void:
	test_mode = test_mode or OS.get_cmdline_user_args().has("--test-mode")
	if not test_mode: progress.load_from(SAVE_PATH)
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://game/catalog.json"))
	progress.roll_day(now())
	var background: ColorRect = ColorRect.new()
	background.color = PAPER
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var margin: MarginContainer = MarginContainer.new()
	page_margin = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right"]: margin.add_theme_constant_override("margin_"+edge,22)
	for edge in ["top","bottom"]: margin.add_theme_constant_override("margin_"+edge,18)
	add_child(margin)
	get_viewport().size_changed.connect(fit_banner_margin)
	var native: Node = service()
	if native != null and native.has_signal("menu_bottom_reserve_changed"):
		native.connect("menu_bottom_reserve_changed",fit_banner_margin)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",10)
	page_scroll = ScrollContainer.new()
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(page_scroll)
	page_scroll.add_child(body)
	var theme_resource: Theme = Theme.new()
	theme_resource.default_font_size = 18
	theme = theme_resource
	if not test_mode and DisplayServer.get_name() != "headless": setup_audio()
	show_home()

func setup_audio() -> void:
	music = AudioStreamPlayer.new()
	music.stream = load("res://assets/audio/quiet_rooms.wav")
	music.volume_db = -9
	add_child(music)
	music.finished.connect(func() -> void: if bool(progress.data.music): music.play())
	if bool(progress.data.music): music.play()
	if ResourceLoader.exists("res://assets/audio/click.ogg"):
		click_sound = AudioStreamPlayer.new()
		click_sound.stream = load("res://assets/audio/click.ogg")
		click_sound.volume_db = -13
		add_child(click_sound)

func _exit_tree() -> void:
	for player in [music,click_sound]:
		if is_instance_valid(player): player.stop(); player.stream = null

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_CLOSE_REQUEST]: save()

func now() -> int:
	return now_override if now_override >= 0 else int(Time.get_unix_time_from_system())

func service() -> Node:
	return get_node_or_null("/root/Services")

func call_service(method: String, args: Array = []) -> Variant:
	var native: Node = service()
	if native != null and native.has_method(method): return native.callv(method,args)
	return null

func save() -> void:
	if not test_mode: progress.save_to(SAVE_PATH)

func clear_page(next: String) -> void:
	page = next
	# Fresh containers discard the previous page's cached minimum height. A
	# journal's long scroll content must not stretch a subsequent puzzle board.
	page_margin.remove_child(page_scroll)
	page_scroll.queue_free()
	page_scroll = ScrollContainer.new()
	page_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if next == "home" else ScrollContainer.SCROLL_MODE_DISABLED
	page_margin.add_child(page_scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",10)
	page_scroll.add_child(body)
	board = null
	call_service("set_menu_visible",[next == "home"])
	fit_banner_margin()

func fit_banner_margin() -> void:
	if not is_instance_valid(page_margin): return
	var reserve: float = 0.0
	var native: Node = service()
	if page == "home" and native != null and native.has_method("menu_bottom_reserve"):
		reserve = maxf(0.0,float(native.call("menu_bottom_reserve",self)))
	page_margin.add_theme_constant_override("margin_bottom",18+ceili(reserve))

func label(text: String, size_value: int = 18, color: Color = INK) -> Label:
	var item: Label = Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size",size_value)
	item.add_theme_color_override("font_color",color)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return item

func style(fill: Color, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(15)
	box.set_content_margin_all(12)
	box.border_color = border
	box.set_border_width_all(1 if border.a > 0 else 0)
	return box

func button(text: String, action: Callable, primary: bool = false, id: String = "") -> Button:
	var item: Button = Button.new()
	item.mouse_filter = Control.MOUSE_FILTER_PASS if page != "puzzle" else Control.MOUSE_FILTER_STOP
	item.text = text
	item.name = id if not id.is_empty() else text.validate_node_name()
	item.custom_minimum_size.y = 48
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item.add_theme_font_size_override("font_size",18)
	item.add_theme_color_override("font_color",PAPER if primary else INK)
	item.add_theme_color_override("font_hover_color",PAPER if primary else INK)
	item.add_theme_color_override("font_pressed_color",PAPER if primary else INK)
	item.add_theme_color_override("font_disabled_color",MUTED)
	item.add_theme_stylebox_override("normal",style(INK if primary else Color("e4e5d9")))
	item.add_theme_stylebox_override("hover",style(INK.lightened(.12) if primary else Color("d6e2d4")))
	item.add_theme_stylebox_override("pressed",style(Color("cb775c")))
	item.add_theme_stylebox_override("disabled",style(Color("e6e2d7")))
	item.pressed.connect(func() -> void:
		if is_instance_valid(click_sound): click_sound.play()
		action.call_deferred())
	return item

func row(parent: Node) -> HBoxContainer:
	var container: HBoxContainer = HBoxContainer.new()
	container.add_theme_constant_override("separation",8)
	parent.add_child(container)
	return container

func panel(parent: Node, color: Color = Color("e8e5d7")) -> VBoxContainer:
	var container: PanelContainer = PanelContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_PASS if page != "puzzle" else Control.MOUSE_FILTER_STOP
	container.add_theme_stylebox_override("panel",style(color))
	parent.add_child(container)
	var contents: VBoxContainer = VBoxContainer.new()
	contents.add_theme_constant_override("separation",7)
	container.add_child(contents)
	return contents

func header(back: Callable = Callable()) -> void:
	var bar: HBoxContainer = row(body)
	if back.is_valid():
		var back_button: Button = button("‹",back,false,"Back")
		back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		back_button.custom_minimum_size.x = 48
		bar.add_child(back_button)
	var brand: Label = label("ROOM FOR TOMORROW",14)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	bar.add_child(brand)
	var balance: Label = label("◈ %d  ·  Lv %d" % [int(progress.data.coins),progress.level()],16)
	balance.size_flags_horizontal = Control.SIZE_SHRINK_END
	balance.autowrap_mode = TextServer.AUTOWRAP_OFF
	bar.add_child(balance)

func make_board(parent: Node, model: RefCounted, height: int, decorative: bool = false) -> Control:
	var view: Control = RoomView.new()
	view.puzzle = model
	view.palette = int(progress.data.palette)
	view.custom_minimum_size.y = height
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.preview = decorative
	parent.add_child(view)
	if decorative: view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view

func show_home() -> void:
	clear_page("home")
	tutorial = -1
	header()
	body.add_child(label("Room for\nTomorrow",42))
	body.add_child(label("Make a little space for a good life.",19,MUTED))
	var demo: RefCounted = Puzzle.new()
	demo.load_room(9)
	demo.placed = demo.room.solution.duplicate(true)
	board = make_board(body,demo,275,true)
	var welcome: HBoxContainer = row(body)
	welcome.add_child(label("%d / 60 homes welcomed" % progress.completed(),18))
	var xp: Label = label("%d planner XP" % int(progress.data.xp),16,MUTED)
	xp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	welcome.add_child(xp)
	body.add_child(button("Open the commission book  →",show_commissions,true,"GoCommissions"))
	var actions: HBoxContainer = row(body)
	actions.add_child(button("Today’s room",start_daily,false,"Daily"))
	actions.add_child(button("My quiet corner",start_decoration,false,"Decorate"))
	var card: VBoxContainer = panel(body)
	card.add_child(label("SMALL THINGS, EVERY DAY",13,MUTED))
	var day_value: int = progress.roll_day(now())
	for i in range(2):
		var quest: HBoxContainer = row(card)
		var text: String = "Make 6 thoughtful moves  ·  %d/6" % mini(6,int(progress.data.quest_actions)) if i == 0 else "Welcome one new home  ·  %d/1" % mini(1,int(progress.data.quest_completes))
		var title: Label = label(text,16)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		quest.add_child(title)
		var claimed: bool = progress.data.quest_claimed.has("%d:%d" % [day_value,i])
		var claim: Button = button("✓" if claimed else "+25",claim_quest.bind(i),false,"Quest%d"%i)
		claim.custom_minimum_size = Vector2(65,44)
		claim.size_flags_horizontal = Control.SIZE_SHRINK_END
		claim.disabled = claimed or (int(progress.data.quest_actions)<6 if i == 0 else int(progress.data.quest_completes)<1)
		quest.add_child(claim)
	var bottom: HBoxContainer = row(body)
	bottom.add_child(button("Planner journal",show_journal,false,"Journal"))
	bottom.add_child(button("How to play",start_tutorial.bind(0),false,"Tutorial"))
	if not toast.is_empty(): body.add_child(label(toast,16,MUTED)); toast = ""

func claim_quest(index: int) -> void:
	if progress.claim_quest(index,now()): save(); sync_metrics()
	show_home()

func show_commissions() -> void:
	clear_page("commissions")
	header(show_home)
	body.add_child(label("The commission book",30))
	body.add_child(label("Eight homes open the next chapter. Revisit any room to find its thoughtful detail.",17,MUTED))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",8)
	scroll.add_child(list)
	for chapter in range(6):
		var unlocked: bool = progress.chapter_unlocked(chapter)
		list.add_child(label("%02d  %s%s" % [chapter+1,puzzle.content.chapters[chapter],"" if unlocked else "  ·  opens at %d homes" % (chapter*8)],23))
		for i in range(chapter*10,chapter*10+10):
			var done: bool = progress.data.cleared.has(str(i))
			var detail: bool = progress.data.requests.has(str(i))
			var text: String = "%02d   %s   %s" % [i+1,puzzle.content.rooms[i].name,"★" if detail else ("✓" if done else "→")]
			var entry: Button = button(text,start_room.bind(i,false),false,"Commission%d"%i)
			entry.alignment = HORIZONTAL_ALIGNMENT_LEFT
			entry.disabled = not unlocked
			list.add_child(entry)

func start_room(id: int, daily: bool = false) -> void:
	active_id = clampi(id,0,59)
	daily_mode = daily
	tutorial = -1
	puzzle.load_room(active_id)
	if progress.data.has("drafts") and progress.data.drafts.has(str(active_id)):
		for p in progress.data.drafts[str(active_id)]:
			if p is Dictionary and p.has_all(["key","x","y","r"]) and puzzle.furniture.has(str(p.key)):
				puzzle.place(str(p.key),int(p.x),int(p.y),clampi(int(p.r),0,3))
		puzzle.history = []
	selected = ""
	quarter_turn = 0
	completed_this_visit = false
	show_puzzle()

func start_daily() -> void:
	start_room(progress.daily_id(now()),true)

func start_tutorial(index: int) -> void:
	tutorial = index
	daily_mode = false
	puzzle.load_room(index)
	puzzle.room.id = -10-index
	puzzle.room.name = "A Chair and a Light" if index == 0 else "A Desk by Daylight"
	puzzle.room.items = ["chair","lamp"] if index == 0 else ["desk","chair","lamp","plant"]
	puzzle.room.daylight = index == 1
	puzzle.room.solution = [{"key":"chair","x":0,"y":0,"r":1},{"key":"lamp","x":1,"y":0,"r":1}] if index == 0 else puzzle.content.rooms[1].solution.duplicate(true)
	selected = ""
	quarter_turn = 0
	completed_this_visit = false
	show_puzzle()

func start_decoration() -> void:
	tutorial = -1
	daily_mode = false
	puzzle.load_decoration()
	for p in progress.data.decor_layout:
		if p is Dictionary and p.has_all(["key","x","y","r"]) and puzzle.furniture.has(str(p.key)):
			puzzle.place(str(p.key),int(p.x),int(p.y),clampi(int(p.r),0,3))
	puzzle.history = []
	selected = ""
	quarter_turn = 0
	show_puzzle()

func show_puzzle() -> void:
	var decoration: bool = int(puzzle.room.id) == -1
	clear_page("decoration" if decoration else "puzzle")
	header(leave_room)
	body.add_child(label(str(puzzle.room.name),28))
	var context: String = "YOUR QUIET CORNER" if decoration else ("TUTORIAL %d OF 2" % (tutorial+1) if tutorial >= 0 else ("TODAY’S COMMISSION" if daily_mode else "%s  ·  %02d / 60" % [puzzle.content.chapters[int(puzzle.room.chapter)],active_id+1]))
	body.add_child(label(context,13,MUTED))
	criteria = VBoxContainer.new()
	criteria.add_theme_constant_override("separation",2)
	body.add_child(criteria)
	board = make_board(body,puzzle,260)
	board.cell_chosen.connect(place_selected)
	board.item_chosen.connect(select_item)
	var tools: HBoxContainer = row(body)
	tools.add_child(button("↻ Rotate",rotate_selected,false,"Rotate"))
	tools.add_child(button("Lift",remove_selected,false,"Lift"))
	tools.add_child(button("Undo",undo_move,false,"Undo"))
	tools.add_child(button("Reset",reset_room,false,"Reset"))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size.y = 105
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	tray = HBoxContainer.new()
	tray.add_theme_constant_override("separation",8)
	scroll.add_child(tray)
	message_label = label("Choose a piece below, then tap a floor tile. Tap a placed piece to move it.",16,MUTED)
	message_label.custom_minimum_size.y = 44
	body.add_child(message_label)
	var final_row: HBoxContainer = row(body)
	final_row.add_child(button("Paths",toggle_paths,false,"Paths"))
	final_row.add_child(button("Plan tip",plan_tip,false,"Tip"))
	var reward_available: bool = bool(call_service("can_reward"))
	var hint: Button = button("Hint · ad",request_hint,false,"RewardHint")
	hint.disabled = not reward_available or decoration
	final_row.add_child(hint)
	submit_button = button("Save my corner" if decoration else "Welcome home  ✓",finish_room,true,"Complete")
	body.add_child(submit_button)
	if tutorial >= 0:
		message_label.text = "Place both pieces. A lamp belongs within two steps of a seat. The outlined door tiles stay empty." if tutorial == 0 else "Put the desk on the window row. Each piece’s front needs a path from the green door tile."
	refresh_puzzle()

func select_item(key: String) -> void:
	selected = key
	for p in puzzle.placed:
		if str(p.key) == key: quarter_turn = int(p.r)
	board.selected = selected
	board.quarter_turn = quarter_turn
	board.hover = Vector2i(-1,-1)
	message_label.text = "%s selected · tap a floor tile, or rotate before placing." % puzzle.furniture[key].name
	refresh_tray()

func refresh_tray() -> void:
	for child in tray.get_children(): tray.remove_child(child); child.queue_free()
	for key in puzzle.room.items:
		var card: Button = button("",select_item.bind(str(key)),false,"Furniture"+str(key))
		card.custom_minimum_size = Vector2(94,91)
		card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		card.add_theme_stylebox_override("normal",style(Color("d2e2d2") if selected == str(key) else Color("ece5d6"),INK if selected == str(key) else Color.TRANSPARENT))
		var contents: VBoxContainer = VBoxContainer.new()
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.offset_top = 6
		contents.offset_bottom = -5
		card.add_child(contents)
		var art: TextureRect = TextureRect.new()
		art.texture = board.texture(str(key),quarter_turn if selected == str(key) else 0)
		art.custom_minimum_size = Vector2(48,48)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(art)
		var name_label: Label = label(("✓ " if puzzle.has_item(str(key)) else "")+str(key).capitalize(),14)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(name_label)
		tray.add_child(card)

func refresh_puzzle() -> void:
	board.selected = selected
	board.quarter_turn = quarter_turn
	board.palette = int(progress.data.palette)
	for child in criteria.get_children(): criteria.remove_child(child); child.queue_free()
	if int(puzzle.room.id) != -1:
		var result: Dictionary = puzzle.evaluate()
		var line1: String = "%s All pieces     %s Clear door     %s Usable fronts" % ["✓" if result.all_placed else "○","✓" if result.clear else "○","✓" if result.paths else "○"]
		var line2: String = "%s Reading light" % ("✓" if result.reading else "○")
		if bool(puzzle.room.daylight): line2 += "     %s Desk in daylight" % ("✓" if result.daylight and puzzle.has_item("desk") else "○")
		criteria.add_child(label(line1,15))
		criteria.add_child(label(line2,15))
		var wish: String = {"plant":"Fern beside a window","shelf":"Bookcase against a back wall","cabinet":"Cabinet within two steps of the bed"}.get(str(puzzle.room.optional),"")
		if tutorial < 0: criteria.add_child(label(("★ " if result.optional else "☆ ")+"Optional · "+wish,14,MUTED))
		submit_button.disabled = not result.complete
	else:
		criteria.add_child(label("A free space. Cosmetics never change puzzle rules.",16,MUTED))
	refresh_tray()
	board.queue_redraw()

func remember_draft() -> void:
	if int(puzzle.room.id) >= 0:
		if not progress.data.has("drafts"): progress.data.drafts = {}
		progress.data.drafts[str(active_id)] = puzzle.placed.duplicate(true)
	elif int(puzzle.room.id) == -1: progress.data.decor_layout = puzzle.placed.duplicate(true)
	save()

func place_selected(cell: Vector2i) -> void:
	if selected.is_empty(): return
	var issue: String = puzzle.placement_issue(selected,cell.x,cell.y,quarter_turn)
	if not issue.is_empty(): message_label.text = issue; return
	if puzzle.place(selected,cell.x,cell.y,quarter_turn):
		board.flash_cell = cell
		board.flash_time = .65
		if is_instance_valid(click_sound): click_sound.play()
		progress.action("place",now())
		message_label.text = "%s placed. Green dots show reachable usable fronts." % puzzle.furniture[selected].name
		board.hints = {}
		selected = ""
		remember_draft()
		refresh_puzzle()

func rotate_selected() -> void:
	if selected.is_empty(): message_label.text = "Choose a piece to rotate first."; return
	quarter_turn = (quarter_turn+1)%4
	progress.action("rotate",now())
	board.quarter_turn = quarter_turn
	refresh_tray()
	message_label.text = "Turned a quarter turn. Tap a floor tile to place it."
	save()

func remove_selected() -> void:
	if selected.is_empty(): message_label.text = "Tap a placed piece, then Lift."; return
	if puzzle.remove(selected):
		progress.action("lift",now())
		remember_draft()
		refresh_puzzle()
	message_label.text = "Piece lifted. Choose a new tile, or choose another piece."

func undo_move() -> void:
	if puzzle.undo():
		progress.action("undo",now())
		selected = ""
		remember_draft()
		refresh_puzzle()
		message_label.text = "One move back. There is always room to rethink."

func reset_room() -> void:
	puzzle.reset()
	selected = ""
	board.hints = {}
	remember_draft()
	refresh_puzzle()
	message_label.text = "A fresh floor. Undo can bring the whole arrangement back."

func toggle_paths() -> void:
	board.show_paths = not board.show_paths
	message_label.text = "Dots show floor reachable from the entrance; green front dots mean furniture can be used." if board.show_paths else "Paths hidden. The room rules still check every usable front."

func plan_tip() -> void:
	board.show_paths = true
	var result: Dictionary = puzzle.evaluate()
	if not result.all_placed: message_label.text = "Give large pieces a home near the edges, leaving a path through the middle."
	elif not result.paths: message_label.text = "A piece’s usable front is blocked. Rotate it toward open floor, or make a gap."
	elif not result.reading: message_label.text = "Bring the floor lamp within two steps of the chair, sofa, bed, or dining chair."
	elif not result.daylight: message_label.text = "The writing desk needs the top window row. Its front still needs a path."
	else: message_label.text = "The required needs are met. Try the optional wish, or welcome this household home."

func request_hint() -> void:
	if not bool(call_service("can_reward")): message_label.text = "A rewarded hint is unavailable. Plan tips, undo and reset are always free."; return
	var token: int = progress.begin_reward()
	if token == 0: return
	var room_id: int = int(puzzle.room.id)
	message_label.text = "Opening a rewarded hint…"
	call_service("reward_requested",["precise_placement_hint",func(earned: bool) -> void: receive_hint(token,earned,room_id)])

func receive_hint(token: int, earned: bool, room_id: int) -> void:
	if not progress.finish_reward(token,earned): return
	if not is_instance_valid(board) or int(puzzle.room.id) != room_id: return
	var hint: Dictionary = puzzle.next_hint()
	if hint.is_empty(): message_label.text = "You have already found the recorded arrangement."; return
	board.hints = hint
	selected = str(hint.key)
	quarter_turn = int(hint.r)
	board.hover = Vector2i(int(hint.x),int(hint.y))
	message_label.text = "One possible plan: %s, column %d · row %d · turn %d. Move other pieces if its footprint is occupied." % [puzzle.furniture[hint.key].name,int(hint.x)+1,int(hint.y)+1,int(hint.r)+1]
	refresh_puzzle()

func leave_room() -> void:
	remember_draft()
	selected = ""
	show_home()

func finish_room() -> void:
	if int(puzzle.room.id) == -1:
		progress.data.decor_layout = puzzle.placed.duplicate(true)
		if not puzzle.placed.is_empty(): progress.data.decorations = 1
		save()
		sync_metrics()
		toast = "Your quiet corner is saved. Come back whenever you like."
		show_home()
		return
	var result: Dictionary = puzzle.evaluate()
	if not result.complete: return
	if tutorial >= 0:
		if not progress.data.tutorials.has(tutorial): progress.data.tutorials.append(tutorial); progress.data.xp = int(progress.data.xp)+10
		save()
		if tutorial == 0: start_tutorial(1)
		else: toast = "You’re ready. Every room accepts many thoughtful arrangements."; show_home()
		return
	var reward: Dictionary = progress.complete(active_id,bool(result.optional),daily_mode,now())
	if not completed_this_visit and (reward.first or reward.daily): call_service("round_finished")
	completed_this_visit = true
	remember_draft()
	sync_metrics()
	clear_page("result")
	header(show_home)
	body.add_child(label("Welcome home.",38))
	body.add_child(label("%s now has room for a good life." % str(puzzle.room.name),20,MUTED))
	board = make_board(body,puzzle,330,true)
	var card: VBoxContainer = panel(body,Color("dce7d8"))
	card.add_child(label("✓ A clear entrance   ✓ Useful furniture   ✓ A reading light",17))
	card.add_child(label("★ Thoughtful detail included" if result.optional else "☆ Revisit anytime for the optional wish",19))
	card.add_child(label("+%d coins    +%d planner XP" % [int(reward.coins),int(reward.xp)],24))
	card.add_child(label("Rewards are saved once; new optional details earn their own bonus.",15,MUTED))
	if active_id < 59 and progress.chapter_unlocked(int((active_id+1)/10)):
		body.add_child(button("The next little room  →",start_room.bind(active_id+1,false),true,"NextRoom"))
	body.add_child(button("Back to the commission book",show_commissions,false,"Book"))
	body.add_child(button("Return to my doorstep",show_home,false,"Home"))

func sync_metrics() -> void:
	if test_mode: return
	var metrics: Dictionary = progress.metrics()
	for ach in catalog.achievements:
		if int(metrics.get(ach.metric,0)) >= int(ach.threshold):
			call_service("unlock",[str(ach.key)])
	for leaderboard in catalog.leaderboards: call_service("submit",[str(leaderboard.key),int(metrics.get(leaderboard.metric,0))])
	save()

func show_journal() -> void:
	clear_page("journal")
	header(show_home)
	body.add_child(label("The planner journal",30))
	body.add_child(label("Level %d · %d XP · %d thoughtful details" % [progress.level(),int(progress.data.xp),progress.requests()],18,MUTED))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",9)
	scroll.add_child(list)
	var cosmetics: VBoxContainer = panel(list)
	cosmetics.add_child(label("A different kind of light",23))
	cosmetics.add_child(label("Palettes change the floor’s colour. Every puzzle stays freely solvable.",16,MUTED))
	var names: Array[String] = ["Honey oak","Garden sage","Evening lilac","Morning gold"]
	for i in range(4):
		var owned: bool = progress.data.owned_palettes.has(i)
		var text: String = "%s  ·  %s" % [names[i],"selected" if int(progress.data.palette)==i else ("use palette" if owned else "%d coins" % (i*120))]
		var choose: Button = button(text,choose_palette.bind(i),false,"Palette%d"%i)
		choose.disabled = not owned and int(progress.data.coins) < i*120
		cosmetics.add_child(choose)
	var metrics: Dictionary = progress.metrics()
	list.add_child(label("Little milestones",24))
	for ach in catalog.achievements:
		var met: bool = int(metrics.get(ach.metric,0)) >= int(ach.threshold)
		var card: VBoxContainer = panel(list,Color("dce7d8") if met else Color("e8e5d7"))
		card.add_child(label(("✦ " if met else "○ ")+str(ach.name),20))
		card.add_child(label("%s · %d / %d" % [str(ach.metric).capitalize(),mini(int(ach.threshold),int(metrics.get(ach.metric,0))),int(ach.threshold)],16,MUTED))
	list.add_child(label("Play services",24))
	var native_status: Variant = call_service("status")
	list.add_child(label(str(native_status) if native_status != null else "Local progress is available offline. Online play services are unavailable on this platform.",16,MUTED))
	list.add_child(button("Sign in to Play Games",func() -> void: call_service("sign_in")))
	list.add_child(button("Online achievements",func() -> void: call_service("open_achievements")))
	for b in catalog.leaderboards:
		list.add_child(button(str(b.name),func() -> void: call_service("open_leaderboards",[str(b.key)])))
	list.add_child(button("Privacy options",func() -> void: call_service("privacy_options")))
	list.add_child(button("Music: "+("on" if bool(progress.data.music) else "off"),toggle_music,false,"Music"))
	list.add_child(label("Room for Tomorrow · original work Apache-2.0\nFurniture Kit & Interface Sounds by Kenney · CC0\nDaily commissions use UTC. A clock rewind cannot claim an earlier day. Your progress stays on this device.",15,MUTED))

func choose_palette(index: int) -> void:
	if progress.buy_palette(index): save()
	show_journal()

func toggle_music() -> void:
	progress.data.music = not bool(progress.data.music)
	if is_instance_valid(music):
		if progress.data.music: music.play()
		else: music.stop()
	save()
	show_journal()
