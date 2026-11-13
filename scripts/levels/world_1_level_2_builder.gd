@tool
extends Node2D

const TILESET_PATH := "res://resources/tilesets/world_1_tileset.tres"
const DEX_SPAWN_POS := Vector2(64.0, 384.0)
const TOTAL_TERMINALS := 5

const TERMINAL_CONFIGS := {
	"Terminal_1": {
		"index": 1,
		"title": "TERMINAL 1: PRIORITAS DAYA LASER PATROLI",
		"objective": "Perbaiki urutan operasi matematika (PEMDAS) agar total_daya bernilai 60.",
		"initial_code": [
			"daya_dasar = 10",
			"pengali = 4",
			"total_daya = daya_dasar + 5 * pengali",
			"matikan_laser_patroli(total_daya)"
		],
		"locked_lines": [0, 1, 3],
		"required_call": "matikan_laser_patroli",
		"expected_arg": 60,
		"require_print": false,
		"expected_print": "",
		"logical_fail_hint": "Saat ini hasilnya 30 karena perkalian (*) dihitung sebelum penjumlahan (+). Gunakan tanda kurung ( ) agar hasilnya 60!",
		"success_message": "Laser Patroli Sektor 1 dimatikan! Lanjut ke Terminal 2 untuk sinkronisasi Elevator.",
		"hints": [
			"Lint: \"Di Python, perkalian (*) dikerjakan lebih dulu daripada penjumlahan (+).\"",
			"Lint: \"10 + 5 * 4 dihitung sebagai 10 + 20 = 30. Kita ingin (10 + 5) dihitung lebih dulu!\"",
			"Lint: \"Ubah baris 3 menjadi: total_daya = (daya_dasar + 5) * pengali\""
		],
		"bug_log_entry": {
			"terminal_id": "Terminal_1",
			"bug_type": "Logical Bug (Prioritas Operator PEMDAS)",
			"broken_code": "total_daya = daya_dasar + 5 * pengali",
			"fixed_code": "total_daya = (daya_dasar + 5) * pengali",
			"explanation": "Operator * memiliki prioritas lebih tinggi dari +. Gunakan tanda kurung () untuk memaksa penjumlahan dijalankan terlebih dahulu."
		}
	},
	"Terminal_2": {
		"index": 2,
		"title": "TERMINAL 2: SINKRONISASI MODULO ELEVATOR",
		"objective": "Perbaiki operator pembagi sisa (modulo %) agar sisa_siklus bernilai 3.",
		"initial_code": [
			"tick_mesin = 15",
			"pembagi = 5",
			"sisa_siklus = tick_mesin % pembagi",
			"sinkronisasi_elevator(sisa_siklus)"
		],
		"locked_lines": [0, 2, 3],
		"required_call": "sinkronisasi_elevator",
		"expected_arg": 3,
		"require_print": false,
		"expected_print": "",
		"logical_fail_hint": "15 % 5 bersisa 0! Ubah nilai pembagi (misal 4) agar sisa bagi 15 % pembagi tepat bernilai 3.",
		"success_message": "Elevator Sektor 1-2 aktif! Naik ke atas menuju CapsulePod Checkpoint Sektor 2.",
		"hints": [
			"Lint: \"Operator % (modulo) menghasilkan SISA pembagian. 15 dibagi 5 sisanya 0.\"",
			"Lint: \"Jika pembagi = 4, maka 15 dibagi 4 = 3 sisa 3!\"",
			"Lint: \"Ubah baris 2 menjadi: pembagi = 4\""
		],
		"bug_log_entry": {
			"terminal_id": "Terminal_2",
			"bug_type": "Logical Bug (Operator Modulo %)",
			"broken_code": "pembagi = 5  # 15 % 5 == 0",
			"fixed_code": "pembagi = 4  # 15 % 4 == 3",
			"explanation": "Operator modulo (%) mengembalikan sisa hasil bagi. Mengubah pembagi dari 5 menjadi 4 membuat 15 % 4 menghasilkan sisa 3."
		}
	},
	"Terminal_3": {
		"index": 3,
		"title": "TERMINAL 3: OVERWRITE FREKUENSI SCANNER",
		"objective": "Hapus atau perbaiki baris yang menimpa nilai kode_scanner agar tetap bernilai 80.",
		"initial_code": [
			"kode_scanner = 80",
			"mode_aman = True",
			"kode_scanner = 20",
			"matikan_scanner(kode_scanner)"
		],
		"locked_lines": [3],
		"required_call": "matikan_scanner",
		"expected_arg": 80,
		"require_print": false,
		"expected_print": "",
		"logical_fail_hint": "Nilai kode_scanner berubah menjadi 20 sebelum dikirim! Pastikan kode_scanner tetap 80.",
		"success_message": "Turret Spotlight Scanner dinonaktifkan! Naik ke platform kanan untuk mengakses Terminal 4.",
		"hints": [
			"Lint: \"Perhatikan baris 1 dan baris 3! Variabel kode_scanner diberi nilai dua kali.\"",
			"Lint: \"Baris 3 menimpa nilai 80 dengan angka 20.\"",
			"Lint: \"Ubah baris 3 menjadi kode_scanner = 80 atau hapus baris tersebut.\""
		],
		"bug_log_entry": {
			"terminal_id": "Terminal_3",
			"bug_type": "Logical Bug (Variable Overwrite)",
			"broken_code": "kode_scanner = 80\n...\nkode_scanner = 20",
			"fixed_code": "kode_scanner = 80",
			"explanation": "Menulis ulang variabel yang sama dengan nilai baru sebelum dipakai menimpa nilai aslinya (variable overwrite)."
		}
	},
	"Terminal_4": {
		"index": 4,
		"title": "TERMINAL 4: KALIBRASI GERBANG SEKTOR 3",
		"objective": "Gunakan abs() dan pembagian bulat (//) agar nilai langkah tepat 5 (integer positif).",
		"initial_code": [
			"jarak = -45",
			"ukuran_blok = 9",
			"langkah = jarak / ukuran_blok",
			"kalibrasi_crane(langkah)"
		],
		"locked_lines": [0, 1, 3],
		"required_call": "kalibrasi_crane",
		"expected_arg": 5,
		"require_print": false,
		"expected_print": "",
		"logical_fail_hint": "Hasil saat ini -5.0 (negatif & desimal). Gunakan abs(jarak) // ukuran_blok agar hasilnya tepat 5!",
		"success_message": "Gerbang Laser Sektor 3 terbuka! Bersiap gunakan Sprint [Shift] melewati koridor laser.",
		"hints": [
			"Lint: \"Pembagian / menghasilkan angka desimal (float) dan jarak bernilai negatif (-45).\"",
			"Lint: \"Gunakan fungsi abs(jarak) untuk mempositifkan angka dan // untuk pembagian bilangan bulat.\"",
			"Lint: \"Ubah baris 3 menjadi: langkah = abs(jarak) // ukuran_blok\""
		],
		"bug_log_entry": {
			"terminal_id": "Terminal_4",
			"bug_type": "Logical Bug (Integer Division // & abs)",
			"broken_code": "langkah = jarak / ukuran_blok",
			"fixed_code": "langkah = abs(jarak) // ukuran_blok",
			"explanation": "Operator // melakukan pembagian bulat tanpa koma, dan abs() mengubah bilangan negatif menjadi positif."
		}
	},
	"Terminal_5": {
		"index": 5,
		"title": "TERMINAL 5: OTORISASI EXIT (MULTI-BUG)",
		"objective": "Temukan sendiri 2 bug (TypeError string & prioritas kurung) agar kunci_exit bernilai 30!",
		"initial_code": [
			"basis = \"10\"",
			"bonus = 5",
			"faktor = 2",
			"kunci_exit = basis + bonus * faktor",
			"buka_exit_level_2(kunci_exit)"
		],
		"locked_lines": [],
		"required_call": "buka_exit_level_2",
		"expected_arg": 30,
		"require_print": false,
		"expected_print": "",
		"logical_fail_hint": "Pastikan basis adalah angka (10 tanpa kutip) dan (basis + bonus) dikurung sebelum dikali faktor!",
		"success_message": "Gerbang Exit Level 2 terbuka! Masuk ke portal EXIT di ujung kanan!",
		"hints": [
			"Lint: \"Kali ini tidak ada baris terkunci! Cek baris 1 dan baris 4.\"",
			"Lint: \"Baris 1: basis masih berupa teks \"10\". Baris 4: perkalian dikerjakan sebelum penjumlahan.\"",
			"Lint: \"Ubah basis = 10 dan kunci_exit = (basis + bonus) * faktor\""
		],
		"bug_log_entry": {
			"terminal_id": "Terminal_5",
			"bug_type": "Multi-Bug (TypeError + PEMDAS)",
			"broken_code": "basis = \"10\"\nkunci_exit = basis + bonus * faktor",
			"fixed_code": "basis = 10\nkunci_exit = (basis + bonus) * faktor",
			"explanation": "Kombinasi dua bug: teks \"10\" harus diubah ke integer 10 agar bisa dihitung, lalu penjumlahan dibungkus kurung () agar dieksekusi sebelum perkalian."
		}
	}
}

