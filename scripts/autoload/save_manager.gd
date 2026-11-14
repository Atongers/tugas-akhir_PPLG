extends Node

## SaveManager Autoload: Menyimpan progres skin, level selesai, debug tools, dan Bug Log ke user://save_data.json.

signal skin_changed(skin_id: String)
signal progression_updated()

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1

const SKIN_METADATA := {
	"default": {
		"id": "default",
		"name": "Cyan Debugger",
		"subtitle": "Unit Standar Syntax Shore",
		"sheet_path": "res://assets/sprites/characters/dex_skin_default.png",
		"col_index": 0,
		"trail_color": Color("#38bdf8"),
		"unlock_hint": "Terbuka sejak awal",
	},
	"volt_scout": {
		"id": "volt_scout",
		"name": "Volt Scout",
		"subtitle": "Armor Pengintai Bertegangan Tinggi",
		"sheet_path": "res://assets/sprites/characters/dex_skin_volt_scout.png",
		"col_index": 1,
		"trail_color": Color("#fbbf24"),
		"unlock_hint": "Tamatkan Level 2",
	},
	"plasma_sentinel": {
		"id": "plasma_sentinel",
		"name": "Plasma Sentinel",
		"subtitle": "Armor Penjaga Inti Reaktor",
		"sheet_path": "res://assets/sprites/characters/dex_skin_plasma_sentinel.png",
		"col_index": 2,
		"trail_color": Color("#e879f9"),
		"unlock_hint": "Tamatkan Level 3",
	},
}

const TOOL_METADATA := {
	"output": {
		"id": "output",
		"name": "Output Console",
		"description": "Panel output standar Python & print().",
	},
	"print_tool": {
		"id": "print_tool",
		"name": "Quick-Insert Print Tool",
		"description": "Tombol [+ Sisipkan print()] untuk mempercepat inspeksi variabel di Terminal.",
	},
	"speed_selector": {
		"id": "speed_selector",
		"name": "Speed Selector 2x & Skip",
		"description": "Percepat atau lewati animasi eksekusi baris kode di Terminal.",
	},
}

var active_skin: String = "default"
var unlocked_skins: Array[String] = ["default"]
var completed_levels: Array[String] = []
var unlocked_tools: Array[String] = ["output"]
var unlocked_bug_logs: Array[String] = ["BUG-01", "BUG-02", "BUG-03", "BUG-04", "BUG-05"]


func _ready() -> void:
	load_save()


func _apply_defaults() -> void:
	active_skin = "default"
	unlocked_skins = ["default"]
	completed_levels = []
	unlocked_tools = ["output"]
	unlocked_bug_logs = ["BUG-01", "BUG-02", "BUG-03", "BUG-04", "BUG-05"]


func load_save() -> void:
	_apply_defaults()
	if not FileAccess.file_exists(SAVE_PATH):
		save_data()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		save_data()
		return

	var d: Dictionary = parsed
	if d.has("unlocked_skins") and typeof(d["unlocked_skins"]) == TYPE_ARRAY:
		unlocked_skins.clear()
		for s in d["unlocked_skins"]:
			var sid := str(s)
			if SKIN_METADATA.has(sid) and not unlocked_skins.has(sid):
				unlocked_skins.append(sid)
		if not unlocked_skins.has("default"):
			unlocked_skins.insert(0, "default")

	if d.has("active_skin"):
		var req_skin := str(d["active_skin"])
		active_skin = req_skin if unlocked_skins.has(req_skin) else "default"

	if d.has("completed_levels") and typeof(d["completed_levels"]) == TYPE_ARRAY:
		completed_levels.clear()
		for lv in d["completed_levels"]:
			var lvid := str(lv)
			if not completed_levels.has(lvid):
				completed_levels.append(lvid)

	if d.has("unlocked_tools") and typeof(d["unlocked_tools"]) == TYPE_ARRAY:
		unlocked_tools.clear()
		for tl in d["unlocked_tools"]:
			var tid := str(tl)
			if not unlocked_tools.has(tid):
				unlocked_tools.append(tid)
		if not unlocked_tools.has("output"):
			unlocked_tools.insert(0, "output")

	if d.has("unlocked_bug_logs") and typeof(d["unlocked_bug_logs"]) == TYPE_ARRAY:
		unlocked_bug_logs.clear()
		for bg in d["unlocked_bug_logs"]:
			var bid := str(bg)
			if not unlocked_bug_logs.has(bid):
				unlocked_bug_logs.append(bid)


