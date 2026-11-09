@tool
extends Node2D

const TILESET_PATH := "res://resources/tilesets/world_1_tileset.tres"
const BUBBLE_HELO_PATH := "res://assets/ui/bubble_helo_dave.png"
const DEX_SPAWN_POS := Vector2(579.0, 96.0)
const TOTAL_TERMINALS := 4

const TERMINAL_CONFIGS := {
	"Terminal_1": {
		"title": "TERMINAL 1: LASER KEAMANAN KORIDOR ATAS",
		"objective": "Perbaiki NameError pada fungsi cetak dan matikan Laser Oranye (kode_akses = 101).",
		"initial_code": [
			"status_laser = \"STANDBY\"",
			"kode_akses = 101",
			"prin(status_laser)",
			"matikan_laser_oranye(kode_akses)"
		],
		"locked_lines": [0, 1, 3],
		"required_call": "matikan_laser_oranye",
		"expected_arg": 101,
		"require_print": true,
		"expected_print": "STANDBY",
		"logical_fail_hint": "Pastikan fungsi print(status_laser) terpanggil sebelum matikan_laser_oranye(kode_akses).",
		"success_message": "Laser Oranye Koridor Atas dinonaktifkan! Jalan menuju sektor kiri terbuka.",
		"hints": [
			"Lint: \"Lihat baris ke-3! Ada typo pada nama fungsi untuk mencetak teks ke layar.\"",
			"Lint: \"Di Python, fungsi untuk menampilkan output ke konsol adalah print(...), bukan prin(...).\"",
			"Lint: \"Ubah baris ke-3 menjadi: print(status_laser)\""
		],
		"bug_log_entry": {
			"terminal_id": "Terminal_1",
			"bug_type": "NameError (Typo Nama Fungsi)",
			"broken_code": "prin(status_laser)",
			"fixed_code": "print(status_laser)",
			"explanation": "NameError muncul ketika Python tidak mengenali nama fungsi atau variabel karena salah ketik (typo). Fungsi bawaan Python untuk mencetak ke layar adalah print()."
		}
	},
	"Terminal_2": {
		"title": "TERMINAL 2: GENERATOR ELEVATOR SEKTOR KIRI",
		"objective": "Perbaiki TypeError agar total_daya bernilai 100 untuk mengaktifkan Elevator.",
		"initial_code": [
			"daya_awal = \"60\"",
			"daya_tambahan = 40",
			"total_daya = daya_awal + daya_tambahan",
			"aktifkan_elevator(total_daya)"
		],
		"locked_lines": [1, 2, 3],
		"required_call": "aktifkan_elevator",
		"expected_arg": 100,
		"require_print": false,
		"expected_print": "",
		"logical_fail_hint": "Elevator membutuhkan total_daya tepat sebesar 100 (integer), bukan nilai lain.",
		"success_message": "Generator Elevator menyala (100W)! Platform Elevator di kiri sekarang aktif bergerak.",
		"hints": [
			"Lint: \"Perhatikan baris 1! Mengapa angka 60 dibungkus tanda kutip?\"",
			"Lint: \"Tanda kutip membuat \"60\" menjadi teks (str), sehingga tidak bisa dijumlahkan dengan angka 40 (int).\"",
			"Lint: \"Hapus tanda kutip pada baris 1 sehingga menjadi: daya_awal = 60\""
		],
		"bug_log_entry": {
			"terminal_id": "Terminal_2",
			"bug_type": "TypeError (String + Integer)",
			"broken_code": "daya_awal = \"60\"",
			"fixed_code": "daya_awal = 60",
			"explanation": "TypeError terjadi saat kita menjumlahkan teks (str) dengan angka bulat (int). Angka yang akan dihitung secara matematis tidak boleh memakai tanda kutip."
		}
	},
	"Terminal_3": {
		"title": "TERMINAL 3: REGULATOR TEGANGAN LASER BIRU",
		"objective": "Perbaiki operator aritmetika agar sisa_tegangan bernilai 0 untuk mematikan kedua Laser Biru.",
		"initial_code": [
			"tegangan_awal = 50",
			"pengurang = 50",
			"sisa_tegangan = tegangan_awal + pengurang",
			"set_tegangan_laser_biru(sisa_tegangan)"
		],
		"locked_lines": [0, 1, 3],
		"required_call": "set_tegangan_laser_biru",
		"expected_arg": 0,
		"require_print": false,
		"expected_print": "",
		"logical_fail_hint": "Kode berjalan tanpa error, tetapi sisa_tegangan bernilai 100V! Kita butuh 0V untuk mematikan laser.",
		"success_message": "Tegangan Laser Biru berhasil diturunkan ke 0V! Kedua penghalang Laser Biru telah mati.",
		"hints": [
			"Lint: \"Program ini tidak menghasilkan pesan error, tapi lihat hasil perhitungannya!\"",
			"Lint: \"Pada baris 3, tegangan_awal justru ditambah (+) dengan pengurang sehingga menjadi 100.\"",
			"Lint: \"Ganti tanda + menjadi - pada baris 3: sisa_tegangan = tegangan_awal - pengurang\""
		],
		"bug_log_entry": {
			"terminal_id": "Terminal_3",
			"bug_type": "Logical Bug (Salah Operator Aritmetika)",
			"broken_code": "sisa_tegangan = tegangan_awal + pengurang",
			"fixed_code": "sisa_tegangan = tegangan_awal - pengurang",
			"explanation": "Logical Bug tidak memunculkan pesan error, tetapi menghasilkan nilai yang salah karena kesalahan rumus/operator (+ seharusnya -)."
		}
	},
	"Terminal_4": {
		"title": "TERMINAL 4: OTORISASI GERBANG EXIT & CRANE",
		"objective": "Perbaiki rumus luas persegi (5 x 5 = 25) untuk membebaskan Robot & membuka Exit Gate.",
		"initial_code": [
			"panjang = 5",
			"lebar = 5",
			"kunci_gerbang = panjang * lebar - 10",
			"print(kunci_gerbang)",
			"buka_gerbang_exit(kunci_gerbang)"
		],
		"locked_lines": [0, 1, 3, 4],
		"required_call": "buka_gerbang_exit",
		"expected_arg": 25,
		"require_print": true,
		"expected_print": "25",
		"logical_fail_hint": "Gerbang membutuhkan kode luas persegi utuh (5 * 5 = 25). Mengapa masih dikurangi 10?",
		"success_message": "Otorisasi Gerbang Exit diterima (Kode: 25)! Capit Crane melepaskan robot dan Gerbang Exit terbuka!",
		"hints": [
			"Lint: \"Lihat baris ke-3! Rumus kunci_gerbang seharusnya hanya panjang dikali lebar.\"",
			"Lint: \"Saat ini hasilnya 5 * 5 - 10 = 15, padahal Gerbang Exit meminta nilai 25.\"",
			"Lint: \"Hapus '- 10' pada baris 3 sehingga menjadi: kunci_gerbang = panjang * lebar\""
		],
		"bug_log_entry": {
			"terminal_id": "Terminal_4",
			"bug_type": "Logical Bug (Kesalahan Rumus Perhitungan)",
			"broken_code": "kunci_gerbang = panjang * lebar - 10",
			"fixed_code": "kunci_gerbang = panjang * lebar",
			"explanation": "Operasi yang tidak diperlukan (- 10) pada rumus menyebabkan output menjadi 15 alih-alih 25 yang diminta sistem."
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

var _is_overview_cam: bool = true
var _bubble_helo_sprite: Sprite2D = null
var _solved_terminals: Dictionary = {}
var _bug_log_entries: Array[Dictionary] = []
var _hud_progress_label: Label = null
var _hud_bug_log_btn: Button = null
var _bug_log_modal: PanelContainer = null
var _bug_log_vbox: VBoxContainer = null
var _bug_log_title: Label = null
var _bug_log_subtitle: Label = null
var _level_completed: bool = false


func _ready() -> void:
	_build_all()
	if not Engine.is_editor_hint():
		_setup_runtime()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and is_instance_valid(_bubble_helo_sprite) and dex:
		_bubble_helo_sprite.visible = dex.global_position.distance_to(DEX_SPAWN_POS) < 28.0


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_toggle_camera_mode()
		elif event.keycode == KEY_L:
			_toggle_bug_log_modal(false)


func _toggle_camera_mode() -> void:
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
	if overview_cam:
		overview_cam.enabled = true
		overview_cam.make_current()
	var dex_cam: Camera2D = dex.get_node_or_null("Camera2D") if dex else null
	if dex_cam:
		dex_cam.enabled = false

	# Initial puzzle states at runtime:
	# Elevator starts inactive until Terminal_2 is solved!
	var elev: Node = get_node_or_null("Programmable/ElevatorPlatform")
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
	_update_hud_display("Misi 1: Dekati Terminal 1 di kiri koridor atas dan tekan [E]")


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

	if hud_status:
		hud_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hud_status.add_theme_font_size_override("font_size", 13)

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
		_hud_bug_log_btn.text = "Bug Log (0/4) [L]"
		_hud_bug_log_btn.add_theme_font_size_override("font_size", 12)
		_hud_bug_log_btn.pressed.connect(func() -> void: _toggle_bug_log_modal(false))
		hbox.add_child(_hud_bug_log_btn)

	_build_bug_log_modal()


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
	hud_layer.add_child(_bug_log_modal)

	var outer_vbox := VBoxContainer.new()
	outer_vbox.add_theme_constant_override("separation", 10)
	_bug_log_modal.add_child(outer_vbox)

	_bug_log_title = Label.new()
	_bug_log_title.text = "BUG LOG — DUNIA 1: SYNTAX SHORE"
	_bug_log_title.add_theme_font_size_override("font_size", 18)
	_bug_log_title.add_theme_color_override("font_color", Color(0.35, 0.95, 0.65))
	outer_vbox.add_child(_bug_log_title)

	_bug_log_subtitle = Label.new()
	_bug_log_subtitle.text = "Catatan seluruh bug Python yang telah kamu perbaiki bersama Lint:"
	_bug_log_subtitle.add_theme_font_size_override("font_size", 13)
	_bug_log_subtitle.add_theme_color_override("font_color", Color(0.8, 0.86, 0.95))
	outer_vbox.add_child(_bug_log_subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer_vbox.add_child(scroll)

	_bug_log_vbox = VBoxContainer.new()
	_bug_log_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bug_log_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(_bug_log_vbox)

	var close_btn := Button.new()
	close_btn.text = "Tutup [L / Esc]"
	close_btn.custom_minimum_size = Vector2(160, 34)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.pressed.connect(func() -> void: _bug_log_modal.visible = false)
	outer_vbox.add_child(close_btn)


func _toggle_bug_log_modal(is_level_clear: bool) -> void:
	if not _bug_log_modal:
		return
	if _bug_log_modal.visible and not is_level_clear:
		_bug_log_modal.visible = false
		return

	if is_level_clear:
		_bug_log_title.text = "LEVEL 1 SELESAI! — DUNIA 1: SYNTAX SHORE"
		_bug_log_subtitle.text = "Selamat! Dex & Lint berhasil memperbaiki semua 4 Terminal dan membuka Gerbang Exit! Berikut ringkasan Bug Log:"
	else:
		_bug_log_title.text = "BUG LOG — DUNIA 1: SYNTAX SHORE (%d/%d)" % [_solved_terminals.size(), TOTAL_TERMINALS]
		_bug_log_subtitle.text = "Catatan bug Python yang telah diperbaiki sejauh ini:"

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

	_setup_dave_bubble()
	_setup_terminals()


func _setup_dave_bubble() -> void:
	var decor_root: Node2D = get_node_or_null("WorldDecor")
	if not decor_root:
		return
	for child in decor_root.get_children():
		decor_root.remove_child(child)
		child.queue_free()

	var b_tex: Texture2D = load(BUBBLE_HELO_PATH)
	if b_tex:
		_bubble_helo_sprite = Sprite2D.new()
		_bubble_helo_sprite.name = "BubbleHeloDave"
		_bubble_helo_sprite.centered = false
		_bubble_helo_sprite.texture = b_tex
		_bubble_helo_sprite.position = Vector2(548.0, 52.0)
		decor_root.add_child(_bubble_helo_sprite)


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
		# Update checkpoint to latest visited terminal
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
		"matikan_laser_oranye":
			if typeof(arg_value) == TYPE_INT and int(arg_value) == 101:
				var laser_o: Node = get_node_or_null("Programmable/LaserOrange_Top")
				if laser_o and laser_o.has_method("set_active"):
					laser_o.call("set_active", false)
		"aktifkan_elevator":
			if typeof(arg_value) == TYPE_INT and int(arg_value) == 100:
				var elev: Node = get_node_or_null("Programmable/ElevatorPlatform")
				if elev and elev.has_method("set_active"):
					elev.call("set_active", true)
		"set_tegangan_laser_biru":
			if typeof(arg_value) == TYPE_INT and int(arg_value) == 0:
				var lb_v: Node = get_node_or_null("Programmable/LaserBlue_Vert")
				var lb_h: Node = get_node_or_null("Programmable/LaserBlue_Horiz")
				if lb_v and lb_v.has_method("set_active"):
					lb_v.call("set_active", false)
				if lb_h and lb_h.has_method("set_active"):
					lb_h.call("set_active", false)
		"buka_gerbang_exit":
			if typeof(arg_value) == TYPE_INT and int(arg_value) == 25:
				var crane: Node = get_node_or_null("Programmable/CraneClaw")
				if crane and crane.has_method("release_robot"):
					crane.call("release_robot")
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
			next_msg = "Laser Oranye mati! Lanjut ke kiri menuju Terminal 2 untuk menyalakan Elevator."
		"Terminal_2":
			next_msg = "Elevator aktif! Turun dan lompat ke Terminal 3 (monitor gantung tengah)."
		"Terminal_3":
			next_msg = "Laser Biru mati! Naik ke platform kanan menuju Terminal 4 untuk membuka Exit Gate."
		"Terminal_4":
			next_msg = "Gerbang Exit terbuka & Robot bebas! Turun ke pit kanan (EXIT) untuk menyelesaikan Level 1!"

	_update_hud_display(next_msg)
	if hud_status:
		hud_status.modulate = Color(0.4, 1.0, 0.6)


func _on_level_completed() -> void:
	if _level_completed:
		return
	_level_completed = true
	_update_hud_display("SELAMAT! Level 1: Syntax Shore berhasil diselesaikan!")
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

	var full_box := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)
	])
	var top_half := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, 0), Vector2(-8, 0)
	])
	var bottom_half := PackedVector2Array([
		Vector2(-8, 0), Vector2(8, 0), Vector2(8, 8), Vector2(-8, 8)
	])
	var one_way_strip := PackedVector2Array([
		Vector2(-8, -8), Vector2(8, -8), Vector2(8, -2), Vector2(-8, -2)
	])

	var solid_coords: Array[Vector2i] = []
	for ry in range(1, 6):
		for rx in range(0, 7):
			solid_coords.append(Vector2i(rx, ry))
	for rx in range(7, 10):
		solid_coords.append(Vector2i(rx, 4))
	for ry in range(6, 8):
		for rx in range(2, 7):
			solid_coords.append(Vector2i(rx, ry))
	for rx in range(7, 10):
		solid_coords.append(Vector2i(rx, 6))
		solid_coords.append(Vector2i(rx, 13))

	for c in solid_coords:
		if atlas.has_tile(c):
			var td: TileData = atlas.get_tile_data(c, 0)
			if td:
				td.set_collision_polygons_count(0, 1)
				td.set_collision_polygon_points(0, 0, full_box)
				td.set_collision_polygon_one_way(0, 0, false)

	if atlas.has_tile(Vector2i(9, 0)):
		var td90: TileData = atlas.get_tile_data(Vector2i(9, 0), 0)
		td90.set_collision_polygons_count(0, 1)
		td90.set_collision_polygon_points(0, 0, top_half)
	if atlas.has_tile(Vector2i(9, 1)):
		var td91: TileData = atlas.get_tile_data(Vector2i(9, 1), 0)
		td91.set_collision_polygons_count(0, 1)
		td91.set_collision_polygon_points(0, 0, bottom_half)

	var slopes := {
		Vector2i(0, 6): PackedVector2Array([Vector2(8, -8), Vector2(8, 8), Vector2(-8, 8)]),
		Vector2i(1, 6): PackedVector2Array([Vector2(-8, -8), Vector2(8, 8), Vector2(-8, 8)]),
		Vector2i(0, 7): PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(8, 8)]),
		Vector2i(1, 7): PackedVector2Array([Vector2(-8, -8), Vector2(8, -8), Vector2(-8, 8)]),
	}
	for sc in slopes.keys():
		if atlas.has_tile(sc):
			var tds: TileData = atlas.get_tile_data(sc, 0)
			tds.set_collision_polygons_count(0, 1)
			tds.set_collision_polygon_points(0, 0, slopes[sc])

	var one_way_coords: Array[Vector2i] = [
		Vector2i(7, 0), Vector2i(8, 0),
		Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2),
		Vector2i(7, 3), Vector2i(8, 3), Vector2i(9, 3),
		Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8),
	]
	for ow in one_way_coords:
		if atlas.has_tile(ow):
			var tdo: TileData = atlas.get_tile_data(ow, 0)
			tdo.set_collision_polygons_count(0, 1)
			tdo.set_collision_polygon_points(0, 0, one_way_strip)
			tdo.set_collision_polygon_one_way(0, 0, true)