@export var rebuild_map_now: bool = false:
	set(_value):
		if is_node_ready():
			call_deferred("_build_all")

@onready var dex: CharacterBody2D = get_node_or_null("Dex")
@onready var bg_layer: TileMapLayer = get_node_or_null("BgLayer")
@onready var terrain_layer: TileMapLayer = get_node_or_null("TerrainLayer")
@onready var props_layer: TileMapLayer = get_node_or_null("PropsLayer")
@onready var overview_cam: Camera2D = get_node_or_null("OverviewCamera")
@onready var hud_status: Label = get_node_or_null("HUD/TopBar/Margin/HBox/StatusLabel")
@onready var terminal_overlay: Node = get_node_or_null("TerminalOverlay")

var _is_overview_cam: bool = false
var _solved_terminals: Dictionary = {}
var _bug_log_entries: Array[Dictionary] = []
var _hud_progress_label: Label = null
var _hud_bug_log_btn: Button = null
var _bug_log_modal: PanelContainer = null
var _bug_log_vbox: VBoxContainer = null
var _bug_log_title: Label = null
var _bug_log_subtitle: Label = null
var _level_completed: bool = false

var _hp_bar: ProgressBar = null
var _hp_label: Label = null
var _hp_fill_sb: StyleBoxFlat = null
var _en_bar: ProgressBar = null
var _en_label: Label = null
var _en_fill_sb: StyleBoxFlat = null

