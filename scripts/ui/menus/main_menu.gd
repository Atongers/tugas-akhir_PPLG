extends Control
class_name MainMenu

const FONT_BOLD_PATH := "res://assets/fonts/ttf/JetBrainsMono-Bold.ttf"
const FONT_SEMIBOLD_PATH := "res://assets/fonts/ttf/JetBrainsMono-SemiBold.ttf"
const FONT_REGULAR_PATH := "res://assets/fonts/ttf/JetBrainsMono-Regular.ttf"
const SPRITESHEET_PATH := "res://assets/sprites/characters/characters.png"
const LEVEL_1_PATH := "res://scenes/levels/world_1_syntax_shore/level_1.tscn"

const COLOR_BG_DEEP := Color(0.045, 0.06, 0.09, 1.0)
const COLOR_PANEL_BG := Color(0.08, 0.105, 0.15, 0.95)
const COLOR_CYAN := Color(0.22, 0.75, 0.98, 1.0)
const COLOR_GREEN := Color(0.28, 0.88, 0.52, 1.0)
const COLOR_AMBER := Color(0.98, 0.65, 0.22, 1.0)
const COLOR_BORDER := Color(0.18, 0.28, 0.42, 0.85)
const COLOR_BORDER_HOVER := Color(0.35, 0.85, 1.0, 1.0)

var _font_bold: FontFile = null
var _font_semibold: FontFile = null
var _font_regular: FontFile = null

# Modals
var _level_select_modal: PanelContainer = null
var _bug_log_modal: PanelContainer = null
var _settings_modal: PanelContainer = null

# Animated Dex Showcase
var _dex_sprite: Sprite2D = null
var _dex_tex: Texture2D = null
var _dex_atlas_cache: Array[AtlasTexture] = []


func _ready() -> void:
	_load_fonts()
	_load_dex_assets()
	_build_ui()
	_close_all_modals()


func _process(_delta: float) -> void:
	# Animate Dex showcase at 6.6 FPS (150ms per frame)
	if is_instance_valid(_dex_sprite) and not _dex_atlas_cache.is_empty():
		var frame_idx: int = int(Time.get_ticks_msec() / 150.0) % _dex_atlas_cache.size()
		_dex_sprite.texture = _dex_atlas_cache[frame_idx]


func _load_fonts() -> void:
	if ResourceLoader.exists(FONT_BOLD_PATH):
		_font_bold = load(FONT_BOLD_PATH)
	if ResourceLoader.exists(FONT_SEMIBOLD_PATH):
		_font_semibold = load(FONT_SEMIBOLD_PATH)
	if ResourceLoader.exists(FONT_REGULAR_PATH):
		_font_regular = load(FONT_REGULAR_PATH)


func _load_dex_assets() -> void:
	if not ResourceLoader.exists(SPRITESHEET_PATH):
		return
	_dex_tex = load(SPRITESHEET_PATH)
	if not _dex_tex:
		return
	# Row 2 (index 1: Cyan Antenna Bot) idle frames (cols 0..3)
	var y_start: int = 1 * 32 - 2
	for col in range(4):
		var at := AtlasTexture.new()
		at.atlas = _dex_tex
		at.region = Rect2(2 + col * 16, y_start, 16, 32)
		at.filter_clip = true
		_dex_atlas_cache.append(at)