func _populate_bg_layer(layer: TileMapLayer) -> void:
	layer.clear()
	for y in range(20, 25):
		for x in range(22, 32):
			layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 11))
	for y in range(17, 21):
		for x in range(39, 41):
			layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 11))

	var vents: Array[Vector2i] = [
		Vector2i(11, 9), Vector2i(13, 9),
		Vector2i(11, 11), Vector2i(13, 11),
		Vector2i(11, 16), Vector2i(13, 16), Vector2i(15, 16),
	]
	for v in vents:
		layer.set_cell(v, 0, Vector2i(3, 12))
		layer.set_cell(v + Vector2i(1, 0), 0, Vector2i(4, 12))
		layer.set_cell(v + Vector2i(0, 1), 0, Vector2i(3, 13))
		layer.set_cell(v + Vector2i(1, 1), 0, Vector2i(4, 13))

	var big_panels: Array[Vector2i] = [
		Vector2i(12, 3), Vector2i(14, 3), Vector2i(10, 4), Vector2i(12, 5),
	]
	for p in big_panels:
		layer.set_cell(p, 0, Vector2i(0, 12))
		layer.set_cell(p + Vector2i(1, 0), 0, Vector2i(1, 12))
		layer.set_cell(p + Vector2i(0, 1), 0, Vector2i(0, 13))
		layer.set_cell(p + Vector2i(1, 1), 0, Vector2i(1, 13))

	var quad_clusters: Array[Vector2i] = [
		Vector2i(31, 10), Vector2i(25, 16), Vector2i(34, 16),
	]
	for qc in quad_clusters:
		for dy in range(2):
			for dx in range(2):
				layer.set_cell(qc + Vector2i(dx, dy), 0, Vector2i(2, 12))

	var small_sq: Array[Vector2i] = [
		Vector2i(16, 4), Vector2i(17, 4), Vector2i(19, 4), Vector2i(19, 5), Vector2i(14, 5),
		Vector2i(17, 12), Vector2i(19, 12), Vector2i(21, 12), Vector2i(23, 12), Vector2i(25, 12), Vector2i(27, 12),
		Vector2i(19, 8), Vector2i(19, 10), Vector2i(21, 8),
	]
	for s in small_sq:
		layer.set_cell(s, 0, Vector2i(2, 11))

	var pillars: Array = [
		[5, 3, 14], [5, 16, 18],
		[9, 3, 14], [9, 16, 18],
		[17, 16, 18], [17, 23, 24],
		[21, 16, 18], [21, 22, 24],
		[24, 11, 14], [24, 16, 18],
		[28, 7, 9],
		[37, 11, 18],
		[44, 10, 12],
	]
	for pil in pillars:
		var px: int = pil[0]
		var y1: int = pil[1]
		var y2: int = pil[2]
		for y in range(y1, y2 + 1):
			var ty: int = 11 + ((y - y1) % 3)
			layer.set_cell(Vector2i(px, y), 0, Vector2i(5, ty))

	# Hanging ceiling wires & brackets
	layer.set_cell(Vector2i(21, 3), 0, Vector2i(0, 10))
	layer.set_cell(Vector2i(22, 3), 0, Vector2i(1, 10))
	layer.set_cell(Vector2i(26, 3), 0, Vector2i(0, 10))
	layer.set_cell(Vector2i(27, 3), 0, Vector2i(1, 10))
	layer.set_cell(Vector2i(40, 7), 0, Vector2i(0, 10))
	layer.set_cell(Vector2i(41, 7), 0, Vector2i(1, 10))
	layer.set_cell(Vector2i(4, 6), 0, Vector2i(3, 0))
	layer.set_cell(Vector2i(9, 7), 0, Vector2i(2, 0))
	layer.set_cell(Vector2i(28, 10), 0, Vector2i(3, 0))
	layer.set_cell(Vector2i(25, 15), 0, Vector2i(3, 0))
	layer.set_cell(Vector2i(42, 13), 0, Vector2i(2, 0))