func save_data() -> void:
	var payload := {
		"version": SAVE_VERSION,
		"active_skin": active_skin,
		"unlocked_skins": unlocked_skins,
		"completed_levels": completed_levels,
		"unlocked_tools": unlocked_tools,
		"unlocked_bug_logs": unlocked_bug_logs,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))
		file.close()


func get_all_skin_ids() -> Array[String]:
	return ["default", "volt_scout", "plasma_sentinel"]


func get_skin_metadata(skin_id: String) -> Dictionary:
	if SKIN_METADATA.has(skin_id):
		return SKIN_METADATA[skin_id]
	return SKIN_METADATA["default"]


func is_skin_unlocked(skin_id: String) -> bool:
	return unlocked_skins.has(skin_id)


func is_tool_unlocked(tool_id: String) -> bool:
	return unlocked_tools.has(tool_id)


func is_level_completed(level_id: String) -> bool:
	return completed_levels.has(level_id)


func is_bug_log_unlocked(bug_id: String) -> bool:
	return unlocked_bug_logs.has(bug_id)


func equip_skin(skin_id: String) -> bool:
	if not unlocked_skins.has(skin_id):
		return false
	if active_skin != skin_id:
		active_skin = skin_id
		save_data()
		skin_changed.emit(active_skin)
		progression_updated.emit()
	return true


func unlock_bug_log(bug_id: String) -> void:
	if bug_id.is_empty():
		return
	if not unlocked_bug_logs.has(bug_id):
		unlocked_bug_logs.append(bug_id)
		save_data()
		progression_updated.emit()


func record_level_completion(level_id: String) -> Array[Dictionary]:
	var newly_unlocked: Array[Dictionary] = []
	var changed := false

	if not completed_levels.has(level_id):
		completed_levels.append(level_id)
		changed = true

	match level_id:
		"world_1_level_1":
			for bid in ["BUG-01", "BUG-02", "BUG-03", "BUG-04", "BUG-05"]:
				if not unlocked_bug_logs.has(bid):
					unlocked_bug_logs.append(bid)
					changed = true
		"world_1_level_2":
			if not unlocked_skins.has("volt_scout"):
				unlocked_skins.append("volt_scout")
				newly_unlocked.append({"type": "skin", "id": "volt_scout", "name": "Skin: Volt Scout", "desc": "Armor amber dengan jejak sprint elektrik #fbbf24"})
				changed = true
			if not unlocked_tools.has("print_tool"):
				unlocked_tools.append("print_tool")
				newly_unlocked.append({"type": "tool", "id": "print_tool", "name": "Debug Tool: Quick-Insert Print", "desc": "Tombol [+ Sisipkan print()] kini aktif di Terminal"})
				changed = true
			for bid in ["BUG-06", "BUG-07", "BUG-08"]:
				if not unlocked_bug_logs.has(bid):
					unlocked_bug_logs.append(bid)
					newly_unlocked.append({"type": "bug_log", "id": bid, "name": "Bug Log: " + bid, "desc": "Entri katalog bug baru terbuka di Main Menu"})
					changed = true
		"world_1_level_3":
			if not unlocked_skins.has("plasma_sentinel"):
				unlocked_skins.append("plasma_sentinel")
				newly_unlocked.append({"type": "skin", "id": "plasma_sentinel", "name": "Skin: Plasma Sentinel", "desc": "Armor magenta dengan jejak sprint plasma #e879f9"})
				changed = true
			if not unlocked_tools.has("speed_selector"):
				unlocked_tools.append("speed_selector")
				newly_unlocked.append({"type": "tool", "id": "speed_selector", "name": "Debug Tool: Speed 2x & Skip", "desc": "Eksekusi kode cepat 2x & Skip kini aktif di Terminal"})
				changed = true
			for bid in ["BUG-09", "BUG-10"]:
				if not unlocked_bug_logs.has(bid):
					unlocked_bug_logs.append(bid)
					newly_unlocked.append({"type": "bug_log", "id": bid, "name": "Bug Log: " + bid, "desc": "Entri katalog bug baru terbuka di Main Menu"})
					changed = true

	if changed:
		save_data()
		progression_updated.emit()

	return newly_unlocked


func reset_progression() -> void:
	_apply_defaults()
	save_data()
	skin_changed.emit(active_skin)
	progression_updated.emit()