func _build_ui() -> void:
	# Full-screen base setup
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# 1. Background Rect
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = COLOR_BG_DEEP
	add_child(bg)

	# 2. Sci-Fi decorative grid & header lines
	var decor := Control.new()
	decor.name = "DecorOverlay"
	decor.set_anchors_preset(Control.PRESET_FULL_RECT)
	decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(decor)

	# 3. Main Horizontal Layout (Left: Title & Navigation, Right: Animated Character Showcase)
	var main_margin := MarginContainer.new()
	main_margin.name = "MainMargin"
	main_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_margin.add_theme_constant_override("margin_left", 60)
	main_margin.add_theme_constant_override("margin_right", 60)
	main_margin.add_theme_constant_override("margin_top", 45)
	main_margin.add_theme_constant_override("margin_bottom", 40)
	add_child(main_margin)

	var hbox := HBoxContainer.new()
	hbox.name = "MainHBox"
	hbox.add_theme_constant_override("separation", 50)
	main_margin.add_child(hbox)

	# Left Column: Brand & Nav Buttons
	var left_vbox := VBoxContainer.new()
	left_vbox.name = "NavColumn"
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_stretch_ratio = 1.2
	left_vbox.add_theme_constant_override("separation", 18)
	hbox.add_child(left_vbox)

	# Brand Header
	var brand_box := VBoxContainer.new()
	brand_box.add_theme_constant_override("separation", 4)
	left_vbox.add_child(brand_box)

	var title_lbl := Label.new()
	title_lbl.name = "TitleLabel"
	title_lbl.text = "DEX & LINT"
	if _font_bold:
		title_lbl.add_theme_font_override("font", _font_bold)
	title_lbl.add_theme_font_size_override("font_size", 42)
	title_lbl.add_theme_color_override("font_color", COLOR_CYAN)
	brand_box.add_child(title_lbl)

	var subtitle_lbl := Label.new()
	subtitle_lbl.name = "SubtitleLabel"
	subtitle_lbl.text = "PYTHON DEBUGGING PUZZLE-PLATFORMER"
	if _font_semibold:
		subtitle_lbl.add_theme_font_override("font", _font_semibold)
	subtitle_lbl.add_theme_font_size_override("font_size", 14)
	subtitle_lbl.add_theme_color_override("font_color", COLOR_GREEN)
	brand_box.add_child(subtitle_lbl)

	var desc_lbl := Label.new()
	desc_lbl.name = "DescriptionLabel"
	desc_lbl.text = "Jelajahi Codeverse, perbaiki baris kode Python yang rusak di terminal, dan pulihkan sistem stasiun data Syntax Shore bersama Dex & Lint."
	if _font_regular:
		desc_lbl.add_theme_font_override("font", _font_regular)
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.72, 0.78, 0.88))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	brand_box.add_child(desc_lbl)

	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = COLOR_BORDER
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	left_vbox.add_child(sep)

	# 5 GDD Buttons
	var btn_vbox := VBoxContainer.new()
	btn_vbox.name = "ButtonList"
	btn_vbox.add_theme_constant_override("separation", 10)
	left_vbox.add_child(btn_vbox)

	var b_play := _create_menu_button("▶  Lanjut Petualangan (Level 1)", COLOR_GREEN)
	b_play.pressed.connect(_on_continue_pressed)
	btn_vbox.add_child(b_play)

	var b_level := _create_menu_button("🗺️  Pilih Dunia dan Level", COLOR_CYAN)
	b_level.pressed.connect(_on_level_select_pressed)
	btn_vbox.add_child(b_level)

	var b_bug_log := _create_menu_button("📖  Bug Log (Katalog Bug)", COLOR_AMBER)
	b_bug_log.pressed.connect(_on_bug_log_pressed)
	btn_vbox.add_child(b_bug_log)

	var b_settings := _create_menu_button("⚙️  Pengaturan Game", Color(0.85, 0.9, 0.98))
	b_settings.pressed.connect(_on_settings_pressed)
	btn_vbox.add_child(b_settings)

	var b_quit := _create_menu_button("🚪  Keluar ke Desktop", Color(0.95, 0.45, 0.45))
	b_quit.pressed.connect(_on_quit_pressed)
	btn_vbox.add_child(b_quit)

	# Footer System Info
	var footer_lbl := Label.new()
	footer_lbl.text = "v0.2.0 • Godot 4.7.2 • Python 3 Subset • Proyek Tugas Akhir PPLG"
	if _font_regular:
		footer_lbl.add_theme_font_override("font", _font_regular)
	footer_lbl.add_theme_font_size_override("font_size", 11)
	footer_lbl.add_theme_color_override("font_color", Color(0.45, 0.52, 0.62))
	left_vbox.add_spacer(false)
	left_vbox.add_child(footer_lbl)

	# Right Column: Animated Showcase Card
	var right_panel := _create_showcase_panel()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 1.0
	hbox.add_child(right_panel)

	# Build Pop-up Modals
	_build_level_select_modal()
	_build_bug_log_modal()
	_build_settings_modal()