func _populate_terrain_layer(layer: TileMapLayer) -> void:
	layer.clear()
	for x in [27, 29, 31, 33, 35, 37]:
		layer.set_cell(Vector2i(x, 1), 0, Vector2i(9, 1))

	layer.set_cell(Vector2i(2, 2), 0, Vector2i(0, 6))
	layer.set_cell(Vector2i(3, 2), 0, Vector2i(0, 4))
	layer.set_cell(Vector2i(4, 2), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(5, 2), 0, Vector2i(7, 4))
	for x in range(6, 9):
		layer.set_cell(Vector2i(x, 2), 0, Vector2i(8, 4))
	layer.set_cell(Vector2i(9, 2), 0, Vector2i(9, 4))
	layer.set_cell(Vector2i(10, 2), 0, Vector2i(0, 4))
	for x in range(11, 23):
		layer.set_cell(Vector2i(x, 2), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(23, 2), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(24, 2), 0, Vector2i(4, 4))
	for x in range(25, 38):
		layer.set_cell(Vector2i(x, 2), 0, Vector2i(1, 5))
	layer.set_cell(Vector2i(38, 2), 0, Vector2i(5, 5))

	layer.set_cell(Vector2i(2, 3), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(3, 3), 0, Vector2i(1, 7))
	layer.set_cell(Vector2i(2, 4), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(1, 5), 0, Vector2i(9, 1))
	layer.set_cell(Vector2i(2, 5), 0, Vector2i(6, 3))
	for y in range(6, 9):
		var ty := y - 5
		layer.set_cell(Vector2i(1, y), 0, Vector2i(0, ty))
		layer.set_cell(Vector2i(2, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(3, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(4, y), 0, Vector2i(2, ty))
	layer.set_cell(Vector2i(5, 6), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(1, 9), 0, Vector2i(0, 7))
	layer.set_cell(Vector2i(2, 9), 0, Vector2i(1, 3))
	layer.set_cell(Vector2i(3, 9), 0, Vector2i(2, 3))
	layer.set_cell(Vector2i(4, 9), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(2, 10), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(3, 10), 0, Vector2i(9, 0))
	layer.set_cell(Vector2i(2, 11), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(1, 12), 0, Vector2i(9, 1))
	layer.set_cell(Vector2i(2, 12), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(3, 12), 0, Vector2i(9, 1))
	for y in range(13, 16):
		var ty := y - 12
		layer.set_cell(Vector2i(1, y), 0, Vector2i(0, ty))
		layer.set_cell(Vector2i(2, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(3, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(4, y), 0, Vector2i(2, ty))
	layer.set_cell(Vector2i(2, 16), 0, Vector2i(0, 7))
	layer.set_cell(Vector2i(3, 16), 0, Vector2i(1, 3))
	layer.set_cell(Vector2i(4, 16), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(3, 17), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(3, 18), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(3, 19), 0, Vector2i(0, 7))

	layer.set_cell(Vector2i(37, 3), 0, Vector2i(2, 7))
	layer.set_cell(Vector2i(38, 3), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(38, 4), 0, Vector2i(3, 1))
	layer.set_cell(Vector2i(39, 4), 0, Vector2i(9, 1))
	layer.set_cell(Vector2i(37, 5), 0, Vector2i(2, 7))
	layer.set_cell(Vector2i(38, 5), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(39, 5), 0, Vector2i(1, 2))
	layer.set_cell(Vector2i(40, 5), 0, Vector2i(1, 6))

	layer.set_cell(Vector2i(23, 6), 0, Vector2i(9, 1))
	layer.set_cell(Vector2i(24, 6), 0, Vector2i(4, 4))
	for x in range(25, 37):
		layer.set_cell(Vector2i(x, 6), 0, Vector2i(1, 5))
	for x in range(37, 44):
		layer.set_cell(Vector2i(x, 6), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(44, 6), 0, Vector2i(1, 6))

	layer.set_cell(Vector2i(10, 7), 0, Vector2i(0, 4))
	for x in range(11, 23):
		layer.set_cell(Vector2i(x, 7), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(23, 7), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(10, 8), 0, Vector2i(9, 0))
	layer.set_cell(Vector2i(24, 7), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(24, 8), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(24, 9), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(25, 7), 0, Vector2i(1, 7))

	layer.set_cell(Vector2i(21, 10), 0, Vector2i(7, 2))
	layer.set_cell(Vector2i(22, 10), 0, Vector2i(8, 2))
	layer.set_cell(Vector2i(23, 10), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(24, 10), 0, Vector2i(0, 4))
	layer.set_cell(Vector2i(25, 10), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(26, 10), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(27, 10), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(15, 12), 0, Vector2i(7, 2))
	layer.set_cell(Vector2i(16, 12), 0, Vector2i(8, 2))
	layer.set_cell(Vector2i(17, 12), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(37, 11), 0, Vector2i(7, 3))
	layer.set_cell(Vector2i(38, 11), 0, Vector2i(8, 3))
	layer.set_cell(Vector2i(39, 11), 0, Vector2i(9, 3))

	# Helper stepping platforms so Dex can smoothly traverse all floors & pits
	layer.set_cell(Vector2i(19, 14), 0, Vector2i(7, 2))
	layer.set_cell(Vector2i(20, 14), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(12, 17), 0, Vector2i(7, 2))
	layer.set_cell(Vector2i(13, 17), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(35, 17), 0, Vector2i(7, 3))
	layer.set_cell(Vector2i(36, 17), 0, Vector2i(9, 3))
	layer.set_cell(Vector2i(35, 15), 0, Vector2i(7, 3))
	layer.set_cell(Vector2i(36, 15), 0, Vector2i(9, 3))
	layer.set_cell(Vector2i(39, 13), 0, Vector2i(7, 3))
	layer.set_cell(Vector2i(40, 13), 0, Vector2i(9, 3))
	layer.set_cell(Vector2i(19, 21), 0, Vector2i(7, 2))
	layer.set_cell(Vector2i(20, 21), 0, Vector2i(9, 2))
	layer.set_cell(Vector2i(19, 23), 0, Vector2i(7, 2))
	layer.set_cell(Vector2i(20, 23), 0, Vector2i(9, 2))

	layer.set_cell(Vector2i(43, 7), 0, Vector2i(0, 7))
	for y in range(7, 10):
		var ty := y - 6
		layer.set_cell(Vector2i(44, y), 0, Vector2i(0, ty))
		layer.set_cell(Vector2i(45, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(46, y), 0, Vector2i(2, ty))
	layer.set_cell(Vector2i(47, 9), 0, Vector2i(9, 1))
	layer.set_cell(Vector2i(44, 10), 0, Vector2i(0, 7))
	for y in range(10, 13):
		var ty := y - 9
		layer.set_cell(Vector2i(45, y), 0, Vector2i(0, ty))
		layer.set_cell(Vector2i(46, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(47, y), 0, Vector2i(2, ty))
	layer.set_cell(Vector2i(42, 13), 0, Vector2i(7, 3))
	for y in range(13, 16):
		var ty := y - 12
		layer.set_cell(Vector2i(43, y), 0, Vector2i(0, ty))
		layer.set_cell(Vector2i(44, y), 0, Vector2i(1, ty))
		layer.set_cell(Vector2i(45, y), 0, Vector2i(2, ty))
	layer.set_cell(Vector2i(46, 13), 0, Vector2i(2, 3))
	layer.set_cell(Vector2i(46, 14), 0, Vector2i(1, 7))
	layer.set_cell(Vector2i(41, 16), 0, Vector2i(0, 6))
	layer.set_cell(Vector2i(42, 16), 0, Vector2i(0, 3))
	layer.set_cell(Vector2i(43, 16), 0, Vector2i(1, 3))
	layer.set_cell(Vector2i(44, 16), 0, Vector2i(2, 3))
	layer.set_cell(Vector2i(41, 17), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(42, 17), 0, Vector2i(3, 1))
	layer.set_cell(Vector2i(41, 18), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(42, 18), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(41, 19), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(42, 19), 0, Vector2i(9, 0))
	layer.set_cell(Vector2i(41, 20), 0, Vector2i(6, 3))

	for x in range(5, 10):
		var tx := 7 + ((x - 5) % 2)
		layer.set_cell(Vector2i(x, 15), 0, Vector2i(tx, 0))
	layer.set_cell(Vector2i(10, 15), 0, Vector2i(0, 4))
	for x in range(11, 21):
		layer.set_cell(Vector2i(x, 15), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(21, 15), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(22, 15), 0, Vector2i(3, 5))
	layer.set_cell(Vector2i(23, 15), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(24, 15), 0, Vector2i(4, 4))
	layer.set_cell(Vector2i(25, 15), 0, Vector2i(7, 3))
	layer.set_cell(Vector2i(26, 15), 0, Vector2i(8, 3))
	layer.set_cell(Vector2i(27, 15), 0, Vector2i(9, 3))

	layer.set_cell(Vector2i(4, 19), 0, Vector2i(0, 4))
	layer.set_cell(Vector2i(5, 19), 0, Vector2i(3, 4))
	for x in range(6, 16):
		layer.set_cell(Vector2i(x, 19), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(16, 19), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(17, 19), 0, Vector2i(3, 6))
	layer.set_cell(Vector2i(21, 19), 0, Vector2i(3, 6))
	layer.set_cell(Vector2i(22, 19), 0, Vector2i(3, 4))
	for x in range(23, 37):
		layer.set_cell(Vector2i(x, 19), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(37, 19), 0, Vector2i(5, 4))

	layer.set_cell(Vector2i(38, 18), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(38, 19), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(38, 20), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(36, 20), 0, Vector2i(9, 0))
	layer.set_cell(Vector2i(37, 20), 0, Vector2i(4, 1))
	layer.set_cell(Vector2i(38, 21), 0, Vector2i(7, 4))
	layer.set_cell(Vector2i(39, 21), 0, Vector2i(8, 4))
	layer.set_cell(Vector2i(40, 21), 0, Vector2i(8, 4))
	layer.set_cell(Vector2i(41, 21), 0, Vector2i(9, 4))

	layer.set_cell(Vector2i(17, 20), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(16, 21), 0, Vector2i(0, 6))
	layer.set_cell(Vector2i(17, 21), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(13, 22), 0, Vector2i(0, 4))
	layer.set_cell(Vector2i(14, 22), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(15, 22), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(16, 22), 0, Vector2i(5, 4))
	layer.set_cell(Vector2i(17, 22), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(13, 23), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(13, 24), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(14, 24), 0, Vector2i(1, 6))
	layer.set_cell(Vector2i(21, 20), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(21, 21), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(29, 20), 0, Vector2i(2, 7))
	layer.set_cell(Vector2i(30, 20), 0, Vector2i(2, 7))
	layer.set_cell(Vector2i(31, 20), 0, Vector2i(2, 7))
	layer.set_cell(Vector2i(32, 20), 0, Vector2i(6, 1))
	layer.set_cell(Vector2i(33, 20), 0, Vector2i(2, 2))
	layer.set_cell(Vector2i(34, 20), 0, Vector2i(9, 0))
	layer.set_cell(Vector2i(32, 21), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(33, 21), 0, Vector2i(1, 7))
	layer.set_cell(Vector2i(32, 22), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(32, 23), 0, Vector2i(6, 2))
	layer.set_cell(Vector2i(31, 24), 0, Vector2i(0, 6))
	layer.set_cell(Vector2i(32, 24), 0, Vector2i(6, 3))
	layer.set_cell(Vector2i(13, 25), 0, Vector2i(0, 4))
	for x in range(14, 32):
		layer.set_cell(Vector2i(x, 25), 0, Vector2i(1, 4))
	layer.set_cell(Vector2i(32, 25), 0, Vector2i(5, 4))
	for x in [13, 16, 19, 22, 25, 28, 31]:
		layer.set_cell(Vector2i(x, 26), 0, Vector2i(9, 0))


func _populate_props_layer(layer: TileMapLayer) -> void:
	layer.clear()
	# Orange floor pad in right pit
	layer.set_cell(Vector2i(39, 20), 0, Vector2i(7, 10))
	layer.set_cell(Vector2i(40, 20), 0, Vector2i(9, 10))
