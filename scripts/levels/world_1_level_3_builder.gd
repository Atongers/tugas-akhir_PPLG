@tool
extends Node2D
class_name World1Level3Builder

## Level 3: Syntax Shore (Moderat-Tinggi) — Dual-Deck Interlocking Arena (112x32 tiles)
## Reprogram-to-Traverse + 5 Terminal Debug Mandiri (print & len) + Low-Power Corridor.

const TILESET_PATH := "res://resources/tilesets/world_1_tileset.tres"
const WIRING_SHEET_PATH := "res://assets/sprites/environment/wiring_cables_sheet.png"
const PROPS_SHEET_PATH := "res://assets/sprites/environment/sector_props_sheet.png"
const UI_ICONS_PATH := "res://assets/ui/ui_status_icons_sheet.png"
const VFX_SPARK_PATH := "res://assets/sprites/vfx/vfx_spark_error.png"
const VFX_SOLVED_PATH := "res://assets/sprites/vfx/vfx_energy_solved.png"
const VFX_DUST_PATH := "res://assets/sprites/vfx/vfx_dust_cyan.png"

const TOTAL_TERMINALS := 5

const TERMINAL_CONFIGS := {
	"Terminal_1": {
		"title": "TERMINAL 1: KALIBRASI TURRET PLASMA",
		"initial_code": "speed = 3\ntime = 5\ndistance = speed + time\ninterval_tembak = distance\nprint(interval_tembak)\n# Target: distance = speed * time (15 -> 1.5s)\natur_plasma(interval_tembak)",
		"broken_code": "distance = speed + time  # 8 (terlalu cepat)",
		"locked_lines": [],
		"required_call": "atur_plasma",
		"expected_arg": 15,
		"hints": [
			"Hint 1: Jalankan script & lihat hasil print(interval_tembak). Angka 8 terlalu cepat bagi turret!",
			"Hint 2: Jarak = kecepatan dikali waktu (speed * time), bukan ditambah.",
			"Hint 3: Ubah baris 3 menjadi: distance = speed * time"
		],
		"bug_type": "Multi-Variable Dependency",
		"explanation": "Mengubah speed + time menjadi speed * time menghasilkan interval 15 (1.5s) yang ritmis agar Dex bisa Sprint melintasinya.",
		"success_message": "Turret Plasma dikalibrasi ulang! Tembakan kini ritmis dan mengarah miring ke atas."
	},
	"Terminal_2": {
		"title": "TERMINAL 2: ARAH & JARAK CRANE TAMENG",
		"initial_code": "arah = -1\njarak_blok = 28\nukuran_rel = 2\nlangkah = arah * (jarak_blok // ukuran_rel)\nprint(langkah)\n# Target: langkah positif = 14\ngerak_crane(langkah)",
		"broken_code": "arah = -1  # Crane mundur menjauh!",
		"locked_lines": [],
		"required_call": "gerak_crane",
		"expected_arg": 14,
		"hints": [
			"Hint 1: Cek output print(langkah)! Nilainya -14 sehingga Crane bergerak mundur.",
			"Hint 2: Untuk bergerak maju melintasi koridor Sentry, arah harus bernilai positif (+1).",
			"Hint 3: Ubah baris 1 menjadi: arah = 1"
		],
		"bug_type": "Signed Integer & Offset Bug",
		"explanation": "Mengubah arah = -1 menjadi arah = 1 menghasilkan langkah = 14 sehingga Crane membawa CompanionCrate sebagai tameng berjalan.",
		"success_message": "Crane Tameng aktif! Ikuti gerakan peti untuk berlindung dari Laser Sentry."
	},
	"Terminal_3": {
		"title": "TERMINAL 3: BATAS FREKUENSI ELEVATOR",
		"initial_code": "tinggi_dasar = 5\noffset_atas = 0\nbatas_siklus = 10\nhasil = (tinggi_dasar + offset_atas) % batas_siklus\nprint(hasil)\n# Target: tinggi akhir = 6\natur_elevator(hasil)",
		"broken_code": "offset_atas = 0  # Berhenti 1 tile di bawah ledge",
		"locked_lines": [],
		"required_call": "atur_elevator",
		"expected_arg": 6,
		"hints": [
			"Hint 1: Hasil print(hasil) saat ini 5, kurang 1 langkah (off-by-one) dari dek Sektor 3.",
			"Hint 2: Naikkan offset_atas agar (5 + offset_atas) % 10 menghasilkan 6.",
			"Hint 3: Ubah baris 2 menjadi: offset_atas = 1"
		],
		"bug_type": "Logical Range & Off-by-One",
		"explanation": "Menyesuaikan offset_atas = 1 membuat hasil = 6 sehingga Elevator naik penuh ke dek atas dengan jeda aman.",
		"success_message": "Elevator tersinkronisasi! Naik dan lompat menuju Sektor 3 saat Scanner menjauh."
	},
	"Terminal_4": {
		"title": "TERMINAL 4: OTORISASI PORT FIREWALL",
		"initial_code": "prefix = \"PORT_\"\nport_dasar = 8000\nport_offset = 80\nport_id = port_dasar + port_offset\nkode_port = prefix + port_id\nprint(kode_port)\n# Target: \"PORT_8080\"\nbuka_firewall(kode_port)",
		"broken_code": "kode_port = prefix + port_id  # TypeError: str + int",
		"locked_lines": [],
		"required_call": "buka_firewall",
		"expected_arg": "PORT_8080",
		"hints": [
			"Hint 1: Menjalankan kode ini memicu TypeError karena string tidak bisa digabung langsung dengan int.",
			"Hint 2: Bungkus port_id dengan fungsi str(port_id) sebelum digabung dengan prefix.",
			"Hint 3: Ubah baris 5 menjadi: kode_port = prefix + str(port_id)"
		],
		"bug_type": "Type Casting & String Format",
		"explanation": "str(port_id) mengubah angka 8080 menjadi teks sehingga \"PORT_\" + str(8080) menghasilkan \"PORT_8080\".",
		"success_message": "Firewall Sektor 3 terbuka! Hemat Energy di Low-Power Corridor di depan."
	},
	"Terminal_5": {
		"title": "TERMINAL 5: SINKRONISASI REAKTOR EXIT",
		"initial_code": "modul = \"CORE\"\npanjang = len(modul)\nbasis = 4\nfaktor = 3\ntotal = basis + panjang * faktor\nkode_akhir = \"SYNC_\" + total\nprint(kode_akhir)\n# Target: (basis + len(modul)) * faktor = 24 -> \"SYNC_24\"\nbuka_exit_level_3(kode_akhir)",
		"broken_code": "total = basis + panjang * faktor  # Salah PEMDAS & str()",
		"locked_lines": [],
		"required_call": "buka_exit_level_3",
		"expected_arg": "SYNC_24",
		"hints": [
			"Hint 1: Ada 2 bug: prioritas kurung pada total dan TypeError saat menggabung \"SYNC_\" + total.",
			"Hint 2: Gunakan (basis + panjang) * faktor untuk mendapat 24, lalu ubah total ke str(total).",
			"Hint 3: total = (basis + panjang) * faktor dan kode_akhir = \"SYNC_\" + str(total)"
		],
		"bug_type": "Comprehensive Multi-Bug (PEMDAS + len + str)",
		"explanation": "Menggabungkan len(\"CORE\") = 4, tanda kurung (4 + 4) * 3 = 24, dan str(24) menghasilkan \"SYNC_24\".",
		"success_message": "Reaktor Exit sinkron! Gerbang keluar Level 3 terbuka!"
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

var _wire_groups: Dictionary = {}
var _status_icon: TextureRect = null
var _cam_icon: TextureRect = null


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

	if dex:
		var px := dex.global_position.x
		if px < 576.0 and not _visited_sectors.has(1):
			_visited_sectors[1] = true
			_show_lint_toast("Lint [Sektor 1]: \"Amati pola plasma di bawah, lalu cari terminal pengatur di dek atas!\"")
		elif px >= 608.0 and px < 1184.0 and not _visited_sectors.has(2):
			_visited_sectors[2] = true
			_show_lint_toast("Lint [Sektor 2]: \"Program ulang Crane agar peti berjalan sejajar melindungimu dari Laser Sentry!\"")
		elif px >= 1200.0 and not _visited_sectors.has(3):
			_visited_sectors[3] = true
			_show_lint_toast("Lint [Sektor 3]: \"Koridor rendah daya di depan—hemat Energimu, gunakan Sprint hanya saat melintasi celah bahaya!\"")

		if "is_in_recharge_zone" in dex:
			var near_recharge := false
			for pod_name in ["CapsulePod_CP1", "CapsulePod_CP2"]:
				var pod := get_node_or_null("Interactables/%s" % pod_name)
				if pod and dex.global_position.distance_to(pod.global_position) < 48.0:
					near_recharge = true
					break
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
	_is_overview_cam = false
	var dex_cam: Camera2D = dex.get_node_or_null("Camera2D") if dex else null
	if dex_cam:
		dex_cam.limit_left = 0
		dex_cam.limit_top = 0
		dex_cam.limit_right = 1792
		dex_cam.limit_bottom = 512
		dex_cam.enabled = true
		dex_cam.make_current()
	if overview_cam:
		overview_cam.enabled = false

	var elev: Node = get_node_or_null("Programmable/Elevator_S2_S3")
	if elev and elev.has_method("set_active"):
		elev.call("set_active", false)

	var exit_gate: Node = get_node_or_null("Interactables/ExitGate")
	if exit_gate:
		if exit_gate.has_method("set_unlocked"):
			exit_gate.call("set_unlocked", false)
		if exit_gate.has_signal("player_reached_exit") and not exit_gate.player_reached_exit.is_connected(_on_level_completed):
			exit_gate.player_reached_exit.connect(_on_level_completed)

	if dex and dex.has_signal("player_damaged") and not dex.player_damaged.is_connected(_on_dex_damaged):
		dex.player_damaged.connect(_on_dex_damaged)

	if not terminal_overlay:
		terminal_overlay = get_node_or_null("TerminalOverlay")
	if terminal_overlay:
		if terminal_overlay.has_signal("level_action_triggered") and not terminal_overlay.level_action_triggered.is_connected(_on_level_action_triggered):
			terminal_overlay.level_action_triggered.connect(_on_level_action_triggered)
		if terminal_overlay.has_signal("terminal_solved") and not terminal_overlay.terminal_solved.is_connected(_on_terminal_solved):
			terminal_overlay.terminal_solved.connect(_on_terminal_solved)
		if terminal_overlay.has_signal("terminal_closed") and not terminal_overlay.terminal_closed.is_connected(_on_terminal_closed):
			terminal_overlay.terminal_closed.connect(_on_terminal_closed)

	Engine.time_scale = 1.0
	_setup_hud_extras()
	_update_hud_display("Misi 1: Naik ke dek atas Sektor 1 & perbaiki Terminal 1 [E] untuk kalibrasi Turret Plasma")


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
		if not _status_icon:
			_status_icon = _make_ui_icon_rect(2)
			_status_icon.name = "StatusIcon"
			hbox.add_child(_status_icon)
			hbox.move_child(_status_icon, hud_status.get_index())

	if not _hud_progress_label:
		if not _cam_icon:
			_cam_icon = _make_ui_icon_rect(3)
			_cam_icon.name = "CamIcon"
			hbox.add_child(_cam_icon)
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


func _make_ui_icon_rect(frame_idx: int) -> TextureRect:
	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(16, 16)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex: Texture2D = load(UI_ICONS_PATH)
	if tex:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(frame_idx * 16, 0, 16, 16)
		icon_rect.texture = atlas
	return icon_rect


func _set_status_icon_frame(frame_idx: int) -> void:
	if not is_instance_valid(_status_icon):
		return
	var atlas := _status_icon.texture as AtlasTexture
	if atlas:
		atlas.region = Rect2(frame_idx * 16, 0, 16, 16)


func _on_dex_damaged(_amount: float, _source: String) -> void:
	if dex and dex.has_method("add_camera_trauma"):
		dex.call("add_camera_trauma", 0.30)
	VfxBurst.trigger_hit_stop(get_tree(), 0.04)
	if dex:
		VfxBurst.spawn_burst(self, VFX_SPARK_PATH, dex.global_position + Vector2(0.0, -10.0), 10, 42.0, -32.0)
	_set_status_icon_frame(0)


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
	_bug_log_title.text = "BUG LOG — DUNIA 1 LEVEL 3"
	_bug_log_title.add_theme_font_size_override("font_size", 18)
	_bug_log_title.add_theme_color_override("font_color", Color(0.45, 0.92, 1.0))
	vbox.add_child(_bug_log_title)

	_bug_log_subtitle = Label.new()
	_bug_log_subtitle.text = "Catatan bug Python Level 3:"
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
		_bug_log_title.text = "LEVEL 3 SELESAI! — DUNIA 1: SYNTAX SHORE"
		_bug_log_subtitle.text = "Luar biasa! Dex & Lint menaklukkan Dual-Deck Arena Level 3 (Moderat–Tinggi)! Ringkasan Bug Log:"
	else:
		_bug_log_title.text = "BUG LOG — LEVEL 3 (%d/%d)" % [_solved_terminals.size(), TOTAL_TERMINALS]
		_bug_log_subtitle.text = "Catatan bug Python Level 3:"

	for child in _bug_log_vbox.get_children():
		_bug_log_vbox.remove_child(child)
		child.queue_free()

	if _bug_log_entries.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Belum ada bug yang tercatat. Gunakan print() di Terminal [E] untuk melacak bug!"
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
		"atur_plasma":
			if typeof(arg_value) == TYPE_INT and int(arg_value) == 15:
				var tp: Node = get_node_or_null("Programmable/TurretPlasma_1")
				if tp:
					if tp.has_method("set_interval"):
						tp.call("set_interval", 1.5)
					if tp.has_method("set_sudut"):
						tp.call("set_sudut", 192.0)
		"gerak_crane":
			if typeof(arg_value) == TYPE_INT and int(arg_value) == 14:
				var crane: Node = get_node_or_null("Programmable/CraneClaw_Shield")
				if crane and crane.has_method("start_shield_patrol"):
					crane.call("start_shield_patrol")
		"atur_elevator":
			if typeof(arg_value) == TYPE_INT and int(arg_value) == 6:
				var elev: Node = get_node_or_null("Programmable/Elevator_S2_S3")
				if elev and elev.has_method("set_active"):
					elev.call("set_active", true)
		"buka_firewall":
			if typeof(arg_value) == TYPE_STRING and String(arg_value) == "PORT_8080":
				var lg: Node = get_node_or_null("Programmable/LaserGate_S3")
				if lg and lg.has_method("set_active"):
					lg.call("set_active", false)
		"buka_exit_level_3":
			if typeof(arg_value) == TYPE_STRING and String(arg_value) == "SYNC_24":
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
			next_msg = "Turret Plasma ritmis! Turun ke dek bawah & Sprint ke Sektor 2."
		"Terminal_2":
			next_msg = "Crane Tameng bergerak! Jalan di balik peti melewati Laser Sentry menuju Terminal 3."
		"Terminal_3":
			next_msg = "Elevator aktif! Naik ke Sektor 3 saat Scanner menjauh."
		"Terminal_4":
			next_msg = "Firewall terbuka! Hemat Energy di Low-Power Corridor menuju Terminal 5."
		"Terminal_5":
			next_msg = "ExitGate Level 3 terbuka! Masuk ke portal EXIT!"

	_update_hud_display(next_msg)
	if hud_status:
		hud_status.modulate = Color(0.4, 1.0, 0.6)
	_set_status_icon_frame(1)
	_mark_wire_solved(terminal_id)

	var term_node: Node2D = get_node_or_null("Terminals/%s" % terminal_id)
	var burst_pos := term_node.global_position + Vector2(0.0, 12.0) if term_node else (dex.global_position if dex else Vector2.ZERO)
	if terminal_id == "Terminal_5":
		if dex and dex.has_method("add_camera_trauma"):
			dex.call("add_camera_trauma", 0.35)
		VfxBurst.trigger_hit_stop(get_tree(), 0.06)
		var exit_gate: Node2D = get_node_or_null("Interactables/ExitGate")
		if exit_gate:
			VfxBurst.spawn_burst(self, VFX_SOLVED_PATH, exit_gate.global_position + Vector2(16.0, 4.0), 20, 56.0, -40.0)
	else:
		if dex and dex.has_method("add_camera_trauma"):
			dex.call("add_camera_trauma", 0.20)
		VfxBurst.trigger_hit_stop(get_tree(), 0.05)
		VfxBurst.spawn_burst(self, VFX_SOLVED_PATH, burst_pos, 14, 40.0, -30.0)


func _on_level_completed() -> void:
	if _level_completed:
		return
	_level_completed = true
	_update_hud_display("SELAMAT! Level 3: Syntax Shore (Moderat–Tinggi) selesai!")
	_toggle_bug_log_modal(true)


func _configure_tileset_collisions(ts: TileSet) -> void:
	if ts.get_physics_layers_count() == 0:
		ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 1)


func _populate_bg_layer(layer: TileMapLayer) -> void:
	layer.clear()
	for px in [10, 22, 34, 48, 62, 78, 92, 104]:
		for y in range(4, 28):
			layer.set_cell(Vector2i(px, y), 0, Vector2i(5, 11 + (y % 3)))

	for vx in [12, 26, 44, 58, 80, 96]:
		layer.set_cell(Vector2i(vx, 10), 0, Vector2i(3, 12))
		layer.set_cell(Vector2i(vx + 1, 10), 0, Vector2i(4, 12))
		layer.set_cell(Vector2i(vx, 11), 0, Vector2i(3, 13))
		layer.set_cell(Vector2i(vx + 1, 11), 0, Vector2i(4, 13))


func _populate_terrain_layer(layer: TileMapLayer) -> void:
	layer.clear()
	# Outer ceiling (y=0..1), bedrock (y=30..31), and side walls (x=0..1, x=110..111)
	for x in range(0, 112):
		layer.set_cell(Vector2i(x, 0), 0, Vector2i(1, 4))
		layer.set_cell(Vector2i(x, 1), 0, Vector2i(1, 5))
		layer.set_cell(Vector2i(x, 30), 0, Vector2i(1, 4))
		layer.set_cell(Vector2i(x, 31), 0, Vector2i(1, 4))

	for y in range(0, 32):
		layer.set_cell(Vector2i(0, y), 0, Vector2i(1, 4))
		layer.set_cell(Vector2i(1, y), 0, Vector2i(4, 4))
		layer.set_cell(Vector2i(110, y), 0, Vector2i(3, 4))
		layer.set_cell(Vector2i(111, y), 0, Vector2i(1, 4))

	# Sector 1 Lower Deck (x=2..35, y=28..29, spike pits at x=14..15 and x=24..25)
	for x in range(2, 36):
		var is_pit := (x >= 14 and x <= 15) or (x >= 24 and x <= 25)
		if is_pit:
			layer.set_cell(Vector2i(x, 29), 0, Vector2i(1, 4))
		else:
			layer.set_cell(Vector2i(x, 28), 0, Vector2i(1, 2))
			layer.set_cell(Vector2i(x, 29), 0, Vector2i(1, 4))

	# Safe spawn step (x=2..3, y=27) shields spawn from TurretPlasma_1 ground orbs
	for x in range(2, 4):
		layer.set_cell(Vector2i(x, 27), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 28), 0, Vector2i(1, 5))

	# Sector 1 Upper Safe Deck (x=12..28, y=21..22) + One-Way steps up (max 2 tiles / 32px per jump)
	_place_one_way_platform(layer, 4, 26, 3)
	_place_one_way_platform(layer, 7, 24, 3)
	_place_one_way_platform(layer, 9, 22, 3)
	for x in range(12, 29):
		layer.set_cell(Vector2i(x, 21), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 22), 0, Vector2i(1, 5))

	# Divider S1 -> S2 (x=36..37, wall y=2..23, open doorway y=24..27, floor y=28..29)
	for y in range(2, 24):
		layer.set_cell(Vector2i(36, y), 0, Vector2i(3, 4))
		layer.set_cell(Vector2i(37, y), 0, Vector2i(4, 4))
	for x in range(36, 38):
		layer.set_cell(Vector2i(x, 28), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 29), 0, Vector2i(1, 4))

	# Sector 2 Main Floor (x=38..73, y=28..29)
	for x in range(38, 74):
		layer.set_cell(Vector2i(x, 28), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 29), 0, Vector2i(1, 4))

	# Sector 2 Scanner Ceiling Mount (x=69..72, y=12..13)
	for x in range(69, 73):
		layer.set_cell(Vector2i(x, 12), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 13), 0, Vector2i(1, 5))

	# Divider S2 -> S3 (x=74..75, wall y=2..13 and y=19..29, doorway y=14..18)
	for y in range(2, 14):
		layer.set_cell(Vector2i(74, y), 0, Vector2i(3, 4))
		layer.set_cell(Vector2i(75, y), 0, Vector2i(4, 4))
	for y in range(19, 30):
		layer.set_cell(Vector2i(74, y), 0, Vector2i(3 if y < 28 else 1, 4))
		layer.set_cell(Vector2i(75, y), 0, Vector2i(4 if y < 28 else 1, 4))
	for x in range(74, 76):
		layer.set_cell(Vector2i(x, 18), 0, Vector2i(1, 2))

	# Sector 3 Entry & Firewall Ledge (x=76..83, y=18..19)
	for x in range(76, 84):
		layer.set_cell(Vector2i(x, 18), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 19), 0, Vector2i(1, 5))

	# Sector 3 Firewall Ceiling (x=82..84, y=12..13)
	for x in range(82, 85):
		layer.set_cell(Vector2i(x, 12), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 13), 0, Vector2i(1, 5))

	# Sector 3 Low-Power Corridor Spike Floor (x=76..101, y=28..29) + Ceiling (x=85..99, y=12..13)
	for x in range(76, 102):
		layer.set_cell(Vector2i(x, 28), 0, Vector2i(1, 4))
		layer.set_cell(Vector2i(x, 29), 0, Vector2i(1, 4))
	for x in range(85, 100):
		layer.set_cell(Vector2i(x, 12), 0, Vector2i(1, 2))
		layer.set_cell(Vector2i(x, 13), 0, Vector2i(1, 5))

	# Low-Power Corridor Rest Islands (solid small islands between CollapsingPlatforms)
	for x in range(84, 86):
		layer.set_cell(Vector2i(x, 21), 0, Vector2i(1, 2))
	for x in range(91, 93):
		layer.set_cell(Vector2i(x, 22), 0, Vector2i(1, 2))
	for x in range(99, 102):
		layer.set_cell(Vector2i(x, 24), 0, Vector2i(1, 2))

	# Sector 3 Reactor Exit Hall (x=102..109, y=26..29)
	for x in range(102, 110):
		for y in range(26, 30):
			layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 2 if y == 26 else 4))


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
	_rebuild_environmental_props()
	_rebuild_wiring_paths()