func _create_menu_button(label_text: String, accent_color: Color) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(340, 42)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	if _font_semibold:
		btn.add_theme_font_override("font", _font_semibold)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	btn.add_theme_color_override("font_hover_color", accent_color)
	btn.add_theme_color_override("font_pressed_color", accent_color)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = COLOR_PANEL_BG
	normal_style.border_color = COLOR_BORDER
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(6)
	normal_style.content_margin_left = 18
	normal_style.content_margin_right = 14
	normal_style.content_margin_top = 8
	normal_style.content_margin_bottom = 8

	var hover_style := normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.11, 0.16, 0.24, 0.98)
	hover_style.border_color = accent_color
	hover_style.set_border_width_all(2)

	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	btn.add_theme_stylebox_override("focus", hover_style)
	return btn


func _create_showcase_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "ShowcasePanel"

	var p_style := StyleBoxFlat.new()
	p_style.bg_color = Color(0.065, 0.085, 0.125, 0.95)
	p_style.border_color = COLOR_BORDER
	p_style.set_border_width_all(2)
	p_style.set_corner_radius_all(10)
	p_style.content_margin_left = 24
	p_style.content_margin_right = 24
	p_style.content_margin_top = 20
	p_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", p_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var s_title := Label.new()
	s_title.text = "TERMINAL STATUS & PROFIL DEBUGGER"
	if _font_bold:
		s_title.add_theme_font_override("font", _font_bold)
	s_title.add_theme_font_size_override("font_size", 13)
	s_title.add_theme_color_override("font_color", COLOR_CYAN)
	vbox.add_child(s_title)

	# Centered Dex Sprite Container
	var sprite_box := CenterContainer.new()
	sprite_box.custom_minimum_size = Vector2(0, 150)
	vbox.add_child(sprite_box)

	var sprite_anchor := Control.new()
	sprite_anchor.custom_minimum_size = Vector2(64, 128)
	sprite_box.add_child(sprite_anchor)

	_dex_sprite = Sprite2D.new()
	_dex_sprite.name = "DexShowcaseSprite"
	_dex_sprite.scale = Vector2(4.0, 4.0)
	_dex_sprite.position = Vector2(32, 64)
	if not _dex_atlas_cache.is_empty():
		_dex_sprite.texture = _dex_atlas_cache[0]
	sprite_anchor.add_child(_dex_sprite)

	var info_card := PanelContainer.new()
	var ic_style := StyleBoxFlat.new()
	ic_style.bg_color = Color(0.09, 0.12, 0.18, 0.9)
	ic_style.border_color = Color(0.2, 0.3, 0.45, 0.8)
	ic_style.set_border_width_all(1)
	ic_style.set_corner_radius_all(6)
	ic_style.content_margin_left = 14
	ic_style.content_margin_right = 14
	ic_style.content_margin_top = 10
	ic_style.content_margin_bottom = 10
	info_card.add_theme_stylebox_override("panel", ic_style)
	vbox.add_child(info_card)

	var ic_vbox := VBoxContainer.new()
	ic_vbox.add_theme_constant_override("separation", 6)
	info_card.add_child(ic_vbox)

	var dex_name := Label.new()
	dex_name.text = "Unit: Dex (Cyan Antenna Bot)"
	if _font_semibold:
		dex_name.add_theme_font_override("font", _font_semibold)
	dex_name.add_theme_font_size_override("font_size", 13)
	dex_name.add_theme_color_override("font_color", COLOR_GREEN)
	ic_vbox.add_child(dex_name)

	var role_lbl := Label.new()
	role_lbl.text = "Peran: Autonomous Debugger Bot\nPemandu: Lint (Code Companion AI)\nLokasi Aktif: Dunia 1 (Syntax Shore)\nMisi: Memperbaiki 4 Terminal Keamanan"
	if _font_regular:
		role_lbl.add_theme_font_override("font", _font_regular)
	role_lbl.add_theme_font_size_override("font_size", 12)
	role_lbl.add_theme_color_override("font_color", Color(0.8, 0.86, 0.95))
	ic_vbox.add_child(role_lbl)

	var quote_lbl := Label.new()
	quote_lbl.text = "Lint: \"Setiap bug adalah petunjuk. Baca errornya, telusuri barisnya, dan perbaiki jalannya!\""
	if _font_regular:
		quote_lbl.add_theme_font_override("font", _font_regular)
	quote_lbl.add_theme_font_size_override("font_size", 11)
	quote_lbl.add_theme_color_override("font_color", COLOR_AMBER)
	quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(quote_lbl)

	return panel