var _toast_panel: PanelContainer = null
var _toast_label: Label = null
var _toast_timer: float = 0.0
var _visited_sectors: Dictionary = {}


func _ready() -> void:
	_build_all()
	if not Engine.is_editor_hint():
		_setup_runtime()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and is_instance_valid(_toast_panel):
			_toast_panel.visible = false

	# Sector toast triggers & fast recharge detection
	if dex:
		var px := dex.global_position.x
		if px < 480.0 and not _visited_sectors.has(1):
			_visited_sectors[1] = true
			_show_lint_toast("Lint [Sektor 1]: \"Hati-hati dengan Laser Patroli & Duri! Gunakan [Shift] untuk Sprint saat laser mati.\"")
		elif px >= 512.0 and px < 1000.0 and not _visited_sectors.has(2):
			_visited_sectors[2] = true
			_show_lint_toast("Lint [Sektor 2]: \"Sentuh CapsulePod untuk Checkpoint! Sembunyi di balik Crate agar tidak terdeteksi Scanner.\"")
		elif px >= 1024.0 and not _visited_sectors.has(3):
			_visited_sectors[3] = true
			_show_lint_toast("Lint [Sektor 3]: \"Koridor Sprint! Manfaatkan Energy untuk lari melewati laser berkedip menuju Terminal 5.\"")

		if "is_in_recharge_zone" in dex:
			var near_recharge := false
			var pod := get_node_or_null("Interactables/CapsulePod_Checkpoint")
			if pod and dex.global_position.distance_to(pod.global_position) < 48.0:
				near_recharge = true
			if not near_recharge:
				for i in range(1, TOTAL_TERMINALS + 1):
					var term := get_node_or_null("Terminals/Terminal_%d" % i)
					if term and dex.global_position.distance_to(term.global_position) < 38.0:
						near_recharge = true
						break
			if terminal_overlay and terminal_overlay.has_method("is_open") and terminal_overlay.is_open():
				near_recharge = true
			dex.is_in_recharge_zone = near_recharge


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_toggle_camera()
		elif event.keycode == KEY_L:
			if not (terminal_overlay and terminal_overlay.has_method("is_open") and terminal_overlay.is_open()):
				_toggle_bug_log_modal(false)


func _toggle_camera() -> void:
	_is_overview_cam = not _is_overview_cam
	var dex_cam: Camera2D = dex.get_node_or_null("Camera2D") if dex else null
	if _is_overview_cam and overview_cam:
		overview_cam.enabled = true
		overview_cam.make_current()
		if dex_cam:
			dex_cam.enabled = false
	elif dex_cam:
		dex_cam.enabled = true
		dex_cam.make_current()
		if overview_cam:
			overview_cam.enabled = false


func _setup_runtime() -> void:
	# Default camera in Level 2 is Follow Dex Camera (limit_right = 1536)
	_is_overview_cam = false
	var dex_cam: Camera2D = dex.get_node_or_null("Camera2D") if dex else null
	if dex_cam:
		dex_cam.limit_left = 0
		dex_cam.limit_top = 0
		dex_cam.limit_right = 1536
		dex_cam.limit_bottom = 432
		dex_cam.enabled = true
		dex_cam.make_current()
	if overview_cam:
		overview_cam.enabled = false

	var elev: Node = get_node_or_null("Programmable/Elevator_S1_S2")
	if elev and elev.has_method("set_active"):
		elev.call("set_active", false)

	var exit_gate: Node = get_node_or_null("Interactables/ExitGate")
	if exit_gate:
		if exit_gate.has_method("set_unlocked"):
			exit_gate.call("set_unlocked", false)
		if exit_gate.has_signal("level_completed") and not exit_gate.level_completed.is_connected(_on_level_completed):
			exit_gate.level_completed.connect(_on_level_completed)

	if not terminal_overlay:
		terminal_overlay = get_node_or_null("TerminalOverlay")
	if terminal_overlay:
		if terminal_overlay.has_signal("level_action_triggered") and not terminal_overlay.level_action_triggered.is_connected(_on_level_action_triggered):
			terminal_overlay.level_action_triggered.connect(_on_level_action_triggered)
		if terminal_overlay.has_signal("terminal_solved") and not terminal_overlay.terminal_solved.is_connected(_on_terminal_solved):
			terminal_overlay.terminal_solved.connect(_on_terminal_solved)
		if terminal_overlay.has_signal("terminal_closed") and not terminal_overlay.terminal_closed.is_connected(_on_terminal_closed):
			terminal_overlay.terminal_closed.connect(_on_terminal_closed)

	_setup_hud_extras()
	_update_hud_display("Misi 1: Lewati duri lantai & perbaiki Terminal 1 [E] untuk mematikan Laser Patroli")


