extends RefCounted

const VERSION: int = 1
const MAX_COINS: int = 1000000
var data: Dictionary = {}
var reward_token: int = 0
var pending_reward: int = 0

func _init() -> void:
	data = fresh()

func fresh() -> Dictionary:
	return {"version":VERSION,"coins":0,"xp":0,"cleared":{},"requests":{},"rotations":0,"undos":0,"dailies":0,
		"daily_claimed":{},"quest_claimed":{},"quest_day":-1,"quest_actions":0,"quest_completes":0,
		"decorations":0,"decor_layout":[],"drafts":{},"palette":0,"owned_palettes":[0],"music":true,"tutorials":[],"last_day":-1,"unlocked":{}}

func day(now: int) -> int:
	return maxi(0, int(now / 86400))

func roll_day(now: int) -> int:
	# Rewinding the clock cannot create an earlier daily reward opportunity.
	var today: int = maxi(day(now), int(data.last_day))
	data.last_day = today
	if today != int(data.quest_day):
		data.quest_day = today
		data.quest_actions = 0
		data.quest_completes = 0
	return today

func daily_id(now: int) -> int:
	return (roll_day(now) * 17 + 11) % 60

func level() -> int:
	return 1 + int(sqrt(float(data.xp) / 40.0))

func chapter_unlocked(chapter: int) -> bool:
	return chapter == 0 or completed() >= chapter * 8

func chapters() -> int:
	return mini(6, 1 + int(completed()/8))

func completed() -> int:
	return data.cleared.size()

func requests() -> int:
	return data.requests.size()

func action(kind: String, now: int) -> void:
	roll_day(now)
	data.quest_actions = mini(100000, int(data.quest_actions)+1)
	if kind == "rotate": data.rotations = mini(1000000, int(data.rotations)+1)
	if kind == "undo": data.undos = mini(1000000, int(data.undos)+1)

func complete(id: int, optional: bool, daily: bool, now: int) -> Dictionary:
	if id < 0 or id >= 60: return {"coins":0,"xp":0,"first":false,"daily":false,"optional":false}
	var today: int = roll_day(now)
	var key: String = str(id)
	var first: bool = not data.cleared.has(key)
	var detail: bool = optional and not data.requests.has(key)
	var daily_bonus: bool = daily and id == daily_id(now) and not data.daily_claimed.has(str(today))
	var coins: int = 0
	var xp: int = 0
	if first:
		data.cleared[key] = true
		coins += 45 + int(id/10)*10
		xp += 35
		data.quest_completes = int(data.quest_completes)+1
	if detail:
		data.requests[key] = true
		coins += 15
		xp += 10
	if daily_bonus:
		data.daily_claimed[str(today)] = true
		data.dailies = int(data.dailies)+1
		coins += 80
		xp += 30
	data.coins = mini(MAX_COINS,int(data.coins)+coins)
	data.xp = mini(MAX_COINS,int(data.xp)+xp)
	return {"coins":coins,"xp":xp,"first":first,"daily":daily_bonus,"optional":detail}

func claim_quest(index: int, now: int) -> bool:
	var today: int = roll_day(now)
	var key: String = "%d:%d" % [today,index]
	if data.quest_claimed.has(key): return false
	var ready: bool = (index == 0 and int(data.quest_actions) >= 6) or (index == 1 and int(data.quest_completes) >= 1)
	if not ready: return false
	data.quest_claimed[key] = true
	data.coins = mini(MAX_COINS,int(data.coins)+25)
	data.xp = mini(MAX_COINS,int(data.xp)+10)
	return true

func buy_palette(index: int) -> bool:
	if index < 0 or index > 3: return false
	if not data.owned_palettes.has(index):
		var cost: int = index * 120
		if int(data.coins) < cost: return false
		data.coins = int(data.coins)-cost
		data.owned_palettes.append(index)
	data.palette = index
	return true

func begin_reward() -> int:
	if pending_reward != 0: return 0
	reward_token += 1
	pending_reward = reward_token
	return pending_reward

func finish_reward(token: int, earned: bool) -> bool:
	if token == 0 or token != pending_reward: return false
	pending_reward = 0
	return earned