func _build_level_select_modal() -> void:
	_level_select_modal = _create_base_modal("PILIH DUNIA DAN LEVEL", Vector2(740, 460))
	add_child(_level_select_modal)

	var vbox: VBoxContainer = _level_select_modal.get_node("OuterVBox/ContentScroll/VBox")

	var worlds := [
		{
			"id": 1,
			"name": "Dunia 1: Syntax Shore",
			"concept": "variabel, print, aritmetika",
			"unlocked": true,
			"status": "Level 1 Terbuka (Tersedia)",
		},
		{
			"id": 2,
			"name": "Dunia 2: Condition Canyon",
			"concept": "if / elif / else, perbandingan, logika",
			"unlocked": false,
			"status": "Terkunci (Selesaikan Bos Dunia 1)",
		},
		{
			"id": 3,
			"name": "Dunia 3: Loop Labyrinth",
			"concept": "for, while, range, perulangan",
			"unlocked": false,
			"status": "Terkunci (Selesaikan Bos Dunia 2)",
		},
		{
			"id": 4,
			"name": "Dunia 4: Function Foundry",
			"concept": "def, return, scope parameter",
			"unlocked": false,
			"status": "Terkunci (Selesaikan Bos Dunia 3)",
		},
		{
			"id": 5,
			"name": "Dunia 5: List Citadel",
			"concept": "list, indexing, struktur data",
			"unlocked": false,
			"status": "Terkunci (Selesaikan Bos Dunia 4)",
		},
	]

	for w in worlds:
		var item := PanelContainer.new()
		var is_unlocked: bool = bool(w["unlocked"])
		var i_style := StyleBoxFlat.new()
		i_style.bg_color = Color(0.1, 0.13, 0.19, 0.95) if is_unlocked else Color(0.07, 0.08, 0.11, 0.8)
		i_style.border_color = COLOR_CYAN if is_unlocked else Color(0.2, 0.25, 0.32, 0.6)
		i_style.set_border_width_all(1)
		i_style.set_corner_radius_all(6)
		i_style.content_margin_left = 14
		i_style.content_margin_right = 14
		i_style.content_margin_top = 10
		i_style.content_margin_bottom = 10
		item.add_theme_stylebox_override("panel", i_style)

		var ih := HBoxContainer.new()
		ih.add_theme_constant_override("separation", 14)
		item.add_child(ih)

		var iv := VBoxContainer.new()
		iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ih.add_child(iv)

		var w_name := Label.new()
		w_name.text = str(w["name"])
		if _font_bold:
			w_name.add_theme_font_override("font", _font_bold)
		w_name.add_theme_font_size_override("font_size", 14)
		w_name.add_theme_color_override("font_color", COLOR_GREEN if is_unlocked else Color(0.55, 0.6, 0.7))
		iv.add_child(w_name)

		var w_concept := Label.new()
		w_concept.text = "Konsep: %s | Status: %s" % [str(w["concept"]), str(w["status"])]
		w_concept.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if _font_regular:
			w_concept.add_theme_font_override("font", _font_regular)
		w_concept.add_theme_font_size_override("font_size", 12)
		w_concept.add_theme_color_override("font_color", Color(0.8, 0.85, 0.92) if is_unlocked else Color(0.48, 0.52, 0.6))
		iv.add_child(w_concept)

		if is_unlocked:
			var btn_box := HBoxContainer.new()
			btn_box.add_theme_constant_override("separation", 8)
			ih.add_child(btn_box)

			var play_btn := Button.new()
			play_btn.text = "Level 1"
			if _font_semibold:
				play_btn.add_theme_font_override("font", _font_semibold)
			play_btn.custom_minimum_size = Vector2(96, 34)
			play_btn.pressed.connect(_on_continue_pressed)
			btn_box.add_child(play_btn)

			var l2_btn := Button.new()
			l2_btn.text = "Level 2"
			if _font_semibold:
				l2_btn.add_theme_font_override("font", _font_semibold)
			l2_btn.custom_minimum_size = Vector2(96, 34)
			l2_btn.pressed.connect(func() -> void:
				get_tree().change_scene_to_file("res://scenes/levels/world_1_syntax_shore/level_2.tscn")
			)
			btn_box.add_child(l2_btn)
		else:
			var lock_lbl := Label.new()
			lock_lbl.text = "🔒 Terkunci"
			if _font_regular:
				lock_lbl.add_theme_font_override("font", _font_regular)
			lock_lbl.add_theme_font_size_override("font_size", 12)
			lock_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
			ih.add_child(lock_lbl)

		vbox.add_child(item)