func _setup_hud_extras() -> void:
	var hbox: HBoxContainer = get_node_or_null("HUD/TopBar/Margin/HBox")
	if not hbox:
		return
	var top_bar: PanelContainer = get_node_or_null("HUD/TopBar")
	if top_bar:
		top_bar.offset_left = 10.0
		top_bar.offset_top = 6.0
		top_bar.offset_right = 1142.0
		top_bar.offset_bottom = 40.0

	if not _hp_bar:
		var hp_cluster := HBoxContainer.new()
		hp_cluster.name = "HPCluster"
		hp_cluster.alignment = BoxContainer.ALIGNMENT_CENTER
		hp_cluster.add_theme_constant_override("separation", 6)

		var hp_lbl := Label.new()
		hp_lbl.text = "HP"
		hp_lbl.add_theme_font_size_override("font_size", 11)
		hp_lbl.add_theme_color_override("font_color", Color(0.29, 0.87, 0.5))
		hp_cluster.add_child(hp_lbl)

		_hp_bar = ProgressBar.new()
		_hp_bar.name = "HPBar"
		_hp_bar.custom_minimum_size = Vector2(80, 14)
		_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_hp_bar.show_percentage = false
		_hp_bar.max_value = 100.0
		_hp_bar.value = 100.0

		var hp_bg_sb := StyleBoxFlat.new()
		hp_bg_sb.bg_color = Color(0.05, 0.08, 0.14, 0.95)
		hp_bg_sb.border_color = Color(0.2, 0.28, 0.38)
		hp_bg_sb.set_border_width_all(1)
		hp_bg_sb.set_corner_radius_all(3)
		_hp_bar.add_theme_stylebox_override("background", hp_bg_sb)

		_hp_fill_sb = StyleBoxFlat.new()
		_hp_fill_sb.bg_color = Color(0.14, 0.77, 0.37)
		_hp_fill_sb.set_corner_radius_all(2)
		_hp_bar.add_theme_stylebox_override("fill", _hp_fill_sb)
		hp_cluster.add_child(_hp_bar)

		_hp_label = Label.new()
		_hp_label.name = "HPValue"
		_hp_label.text = "100/100"
		_hp_label.add_theme_font_size_override("font_size", 10)
		_hp_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
		hp_cluster.add_child(_hp_label)
		hbox.add_child(hp_cluster)

	if not _en_bar:
		var en_cluster := HBoxContainer.new()
		en_cluster.name = "ENCluster"
		en_cluster.alignment = BoxContainer.ALIGNMENT_CENTER
		en_cluster.add_theme_constant_override("separation", 6)

		var en_lbl := Label.new()
		en_lbl.text = "EN"
		en_lbl.add_theme_font_size_override("font_size", 11)
		en_lbl.add_theme_color_override("font_color", Color(0.22, 0.74, 0.97))
		en_cluster.add_child(en_lbl)

		_en_bar = ProgressBar.new()
		_en_bar.name = "ENBar"
		_en_bar.custom_minimum_size = Vector2(80, 14)
		_en_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_en_bar.show_percentage = false
		_en_bar.max_value = 100.0
		_en_bar.value = 100.0

		var en_bg_sb := StyleBoxFlat.new()
		en_bg_sb.bg_color = Color(0.05, 0.08, 0.14, 0.95)
		en_bg_sb.border_color = Color(0.2, 0.28, 0.38)
		en_bg_sb.set_border_width_all(1)
		en_bg_sb.set_corner_radius_all(3)
		_en_bar.add_theme_stylebox_override("background", en_bg_sb)

		_en_fill_sb = StyleBoxFlat.new()
		_en_fill_sb.bg_color = Color(0.02, 0.71, 0.83)
		_en_fill_sb.set_corner_radius_all(2)
		_en_bar.add_theme_stylebox_override("fill", _en_fill_sb)
		en_cluster.add_child(_en_bar)

		_en_label = Label.new()
		_en_label.name = "ENValue"
		_en_label.text = "100/100"
		_en_label.add_theme_font_size_override("font_size", 10)
		_en_label.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
		en_cluster.add_child(_en_label)
		hbox.add_child(en_cluster)

		var vit_sep := VSeparator.new()
		vit_sep.name = "VitalitySep"
		hbox.add_child(vit_sep)

		hbox.move_child(hbox.get_node("HPCluster"), 0)
		hbox.move_child(hbox.get_node("ENCluster"), 1)
		hbox.move_child(vit_sep, 2)

	if dex:
		if not dex.health_changed.is_connected(_on_dex_health_changed):
			dex.health_changed.connect(_on_dex_health_changed)
		if not dex.energy_changed.is_connected(_on_dex_energy_changed):
			dex.energy_changed.connect(_on_dex_energy_changed)
		if "health" in dex and "max_health" in dex:
			_on_dex_health_changed(dex.health, dex.max_health)
		if "energy" in dex and "max_energy" in dex:
			_on_dex_energy_changed(dex.energy, dex.max_energy)

	if hud_status:
		hud_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hud_status.custom_minimum_size = Vector2(200, 0)
		hud_status.clip_text = true
		hud_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		hud_status.add_theme_font_size_override("font_size", 12)

	if not _hud_progress_label:
		_hud_progress_label = Label.new()
		_hud_progress_label.name = "ProgressLabel"
		_hud_progress_label.add_theme_font_size_override("font_size", 13)
		_hud_progress_label.add_theme_color_override("font_color", Color(0.45, 0.9, 1.0))
		hbox.add_child(_hud_progress_label)

	var sep := VSeparator.new()
	hbox.add_child(sep)

	if not _hud_bug_log_btn:
		_hud_bug_log_btn = Button.new()
		_hud_bug_log_btn.name = "BugLogBtn"
		_hud_bug_log_btn.text = "Bug Log (0/5) [L]"
		_hud_bug_log_btn.add_theme_font_size_override("font_size", 12)
		_hud_bug_log_btn.pressed.connect(func() -> void: _toggle_bug_log_modal(false))
		hbox.add_child(_hud_bug_log_btn)

	var sep2 := VSeparator.new()
	hbox.add_child(sep2)

	var menu_btn := Button.new()
	menu_btn.name = "MenuBtn"
	menu_btn.text = "Menu Utama"
	menu_btn.add_theme_font_size_override("font_size", 12)
	menu_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
	)
	hbox.add_child(menu_btn)

	_build_bug_log_modal()
	_build_lint_toast()