func _rebuild_environmental_props() -> void:
	var parent_node: Node = (props_layer as Node) if props_layer != null else (self as Node)
	var old := parent_node.get_node_or_null("EnvPropsContainer")
	if old:
		parent_node.remove_child(old)
		old.queue_free()

	var props_tex: Texture2D = load(PROPS_SHEET_PATH)
	if not props_tex:
		return

	var container := Node2D.new()
	container.name = "EnvPropsContainer"
	container.z_index = 0
	parent_node.add_child(container)

	var placements := [
		# Sector 1
		[Vector2i(3, 27), Vector2i(0, 0)], [Vector2i(16, 20), Vector2i(3, 0)],
		[Vector2i(21, 20), Vector2i(4, 0)], [Vector2i(32, 27), Vector2i(5, 0)],
		# Sector 2
		[Vector2i(40, 27), Vector2i(0, 1)], [Vector2i(48, 27), Vector2i(2, 1)],
		[Vector2i(56, 27), Vector2i(3, 1)], [Vector2i(66, 27), Vector2i(6, 1)],
		# Sector 3
		[Vector2i(78, 17), Vector2i(0, 2)], [Vector2i(86, 11), Vector2i(2, 2)],
		[Vector2i(94, 11), Vector2i(2, 2)], [Vector2i(105, 25), Vector2i(5, 2)],
		[Vector2i(108, 24), Vector2i(7, 2)],
	]

	for item in placements:
		var grid_pos: Vector2i = item[0]
		var atlas_pos: Vector2i = item[1]
		var sp := Sprite2D.new()
		sp.centered = false
		sp.position = Vector2(grid_pos.x * 16.0, grid_pos.y * 16.0)
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var at := AtlasTexture.new()
		at.atlas = props_tex
		at.region = Rect2(atlas_pos.x * 16, atlas_pos.y * 16, 16, 16)
		sp.texture = at
		container.add_child(sp)