func _build_bug_log_modal() -> void:
	_bug_log_modal = _create_base_modal("BUG LOG — KATALOG ENSIKLOPEDIA CODEVERSE", Vector2(760, 480))
	add_child(_bug_log_modal)

	var vbox: VBoxContainer = _bug_log_modal.get_node("OuterVBox/ContentScroll/VBox")

	var entries := [
		{
			"id": "BUG-01",
			"name": "NameError (Typo Nama Fungsi/Variabel)",
			"world": "Dunia 1: Syntax Shore (Terminal 1)",
			"sample_bad": "prin(status_laser)",
			"sample_good": "print(status_laser)",
			"desc": "Terjadi ketika Python menemukan nama fungsi atau variabel yang tidak dikenali karena kesalahan ketik. Solusi: Gunakan fungsi bawaan standar seperti print()."
		},
		{
			"id": "BUG-02",
			"name": "TypeError (Operasi String + Integer)",
			"world": "Dunia 1: Syntax Shore (Terminal 2)",
			"sample_bad": "total_daya = \"60\" + 40",
			"sample_good": "total_daya = 60 + 40",
			"desc": "Terjadi saat menggabungkan string teks bertanda kutip dengan angka bulat (int). Solusi: Hapus tanda kutip agar nilai diperlakukan sebagai angka hitung."
		},
		{
			"id": "BUG-03",
			"name": "Logical Bug (Salah Operator Aritmetika)",
			"world": "Dunia 1: Syntax Shore (Terminal 3)",
			"sample_bad": "sisa = tegangan_awal + pengurang",
			"sample_good": "sisa = tegangan_awal - pengurang",
			"desc": "Kode tidak memicu crash atau pesan error sintaks, tetapi menghasilkan kalkulasi yang salah secara fungsional. Solusi: Ubah operator '+' menjadi '-'."
		},
		{
			"id": "BUG-04",
			"name": "Logical Bug (Kesalahan Rumus Perhitungan)",
			"world": "Dunia 1: Syntax Shore (Terminal 4)",
			"sample_bad": "kunci = panjang * lebar - 10",
			"sample_good": "kunci = panjang * lebar",
			"desc": "Rumus perhitungan mengandung operasi pengurangan berlebih sehingga nilai kunci otorisasi tidak sesuai target. Solusi: Hapus '- 10'."
		},
		{
			"id": "BUG-05",
			"name": "ZeroDivisionError (Pembagian dengan Nol)",
			"world": "Dunia 1: Konsep Lanjutan",
			"sample_bad": "rata = total / 0",
			"sample_good": "rata = total / jumlah_item",
			"desc": "Angka pembagi tidak boleh bernilai nol dalam operasi matematika komputer."
		}
	]

	for e in entries:
		var card := PanelContainer.new()
		var c_style := StyleBoxFlat.new()
		c_style.bg_color = Color(0.1, 0.13, 0.19, 0.95)
		c_style.border_color = COLOR_AMBER
		c_style.set_border_width_all(1)
		c_style.set_corner_radius_all(6)
		c_style.content_margin_left = 14
		c_style.content_margin_right = 14
		c_style.content_margin_top = 10
		c_style.content_margin_bottom = 10
		card.add_theme_stylebox_override("panel", c_style)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)
		card.add_child(cv)

		var h := Label.new()
		h.text = "[%s] %s" % [str(e["id"]), str(e["name"])]
		if _font_bold:
			h.add_theme_font_override("font", _font_bold)
		h.add_theme_font_size_override("font_size", 13)
		h.add_theme_color_override("font_color", COLOR_AMBER)
		cv.add_child(h)

		var w_lbl := Label.new()
		w_lbl.text = "Lokasi: " + str(e["world"])
		if _font_semibold:
			w_lbl.add_theme_font_override("font", _font_semibold)
		w_lbl.add_theme_font_size_override("font_size", 11)
		w_lbl.add_theme_color_override("font_color", COLOR_CYAN)
		cv.add_child(w_lbl)

		var code_lbl := Label.new()
		code_lbl.text = "Salah : %s\nBenar : %s" % [str(e["sample_bad"]), str(e["sample_good"])]
		if _font_regular:
			code_lbl.add_theme_font_override("font", _font_regular)
		code_lbl.add_theme_font_size_override("font_size", 12)
		code_lbl.add_theme_color_override("font_color", COLOR_GREEN)
		cv.add_child(code_lbl)

		var d_lbl := Label.new()
		d_lbl.text = "Penjelasan: " + str(e["desc"])
		if _font_regular:
			d_lbl.add_theme_font_override("font", _font_regular)
		d_lbl.add_theme_font_size_override("font_size", 11)
		d_lbl.add_theme_color_override("font_color", Color(0.82, 0.88, 0.95))
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(d_lbl)

		vbox.add_child(card)