func _build_lint_toast() -> void:
	var hud_layer: CanvasLayer = get_node_or_null("HUD")
	if not hud_layer or _toast_panel:
		return

	_toast_panel = PanelContainer.new()
	_toast_panel.name = "LintToast"
	_toast_panel.visible = false
	_toast_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_toast_panel.offset_left = 180.0
	_toast_panel.offset_right = -180.0
	_toast_panel.offset_top = -68.0
	_toast_panel.offset_bottom = -14.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.15, 0.94)
	style.border_color = Color(0.22, 0.74, 0.97, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_toast_panel.add_theme_stylebox_override("panel", style)

	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.add_theme_font_size_override("font_size", 13)
	_toast_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_toast_panel.add_child(_toast_label)
	hud_layer.add_child(_toast_panel)


func _show_lint_toast(msg: String, duration: float = 5.5) -> void:
	if not _toast_panel or not _toast_label:
		return
	_toast_label.text = msg
	_toast_panel.visible = true
	_toast_timer = duration


func _build_bug_log_modal() -> void:
	var hud_layer: CanvasLayer = get_node_or_null("HUD")
	if not hud_layer or _bug_log_modal:
		return

	_bug_log_modal = PanelContainer.new()
	_bug_log_modal.name = "BugLogModal"
	_bug_log_modal.visible = false
	_bug_log_modal.set_anchors_preset(Control.PRESET_CENTER)
	_bug_log_modal.custom_minimum_size = Vector2(760, 440)
	_bug_log_modal.offset_left = -380.0
	_bug_log_modal.offset_top = -220.0
	_bug_log_modal.offset_right = 380.0
	_bug_log_modal.offset_bottom = 220.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.98)
	style.border_color = Color(0.3, 0.85, 1.0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	_bug_log_modal.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_bug_log_modal.add_child(vbox)

	_bug_log_title = Label.new()
	_bug_log_title.text = "BUG LOG — DUNIA 1 LEVEL 2"
	_bug_log_title.add_theme_font_size_override("font_size", 18)
	_bug_log_title.add_theme_color_override("font_color", Color(0.45, 0.92, 1.0))
	vbox.add_child(_bug_log_title)

	_bug_log_subtitle = Label.new()
	_bug_log_subtitle.text = "Catatan bug Python Level 2:"
	_bug_log_subtitle.add_theme_font_size_override("font_size", 13)
	_bug_log_subtitle.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	_bug_log_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_bug_log_subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_bug_log_vbox = VBoxContainer.new()
	_bug_log_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bug_log_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(_bug_log_vbox)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var menu_btn := Button.new()
	menu_btn.text = "Kembali ke Main Menu"
	menu_btn.custom_minimum_size = Vector2(160, 34)
	menu_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
	)
	btn_row.add_child(menu_btn)

	var close_btn := Button.new()
	close_btn.text = "Tutup [L]"
	close_btn.custom_minimum_size = Vector2(120, 34)
	close_btn.pressed.connect(func() -> void: _bug_log_modal.visible = false)
	btn_row.add_child(close_btn)

	hud_layer.add_child(_bug_log_modal)