func _rebuild_wiring_paths() -> void:
	_wire_groups.clear()
	var parent_node: Node = (props_layer as Node) if props_layer != null else (self as Node)
	var old := parent_node.get_node_or_null("WiringContainer")
	if old:
		parent_node.remove_child(old)
		old.queue_free()

	var wire_tex: Texture2D = load(WIRING_SHEET_PATH)
	if not wire_tex:
		return

	var container := Node2D.new()
	container.name = "WiringContainer"
	container.z_index = 0
	parent_node.add_child(container)

	var paths := {
		"Terminal_1": [Vector2i(18, 20), Vector2i(19, 20), Vector2i(20, 20), Vector2i(21, 20), Vector2i(22, 20), Vector2i(23, 20), Vector2i(24, 20), Vector2i(25, 20), Vector2i(26, 20), Vector2i(27, 20), Vector2i(28, 20)],
		"Terminal_2": [Vector2i(42, 27), Vector2i(43, 27), Vector2i(44, 27), Vector2i(45, 27)],
		"Terminal_3": [Vector2i(64, 27), Vector2i(65, 27), Vector2i(66, 27), Vector2i(67, 27)],
		"Terminal_4": [Vector2i(80, 17), Vector2i(81, 17), Vector2i(82, 17), Vector2i(83, 17)],
		"Terminal_5": [Vector2i(103, 25), Vector2i(104, 25), Vector2i(105, 25), Vector2i(106, 25), Vector2i(107, 25)],
	}

	for term_id in paths.keys():
		var arr: Array[Sprite2D] = []
		var pts: Array = paths[term_id]
		var solved := _solved_terminals.has(term_id)
		var row_idx := 2 if solved else 1
		for i in range(pts.size()):
			var p: Vector2i = pts[i]
			var col_idx := 5 if (i == 0 or i == pts.size() - 1) else 0
			var sp := Sprite2D.new()
			sp.centered = false
			sp.position = Vector2(p.x * 16.0, p.y * 16.0)
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var at := AtlasTexture.new()
			at.atlas = wire_tex
			at.region = Rect2(col_idx * 16, row_idx * 16, 16, 16)
			sp.texture = at
			container.add_child(sp)
			arr.append(sp)
		_wire_groups[term_id] = arr


func _mark_wire_solved(terminal_id: String) -> void:
	if not _wire_groups.has(terminal_id):
		return
	for sp in _wire_groups[terminal_id]:
		if is_instance_valid(sp):
			var at := sp.texture as AtlasTexture
			if at:
				var reg := at.region
				reg.position.y = 32.0
				at.region = reg