func metrics() -> Dictionary:
	return {"commissions":completed(),"requests":requests(),"xp":int(data.xp),"level":level(),"dailies":int(data.dailies),"decorations":int(data.decorations),"rotations":int(data.rotations),"undos":int(data.undos),"chapters":chapters()}

func encode() -> String:
	return JSON.stringify(data)

func decode(raw: String) -> bool:
	if raw.length() > 1000000: return false
	var parser: JSON = JSON.new()
	if parser.parse(raw) != OK: return false
	var parsed: Variant = parser.data
	if not parsed is Dictionary: return false
	var saved_version: Variant = parsed.get("version",0)
	if not (saved_version is int or saved_version is float): return false
	if not is_finite(float(saved_version)) or float(saved_version) != VERSION: return false
	var result: Dictionary = fresh()
	for key in result:
		if not parsed.has(key): continue
		if typeof(result[key]) == TYPE_DICTIONARY and parsed[key] is Dictionary: result[key] = parsed[key].duplicate(true)
		elif typeof(result[key]) == TYPE_ARRAY and parsed[key] is Array: result[key] = parsed[key].duplicate(true)
		elif typeof(result[key]) == TYPE_BOOL and parsed[key] is bool: result[key] = parsed[key]
		elif typeof(result[key]) == TYPE_INT and (parsed[key] is float or parsed[key] is int):
			var value: float = float(parsed[key])
			if is_finite(value): result[key] = clampi(int(value),-1,MAX_COINS)
	for key in ["cleared","requests"]:
		var clean: Dictionary = {}
		for id in result[key]:
			if str(id).is_valid_int() and int(id) >= 0 and int(id) < 60 and bool(result[key][id]): clean[str(int(id))] = true
		result[key] = clean
	result.coins = maxi(0,int(result.coins))
	result.xp = maxi(0,int(result.xp))
	result.palette = clampi(int(result.palette),0,3)
	result.owned_palettes = result.owned_palettes.filter(func(v: Variant) -> bool: return (v is int or v is float) and int(v) >= 0 and int(v) <= 3).map(func(v: Variant) -> int: return int(v))
	if not result.owned_palettes.has(0): result.owned_palettes.append(0)
	if not result.owned_palettes.has(result.palette): result.palette = 0
	result.tutorials = result.tutorials.filter(func(v: Variant) -> bool: return v is int or v is float).map(func(v: Variant) -> int: return clampi(int(v),0,1))
	result.decor_layout = sanitize_layout(result.decor_layout)
	var clean_drafts: Dictionary = {}
	for id in result.drafts:
		if str(id).is_valid_int() and int(id) >= 0 and int(id) < 60:
			clean_drafts[str(int(id))] = sanitize_layout(result.drafts[id])
	result.drafts = clean_drafts
	data = result
	pending_reward = 0
	return true

func sanitize_layout(value: Variant) -> Array:
	var out: Array = []
	if not value is Array: return out
	var allowed: Array[String] = ["desk","bed","sofa","chair","lamp","plant","shelf","table","stool","dining","cabinet","coat"]
	var seen: Dictionary = {}
	for p in value.slice(0,12):
		if not p is Dictionary or not p.has_all(["key","x","y","r"]): continue
		if not p.key is String or not allowed.has(p.key) or seen.has(p.key): continue
		var valid: bool = true
		for field in ["x","y","r"]:
			if not (p[field] is int or p[field] is float) or not is_finite(float(p[field])): valid = false
		if not valid: continue
		if int(p.x)<0 or int(p.x)>7 or int(p.y)<0 or int(p.y)>7 or int(p.r)<0 or int(p.r)>3: continue
		out.append({"key":str(p.key),"x":int(p.x),"y":int(p.y),"r":int(p.r)})
		seen[p.key] = true
	return out

func save_to(path: String) -> bool:
	var file: FileAccess = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: return false
	file.store_string(encode())
	file.close()
	var error: Error = DirAccess.rename_absolute(path+".tmp",path)
	return error == OK

func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	return decode(FileAccess.get_file_as_string(path))