func _toggle_bug_log_modal(is_level_clear: bool) -> void:
	if not _bug_log_modal:
		return
	if _bug_log_modal.visible and not is_level_clear:
		_bug_log_modal.visible = false
		return

	if is_level_clear:
		_bug_log_title.text = "LEVEL 2 SELESAI! — DUNIA 1: SYNTAX SHORE"
		_bug_log_subtitle.text = "Hebat! Dex & Lint menyelesaikan seluruh 5 Terminal Level 2 (Moderat)! Berikut ringkasan Bug Log:"
	else:
		_bug_log_title.text = "BUG LOG — LEVEL 2 (%d/%d)" % [_solved_terminals.size(), TOTAL_TERMINALS]
		_bug_log_subtitle.text = "Catatan bug Python yang telah diperbaiki di Level 2:"

	for child in _bug_log_vbox.get_children():
		_bug_log_vbox.remove_child(child)
		child.queue_free()

	if _bug_log_entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Belum ada bug yang tercatat. Perbaiki kode di Terminal [E] untuk mengisi Bug Log!"
		empty_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.82))
		_bug_log_vbox.add_child(empty_lbl)
	else:
		for entry in _bug_log_entries:
			var card := PanelContainer.new()
			var c_style := StyleBoxFlat.new()
			c_style.bg_color = Color(0.12, 0.15, 0.2, 1.0)
			c_style.border_color = Color(0.25, 0.55, 0.75, 0.8)
			c_style.set_border_width_all(1)
			c_style.set_corner_radius_all(5)
			c_style.content_margin_left = 10
			c_style.content_margin_right = 10
			c_style.content_margin_top = 8
			c_style.content_margin_bottom = 8
			card.add_theme_stylebox_override("panel", c_style)

			var cv := VBoxContainer.new()
			cv.add_theme_constant_override("separation", 3)
			card.add_child(cv)

			var h_lbl := Label.new()
			h_lbl.text = "[%s] %s" % [entry.get("terminal_id", ""), entry.get("bug_type", "")]
			h_lbl.add_theme_font_size_override("font_size", 13)
			h_lbl.add_theme_color_override("font_color", Color(1.0, 0.84, 0.35))
			cv.add_child(h_lbl)

			var diff_lbl := Label.new()
			diff_lbl.text = "Salah : %s\nBenar : %s" % [entry.get("broken_code", ""), entry.get("fixed_code", "")]
			diff_lbl.add_theme_font_size_override("font_size", 12)
			diff_lbl.add_theme_color_override("font_color", Color(0.6, 0.95, 0.7))
			cv.add_child(diff_lbl)

			var exp_lbl := Label.new()
			exp_lbl.text = "Penjelasan: " + String(entry.get("explanation", ""))
			exp_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			exp_lbl.add_theme_font_size_override("font_size", 12)
			exp_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.96))
			cv.add_child(exp_lbl)

			_bug_log_vbox.add_child(card)

	_bug_log_modal.visible = true


func _update_hud_display(objective_text: String = "") -> void:
	if hud_status and not objective_text.is_empty():
		hud_status.text = objective_text
	var solved_count: int = _solved_terminals.size()
	if _hud_progress_label:
		_hud_progress_label.text = "Terminal: %d/%d | [Tab] Kamera" % [solved_count, TOTAL_TERMINALS]
	if _hud_bug_log_btn:
		_hud_bug_log_btn.text = "Bug Log (%d/%d) [L]" % [solved_count, TOTAL_TERMINALS]


func _on_dex_health_changed(hp: float, max_hp: float) -> void:
	if _hp_bar:
		_hp_bar.value = hp
		_hp_bar.max_value = max_hp
	if _hp_label:
		_hp_label.text = "%d/%d" % [int(hp), int(max_hp)]
	if _hp_fill_sb:
		_hp_fill_sb.bg_color = Color(0.94, 0.27, 0.27) if hp <= 30.0 else Color(0.14, 0.77, 0.37)


func _on_dex_energy_changed(en: float, max_en: float) -> void:
	if _en_bar:
		_en_bar.value = en
		_en_bar.max_value = max_en
	if _en_label:
		_en_label.text = "%d/%d" % [int(en), int(max_en)]
	if _en_fill_sb:
		_en_fill_sb.bg_color = Color(0.96, 0.62, 0.04) if en <= 20.0 else Color(0.02, 0.71, 0.83)


func _build_all() -> void:
	var ts: TileSet = load(TILESET_PATH)
	if not ts:
		return
	_configure_tileset_collisions(ts)

	bg_layer = get_node_or_null("BgLayer")
	terrain_layer = get_node_or_null("TerrainLayer")
	props_layer = get_node_or_null("PropsLayer")
	dex = get_node_or_null("Dex")

	if bg_layer:
		bg_layer.tile_set = ts
		_populate_bg_layer(bg_layer)
	if terrain_layer:
		terrain_layer.tile_set = ts
		_populate_terrain_layer(terrain_layer)
	if props_layer:
		props_layer.tile_set = ts
		_populate_props_layer(props_layer)

	_setup_terminals()


func _setup_terminals() -> void:
	var terms_root: Node2D = get_node_or_null("Terminals")
	if not terms_root or Engine.is_editor_hint():
		return
	for child in terms_root.get_children():
		if child.has_signal("terminal_interacted"):
			if not child.terminal_interacted.is_connected(_on_terminal_interacted):
				child.terminal_interacted.connect(_on_terminal_interacted)