func _build_settings_modal() -> void:
	_settings_modal = _create_base_modal("PENGATURAN GAME & KONTROL", Vector2(740, 480))
	add_child(_settings_modal)

	var vbox: VBoxContainer = _settings_modal.get_node("OuterVBox/ContentScroll/VBox")

	# Section 1: Audio
	var a_header := Label.new()
	a_header.text = "🔊 AUDIO & SUARA"
	if _font_bold:
		a_header.add_theme_font_override("font", _font_bold)
	a_header.add_theme_font_size_override("font_size", 14)
	a_header.add_theme_color_override("font_color", COLOR_CYAN)
	vbox.add_child(a_header)

	var a_panel := _create_sub_box()
	vbox.add_child(a_panel)
	var a_vbox := VBoxContainer.new()
	a_vbox.add_theme_constant_override("separation", 8)
	a_panel.add_child(a_vbox)

	a_vbox.add_child(_create_slider_row("Master Volume", 80))
	a_vbox.add_child(_create_slider_row("Musik Latar (BGM)", 75))
	a_vbox.add_child(_create_slider_row("Efek Suara (SFX)", 85))

	# Section 2: Display
	var d_header := Label.new()
	d_header.text = "🖥️ TAMPILAN & LAYAR"
	if _font_bold:
		d_header.add_theme_font_override("font", _font_bold)
	d_header.add_theme_font_size_override("font_size", 14)
	d_header.add_theme_color_override("font_color", COLOR_GREEN)
	vbox.add_child(d_header)

	var d_panel := _create_sub_box()
	vbox.add_child(d_panel)
	var d_hbox := HBoxContainer.new()
	d_panel.add_child(d_hbox)

	var fs_check := CheckButton.new()
	fs_check.text = "Layar Penuh (Fullscreen Mode)"
	if _font_semibold:
		fs_check.add_theme_font_override("font", _font_semibold)
	fs_check.add_theme_font_size_override("font_size", 12)
	fs_check.toggled.connect(func(toggled_on: bool) -> void:
		if toggled_on:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	d_hbox.add_child(fs_check)

	# Section 3: Cheatsheet Kontrol
	var c_header := Label.new()
	c_header.text = "🎮 PANDUAN KONTROL KEYBOARD"
	if _font_bold:
		c_header.add_theme_font_override("font", _font_bold)
	c_header.add_theme_font_size_override("font_size", 14)
	c_header.add_theme_color_override("font_color", COLOR_AMBER)
	vbox.add_child(c_header)

	var c_panel := _create_sub_box()
	vbox.add_child(c_panel)
	var c_lbl := Label.new()
	c_lbl.text = "• [A / D] atau [Panah] : Berjalan ke Kiri / Kanan\n• [Spasi]             : Melompat\n• [E]                 : Buka / Interaksi Terminal Kode\n• [Tab]               : Beralih Kamera (Overview Full Map vs Zoom Dex)\n• [L]                 : Buka / Tutup Jurnal Bug Log\n• [Ctrl + Enter]      : Jalankan Kode (Run) di Terminal\n• [Ctrl + R]          : Reset Kode ke template awal\n• [F1]                : Bantuan Petunjuk Bertahap (Hint 1..3)\n• [Esc]               : Tutup Terminal / Jendela Modal"
	if _font_regular:
		c_lbl.add_theme_font_override("font", _font_regular)
	c_lbl.add_theme_font_size_override("font_size", 12)
	c_lbl.add_theme_color_override("font_color", Color(0.85, 0.9, 0.96))
	c_panel.add_child(c_lbl)


func _create_slider_row(label_text: String, default_val: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(160, 0)
	if _font_regular:
		lbl.add_theme_font_override("font", _font_regular)
	lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = default_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(240, 24)
	row.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.text = "%d%%" % default_val
	val_lbl.custom_minimum_size = Vector2(48, 0)
	if _font_regular:
		val_lbl.add_theme_font_override("font", _font_regular)
	val_lbl.add_theme_font_size_override("font_size", 12)
	row.add_child(val_lbl)

	slider.value_changed.connect(func(v: float) -> void:
		val_lbl.text = "%d%%" % int(v)
		# Update master audio bus volume if bus exists
		if AudioServer.get_bus_count() > 0:
			var db := linear_to_db(v / 100.0) if v > 0.0 else -80.0
			AudioServer.set_bus_volume_db(0, db)
	)

	return row


func _create_sub_box() -> PanelContainer:
	var pc := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.15, 0.9)
	style.border_color = COLOR_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	pc.add_theme_stylebox_override("panel", style)
	return pc


func _create_base_modal(title_text: String, size_vec: Vector2) -> PanelContainer:
	var modal := PanelContainer.new()
	modal.visible = false
	modal.set_anchors_preset(Control.PRESET_CENTER)
	modal.custom_minimum_size = size_vec
	modal.offset_left = -size_vec.x * 0.5
	modal.offset_top = -size_vec.y * 0.5
	modal.offset_right = size_vec.x * 0.5
	modal.offset_bottom = size_vec.y * 0.5

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.085, 0.13, 0.98)
	style.border_color = COLOR_CYAN
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	modal.add_theme_stylebox_override("panel", style)

	var outer := VBoxContainer.new()
	outer.name = "OuterVBox"
	outer.add_theme_constant_override("separation", 10)
	modal.add_child(outer)

	var h_bar := HBoxContainer.new()
	outer.add_child(h_bar)

	var t_lbl := Label.new()
	t_lbl.text = title_text
	t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _font_bold:
		t_lbl.add_theme_font_override("font", _font_bold)
	t_lbl.add_theme_font_size_override("font_size", 16)
	t_lbl.add_theme_color_override("font_color", COLOR_CYAN)
	h_bar.add_child(t_lbl)

	var c_btn := Button.new()
	c_btn.text = "✕ Tutup [Esc]"
	if _font_semibold:
		c_btn.add_theme_font_override("font", _font_semibold)
	c_btn.pressed.connect(func() -> void: modal.visible = false)
	h_bar.add_child(c_btn)

	var scroll := ScrollContainer.new()
	scroll.name = "ContentScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(scroll)

	var content_vbox := VBoxContainer.new()
	content_vbox.name = "VBox"
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(content_vbox)

	return modal


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		# Close active modal if open
		if _level_select_modal and _level_select_modal.visible:
			_level_select_modal.visible = false
			get_viewport().set_input_as_handled()
		elif _bug_log_modal and _bug_log_modal.visible:
			_bug_log_modal.visible = false
			get_viewport().set_input_as_handled()
		elif _settings_modal and _settings_modal.visible:
			_settings_modal.visible = false
			get_viewport().set_input_as_handled()


func _on_continue_pressed() -> void:
	if ResourceLoader.exists(LEVEL_1_PATH):
		get_tree().change_scene_to_file(LEVEL_1_PATH)


func _on_level_select_pressed() -> void:
	_close_all_modals()
	if _level_select_modal:
		_level_select_modal.visible = true


func _on_bug_log_pressed() -> void:
	_close_all_modals()
	if _bug_log_modal:
		_bug_log_modal.visible = true


func _on_settings_pressed() -> void:
	_close_all_modals()
	if _settings_modal:
		_settings_modal.visible = true


func _on_quit_pressed() -> void:
	get_tree().quit()


func _close_all_modals() -> void:
	if _level_select_modal:
		_level_select_modal.visible = false
	if _bug_log_modal:
		_bug_log_modal.visible = false
	if _settings_modal:
		_settings_modal.visible = false