func _on_terminal_interacted(terminal: Node) -> void:
	var t_id: String = terminal.get("terminal_id") if "terminal_id" in terminal else terminal.name
	if not TERMINAL_CONFIGS.has(t_id):
		return
	if dex:
		dex.controls_enabled = false
		dex.velocity = Vector2.ZERO
		dex.checkpoint_position = terminal.global_position + Vector2(0.0, -8.0)

	if not terminal_overlay:
		terminal_overlay = get_node_or_null("TerminalOverlay")
	if terminal_overlay and terminal_overlay.has_method("open_terminal"):
		terminal_overlay.call("open_terminal", t_id, TERMINAL_CONFIGS[t_id], TOTAL_TERMINALS)


func _on_terminal_closed() -> void:
	if dex:
		dex.controls_enabled = true


func _on_level_action_triggered(action_name: String, arg_value: Variant) -> void:
	match action_name:
		"matikan_laser_patroli":
			if typeof(arg_value) == TYPE_INT and int(arg_value) == 60:
				var lp: Node = get_node_or_null("Programmable/LaserPatrol_1")
				if lp and lp.has_method("set_active"):
					lp.call("set_active", false)
		"sinkronisasi_elevator":
			if typeof(arg_value) == TYPE_INT and int(arg_value) == 3:
				var elev: Node = get_node_or_null("Programmable/Elevator_S1_S2")
				if elev and elev.has_method("set_active"):
					elev.call("set_active", true)
		"matikan_scanner":
			if typeof(arg_value) == TYPE_INT and int(arg_value) == 80:
				var sc: Node = get_node_or_null("Programmable/Scanner_1")
				if sc and sc.has_method("matikan_sensor"):
					sc.call("matikan_sensor")
		"kalibrasi_crane":
			if typeof(arg_value) == TYPE_INT and int(arg_value) == 5:
				var lg: Node = get_node_or_null("Programmable/LaserGate_S2_S3")
				if lg and lg.has_method("set_active"):
					lg.call("set_active", false)
				var crane: Node = get_node_or_null("Programmable/CraneClaw")
				if crane and crane.has_method("release_robot"):
					crane.call("release_robot")
		"buka_exit_level_2":
			if typeof(arg_value) == TYPE_INT and int(arg_value) == 30:
				var exit_gate: Node = get_node_or_null("Interactables/ExitGate")
				if exit_gate and exit_gate.has_method("set_unlocked"):
					exit_gate.call("set_unlocked", true)


func _on_terminal_solved(terminal_id: String, bug_log_entry: Dictionary) -> void:
	if not _solved_terminals.has(terminal_id):
		_solved_terminals[terminal_id] = true
		if not bug_log_entry.is_empty():
			_bug_log_entries.append(bug_log_entry)

	var next_msg := ""
	match terminal_id:
		"Terminal_1":
			next_msg = "Laser Patroli mati! Lanjut ke Terminal 2 di kanan untuk mengaktifkan Elevator."
		"Terminal_2":
			next_msg = "Elevator aktif! Naik ke Sektor 2 dan sentuh CapsulePod untuk Checkpoint."
		"Terminal_3":
			next_msg = "Scanner Sektor 2 mati! Naik platform kanan ke Terminal 4."
		"Terminal_4":
			next_msg = "Gerbang Laser Sektor 3 terbuka! Gunakan Sprint [Shift] melewati koridor laser ke Terminal 5."
		"Terminal_5":
			next_msg = "Gerbang Exit Level 2 terbuka! Masuk ke portal EXIT di ujung kanan!"

	_update_hud_display(next_msg)
	if hud_status:
		hud_status.modulate = Color(0.4, 1.0, 0.6)


func _on_level_completed() -> void:
	if _level_completed:
		return
	_level_completed = true
	_update_hud_display("SELAMAT! Level 2: Syntax Shore (Moderat) selesai!")
	_toggle_bug_log_modal(true)


func _configure_tileset_collisions(ts: TileSet) -> void:
	if ts.get_physics_layers_count() == 0:
		ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 1)

	if not ts.has_source(0):
		return
	var atlas: TileSetAtlasSource = ts.get_source(0) as TileSetAtlasSource
	if not atlas:
		return
	if atlas.has_tile(Vector2i(1, 4)):
		var check_td: TileData = atlas.get_tile_data(Vector2i(1, 4), 0)
		if check_td and check_td.get_collision_polygons_count(0) > 0:
			return


func _populate_bg_layer(layer: TileMapLayer) -> void:
	layer.clear()
	# Background industrial pillars & vents across 96 tiles
	for px in [8, 18, 27, 36, 46, 56, 67, 78, 86]:
		for y in range(4, 24):
			layer.set_cell(Vector2i(px, y), 0, Vector2i(5, 11 + (y % 3)))

	for vx in [10, 22, 39, 50, 70, 82]:
		layer.set_cell(Vector2i(vx, 12), 0, Vector2i(3, 12))
		layer.set_cell(Vector2i(vx + 1, 12), 0, Vector2i(4, 12))
		layer.set_cell(Vector2i(vx, 13), 0, Vector2i(3, 13))
		layer.set_cell(Vector2i(vx + 1, 13), 0, Vector2i(4, 13))

	for sqx in range(6, 90, 6):
		layer.set_cell(Vector2i(sqx, 8), 0, Vector2i(2, 11))
		layer.set_cell(Vector2i(sqx + 2, 17), 0, Vector2i(2, 11))


func _populate_terrain_layer(layer: TileMapLayer) -> void:
	layer.clear()
	# Outer ceiling & walls (96x27)
	for x in range(0, 96):
		layer.set_cell(Vector2i(x, 0), 0, Vector2i(1, 4))
		layer.set_cell(Vector2i(x, 1), 0, Vector2i(1, 5))
		layer.set_cell(Vector2i(x, 26), 0, Vector2i(1, 4))

	for y in range(0, 27):
		layer.set_cell(Vector2i(0, y), 0, Vector2i(1, 4))
		layer.set_cell(Vector2i(1, y), 0, Vector2i(4, 4))
		layer.set_cell(Vector2i(94, y), 0, Vector2i(3, 4))
		layer.set_cell(Vector2i(95, y), 0, Vector2i(1, 4))

	# Main Floor row y=24..25 across Sector 1 & 2 & 3 (with recessed spike pits)
	for x in range(2, 94):
		var is_pit := (x >= 12 and x <= 13) or (x >= 84 and x <= 86)
		if is_pit:
			layer.set_cell(Vector2i(x, 25), 0, Vector2i(1, 4))
		else:
			layer.set_cell(Vector2i(x, 24), 0, Vector2i(1, 2))
			layer.set_cell(Vector2i(x, 25), 0, Vector2i(1, 4))

	# Sector 1 low ceiling over Patrol Laser (x=18..26, y=18..19)
	for x in range(18, 27):
		layer.set_cell(Vector2i(x, 18), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 19), 0, Vector2i(1, 5))

	# Divider Wall Sector 1 -> Sector 2 (x=30..31, bottom y=16..23, gap y=10..15)
	for y in range(16, 24):
		layer.set_cell(Vector2i(30, y), 0, Vector2i(3, 4))
		layer.set_cell(Vector2i(31, y), 0, Vector2i(4, 4))
	for y in range(2, 10):
		layer.set_cell(Vector2i(30, y), 0, Vector2i(3, 4))
		layer.set_cell(Vector2i(31, y), 0, Vector2i(4, 4))

	# Sector 2 Checkpoint Entry Ledge (x=32..37, y=15..16)
	for x in range(32, 38):
		layer.set_cell(Vector2i(x, 15), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 16), 0, Vector2i(1, 5))

	# Sector 2 One-Way Step-Down Platforms (from Checkpoint to floor)
	_place_one_way_platform(layer, 39, 18, 3)
	_place_one_way_platform(layer, 36, 21, 3)

	# Sector 2 Ceiling Mount for Scanner_1 (x=44..48, y=14..15)
	for x in range(44, 49):
		layer.set_cell(Vector2i(x, 14), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 15), 0, Vector2i(1, 5))

	# Sector 2 Elevated Ledge for Terminal 4 (x=57..61, y=20..21) & One-Way steps
	_place_one_way_platform(layer, 54, 22, 3)
	for x in range(57, 62):
		layer.set_cell(Vector2i(x, 20), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 21), 0, Vector2i(1, 5))

	# Divider Wall Sector 2 -> Sector 3 (x=62..63, gap y=16..19 for LaserGate)
	for y in range(2, 16):
		layer.set_cell(Vector2i(62, y), 0, Vector2i(3, 4))
		layer.set_cell(Vector2i(63, y), 0, Vector2i(4, 4))
	for y in range(20, 24):
		layer.set_cell(Vector2i(62, y), 0, Vector2i(3, 4))
		layer.set_cell(Vector2i(63, y), 0, Vector2i(4, 4))

	# Sector 3 Sprint Corridor Floor (x=64..79, y=20..21, with 2-tile spike pit at x=72..73)
	for x in range(64, 80):
		if x >= 72 and x <= 73:
			layer.set_cell(Vector2i(x, 21), 0, Vector2i(1, 4))
		else:
			layer.set_cell(Vector2i(x, 20), 0, Vector2i(1, 2))
			layer.set_cell(Vector2i(x, 21), 0, Vector2i(1, 5))

	# Sector 3 Low Ceiling over Sprint Corridor (x=65..78, y=14..15)
	for x in range(65, 79):
		layer.set_cell(Vector2i(x, 14), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 15), 0, Vector2i(1, 5))

	# Sector 3 One-Way steps down to Exit Hall & over Final Spike Pit
	_place_one_way_platform(layer, 80, 22, 3)
	_place_one_way_platform(layer, 84, 22, 3)


func _place_one_way_platform(layer: TileMapLayer, start_x: int, y: int, length: int) -> void:
	for i in range(length):
		var tx := 8
		if i == 0:
			tx = 7
		elif i == length - 1:
			tx = 9
		layer.set_cell(Vector2i(start_x + i, y), 0, Vector2i(tx, 2))


func _populate_props_layer(layer: TileMapLayer) -> void:
	layer.clear()
