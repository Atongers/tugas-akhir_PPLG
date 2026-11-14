extends Control
class_name MainMenu

const FONT_BOLD_PATH := "res://assets/fonts/ttf/JetBrainsMono-Bold.ttf"
const FONT_SEMIBOLD_PATH := "res://assets/fonts/ttf/JetBrainsMono-SemiBold.ttf"
const FONT_REGULAR_PATH := "res://assets/fonts/ttf/JetBrainsMono-Regular.ttf"
const SPRITESHEET_PATH := "res://assets/sprites/characters/characters.png"
const LINT_SHEET_PATH := "res://assets/sprites/characters/lint_companion_sheet.png"
const TILESET_PNG_PATH := "res://assets/tilesets/tileset.png"
const PROPS_SHEET_PATH := "res://assets/sprites/environment/sector_props_sheet.png"
const WIRING_SHEET_PATH := "res://assets/sprites/environment/wiring_cables_sheet.png"
const TURRET_BASE_PATH := "res://assets/sprites/objects/turret_tripod_base.png"
const UI_STATUS_ICONS_PATH := "res://assets/ui/ui_status_icons_sheet.png"
const UI_DEBUG_TOOLS_PATH := "res://assets/ui/ui_debug_tools_sheet.png"
const UI_WORLD_BADGES_PATH := "res://assets/ui/ui_world_badges_sheet.png"
const SKIN_PORTRAITS_PATH := "res://assets/ui/skins/dex_skin_portraits.png"
const SKIN_BADGES_PATH := "res://assets/ui/skins/dex_skin_badges.png"
const DEFAULT_DEX_SKIN_PATH := "res://assets/sprites/characters/dex_skin_default.png"
const LEVEL_1_PATH := "res://scenes/levels/world_1_syntax_shore/level_1.tscn"

const COLOR_BG_DEEP := Color(0.028, 0.04, 0.072, 1.0)
const COLOR_PANEL_BG := Color(0.065, 0.09, 0.145, 0.94)
const COLOR_CYAN := Color(0.133, 0.827, 0.933, 1.0) # #22d3ee
const COLOR_GREEN := Color(0.133, 0.773, 0.369, 1.0) # #22c55e
const COLOR_AMBER := Color(0.961, 0.62, 0.043, 1.0) # #f59e0b
const COLOR_SLATE_TEXT := Color(0.58, 0.639, 0.722, 1.0) # #94a3b8
const COLOR_BORDER := Color(0.18, 0.28, 0.42, 0.85)
const COLOR_BORDER_HOVER := Color(0.22, 0.74, 0.97, 1.0)

var _font_bold: FontFile = null
var _font_semibold: FontFile = null
var _font_regular: FontFile = null

# Modals & Screen Stack
var _modal_dimmer: ColorRect = null
var _level_select_modal: PanelContainer = null
var _bug_log_modal: PanelContainer = null
var _settings_modal: PanelContainer = null
var _last_focused_button: Control = null

# 4-Layer Parallax Diorama
var _layer_far: Control = null
var _layer_mid: Control = null
var _layer_hero: Control = null
var _layer_fg: Control = null
var _parallax_cur: Vector2 = Vector2.ZERO

# Animated Hero Diorama (Dex, Lint, Terminal, Dust Motes)
var _dex_sprite: Sprite2D = null
var _dex_atlas_cache: Array[AtlasTexture] = []
var _lint_sprite: Sprite2D = null
var _lint_atlas_cache: Array[AtlasTexture] = []
var _lint_base_y: float = 0.0
var _terminal_glow_lines: Array[ColorRect] = []
var _dust_motes: Array[Dictionary] = []

# Sleek Pixel-Tech Menu Buttons & Skin Selector
var _menu_buttons: Array[Dictionary] = []
var _skin_cards_box: HBoxContainer = null


const SETTINGS_PATH := "user://settings.cfg"

var _user_settings: Dictionary = {
	"master_vol": 80,
	"bgm_vol": 75,
	"sfx_vol": 85,
	"fullscreen": false,
}


func _ready() -> void:
	_ensure_audio_buses()
	_load_user_settings()
	_load_fonts()
	_load_diorama_assets()
	_build_ui()
	_close_all_modals()
	if has_node("/root/SaveManager"):
		var sm := get_node("/root/SaveManager")
		if sm.has_signal("skin_changed") and not sm.skin_changed.is_connected(_on_save_skin_changed):
			sm.skin_changed.connect(_on_save_skin_changed)
		if sm.has_signal("progression_updated") and not sm.progression_updated.is_connected(_on_progression_updated):
			sm.progression_updated.connect(_on_progression_updated)
	if not _menu_buttons.is_empty():
		var first_btn: Button = _menu_buttons[0]["button"]
		first_btn.call_deferred("grab_focus")


func _process(delta: float) -> void:
	var t_sec: float = Time.get_ticks_msec() / 1000.0

	# 1. Smooth 4-layer parallax (cursor + gentle idle camera sway)
	var vp_size := get_viewport_rect().size
	var mouse_norm := Vector2.ZERO
	if vp_size.x > 0.0 and vp_size.y > 0.0:
		var mpos := get_viewport().get_mouse_position()
		mouse_norm = Vector2((mpos.x / vp_size.x - 0.5) * 2.0, (mpos.y / vp_size.y - 0.5) * 2.0).clamp(Vector2(-1, -1), Vector2(1, 1))
	var idle_sway := Vector2(sin(t_sec * 0.45) * 0.18, cos(t_sec * 0.35) * 0.12)
	var target := mouse_norm + idle_sway
	_parallax_cur = _parallax_cur.lerp(target, clampf(delta * 4.5, 0.0, 1.0))

	if is_instance_valid(_layer_far):
		_layer_far.position = Vector2(_parallax_cur.x * -3.0, _parallax_cur.y * -1.5)
	if is_instance_valid(_layer_mid):
		_layer_mid.position = Vector2(_parallax_cur.x * -9.0, _parallax_cur.y * -4.0)
	if is_instance_valid(_layer_hero):
		_layer_hero.position = Vector2(_parallax_cur.x * -17.0, _parallax_cur.y * -7.0)
	if is_instance_valid(_layer_fg):
		_layer_fg.position = Vector2(_parallax_cur.x * -28.0, _parallax_cur.y * -11.0)

	# 2. Animate Dex idle at ~6.6 FPS
	if is_instance_valid(_dex_sprite) and not _dex_atlas_cache.is_empty():
		var frame_idx: int = int(Time.get_ticks_msec() / 150.0) % _dex_atlas_cache.size()
		_dex_sprite.texture = _dex_atlas_cache[frame_idx]

	# 3. Animate Lint hover & blink
	if is_instance_valid(_lint_sprite) and not _lint_atlas_cache.is_empty():
		_lint_sprite.position.y = _lint_base_y + sin(t_sec * 2.6) * 7.0
		var lint_cycle: int = int(t_sec * 2.0) % 10
		# Mostly friendly cyan (frame 0) with occasional happy green blink (frame 2)
		var lint_idx: int = 2 if lint_cycle == 8 else 0
		_lint_sprite.texture = _lint_atlas_cache[lint_idx]

	# 4. Pulse CodeTerminal screen lines
	for i in range(_terminal_glow_lines.size()):
		var line_rect := _terminal_glow_lines[i]
		if is_instance_valid(line_rect):
			line_rect.modulate.a = 0.55 + 0.45 * sin(t_sec * 2.8 + float(i) * 1.1)

	# 5. Float dust motes inside light shaft
	for mote in _dust_motes:
		var node: ColorRect = mote["node"]
		if not is_instance_valid(node):
			continue
		var phase: float = float(mote["phase"])
		var speed: float = float(mote["speed"])
		var base_pos: Vector2 = mote["base_pos"]
		node.position = base_pos + Vector2(sin(t_sec * speed + phase) * 10.0, cos(t_sec * speed * 0.7 + phase) * 14.0)
		node.modulate.a = 0.2 + 0.35 * (0.5 + 0.5 * sin(t_sec * 1.8 + phase))

	# 6. Pulse left strip on focused menu button (keyboard/gamepad distinctness)
	for entry in _menu_buttons:
		var btn: Button = entry["button"]
		var strip: ColorRect = entry["strip"]
		if is_instance_valid(btn) and is_instance_valid(strip):
			if btn.has_focus():
				strip.modulate.a = 0.72 + 0.28 * sin(t_sec * 5.0)
			elif btn.is_hovered():
				strip.modulate.a = 1.0


func _load_fonts() -> void:
	if ResourceLoader.exists(FONT_BOLD_PATH):
		_font_bold = load(FONT_BOLD_PATH)
	if ResourceLoader.exists(FONT_SEMIBOLD_PATH):
		_font_semibold = load(FONT_SEMIBOLD_PATH)
	if ResourceLoader.exists(FONT_REGULAR_PATH):
		_font_regular = load(FONT_REGULAR_PATH)


func _load_diorama_assets() -> void:
	_reload_dex_skin_frames()

	if ResourceLoader.exists(LINT_SHEET_PATH):
		var lint_tex: Texture2D = load(LINT_SHEET_PATH)
		if lint_tex:
			for col in range(4):
				var at := AtlasTexture.new()
				at.atlas = lint_tex
				at.region = Rect2(col * 16, 0, 16, 16)
				at.filter_clip = true
				_lint_atlas_cache.append(at)


func _reload_dex_skin_frames() -> void:
	_dex_atlas_cache.clear()
	var sheet_path := DEFAULT_DEX_SKIN_PATH
	if has_node("/root/SaveManager"):
		var sm := get_node("/root/SaveManager")
		var meta: Dictionary = sm.call("get_skin_metadata", sm.get("active_skin"))
		sheet_path = str(meta.get("sheet_path", DEFAULT_DEX_SKIN_PATH))
	if not ResourceLoader.exists(sheet_path):
		sheet_path = DEFAULT_DEX_SKIN_PATH
	if not ResourceLoader.exists(sheet_path):
		return
	var dex_tex: Texture2D = load(sheet_path)
	if not dex_tex:
		return
	# 256x192 (32x32 cells), Row 0 Col 0..3 = idle
	for col in range(4):
		var at := AtlasTexture.new()
		at.atlas = dex_tex
		at.region = Rect2(col * 32, 0, 32, 32)
		at.filter_clip = true
		_dex_atlas_cache.append(at)


func _on_save_skin_changed(_skin_id: String) -> void:
	_reload_dex_skin_frames()
	_rebuild_skin_selector_cards()


func _on_progression_updated() -> void:
	_reload_dex_skin_frames()
	_rebuild_skin_selector_cards()
	_refresh_modals_after_progression()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	# 1. Base Dark Slate Background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = COLOR_BG_DEEP
	add_child(bg)

	# 2. 4-Layer Parallax Diorama ("Dormant Debugger Bay")
	_build_diorama_layers()

	# 3. Left-Aligned UI Layer with Safe Area Margins (48px)
	var main_margin := MarginContainer.new()
	main_margin.name = "MainMargin"
	main_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_margin.add_theme_constant_override("margin_left", 56)
	main_margin.add_theme_constant_override("margin_right", 56)
	main_margin.add_theme_constant_override("margin_top", 48)
	main_margin.add_theme_constant_override("margin_bottom", 44)
	add_child(main_margin)

	var root_vbox := VBoxContainer.new()
	root_vbox.name = "UIRootVBox"
	root_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_margin.add_child(root_vbox)

	# Top Left: Brand Logo (CODEVERSE: [ >_ DEBUGGER ])
	var brand_box := VBoxContainer.new()
	brand_box.name = "BrandHeader"
	brand_box.add_theme_constant_override("separation", 4)
	root_vbox.add_child(brand_box)

	var logo_row := HBoxContainer.new()
	logo_row.add_theme_constant_override("separation", 10)
	brand_box.add_child(logo_row)

	var title_lbl := Label.new()
	title_lbl.name = "TitleLabel"
	title_lbl.text = "CODEVERSE:"
	if _font_bold:
		title_lbl.add_theme_font_override("font", _font_bold)
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.add_theme_color_override("font_color", Color(0.886, 0.91, 0.941))
	logo_row.add_child(title_lbl)

	var badge_panel := PanelContainer.new()
	var badge_sb := StyleBoxFlat.new()
	badge_sb.bg_color = Color(0.024, 0.714, 0.831, 0.18)
	badge_sb.border_color = Color(0.024, 0.714, 0.831, 0.65)
	badge_sb.set_border_width_all(1)
	badge_sb.set_corner_radius_all(3)
	badge_sb.content_margin_left = 10
	badge_sb.content_margin_right = 10
	badge_sb.content_margin_top = 4
	badge_sb.content_margin_bottom = 4
	badge_panel.add_theme_stylebox_override("panel", badge_sb)
	badge_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	logo_row.add_child(badge_panel)

	var badge_lbl := Label.new()
	badge_lbl.text = ">_ DEBUGGER"
	if _font_bold:
		badge_lbl.add_theme_font_override("font", _font_bold)
	badge_lbl.add_theme_font_size_override("font_size", 18)
	badge_lbl.add_theme_color_override("font_color", COLOR_CYAN)
	badge_panel.add_child(badge_lbl)

	var subtitle_lbl := Label.new()
	subtitle_lbl.name = "SubtitleLabel"
	subtitle_lbl.text = "DEX & LINT • PYTHON PUZZLE-PLATFORMER"
	if _font_semibold:
		subtitle_lbl.add_theme_font_override("font", _font_semibold)
	subtitle_lbl.add_theme_font_size_override("font_size", 12)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.29, 0.871, 0.502))
	brand_box.add_child(subtitle_lbl)

	# Middle Left: Sleek Pixel-Tech Menu List (vertically centered)
	var mid_spacer_top := Control.new()
	mid_spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(mid_spacer_top)

	var btn_vbox := VBoxContainer.new()
	btn_vbox.name = "ButtonList"
	btn_vbox.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn_vbox.add_theme_constant_override("separation", 6)
	root_vbox.add_child(btn_vbox)

	var icon_play := _make_sheet_icon(UI_STATUS_ICONS_PATH, 1, 4)
	var icon_world := _make_sheet_icon(UI_WORLD_BADGES_PATH, 0, 6)
	var icon_bug := _make_sheet_icon(UI_STATUS_ICONS_PATH, 2, 4)
	var icon_settings := _make_sheet_icon(UI_DEBUG_TOOLS_PATH, 0, 8)
	var icon_quit := _make_sheet_icon(UI_STATUS_ICONS_PATH, 0, 4)

	var b_play := _create_menu_button("LANJUT PETUALANGAN (Lv. 1)", COLOR_GREEN, icon_play)
	b_play.pressed.connect(_on_continue_pressed)
	btn_vbox.add_child(b_play)

	var b_level := _create_menu_button("PILIH DUNIA & LEVEL", COLOR_CYAN, icon_world)
	b_level.pressed.connect(_on_level_select_pressed)
	btn_vbox.add_child(b_level)

	var b_bug_log := _create_menu_button("BUG LOG", COLOR_AMBER, icon_bug)
	b_bug_log.pressed.connect(_on_bug_log_pressed)
	btn_vbox.add_child(b_bug_log)

	var b_settings := _create_menu_button("PENGATURAN", Color(0.796, 0.835, 0.882), icon_settings)
	b_settings.pressed.connect(_on_settings_pressed)
	btn_vbox.add_child(b_settings)

	var b_quit := _create_menu_button("KELUAR", Color(0.973, 0.443, 0.443), icon_quit)
	b_quit.pressed.connect(_on_quit_pressed)
	btn_vbox.add_child(b_quit)

	# Keyboard / Gamepad focus loop
	var btn_count := _menu_buttons.size()
	for i in range(btn_count):
		var cur_btn: Button = _menu_buttons[i]["button"]
		var prev_btn: Button = _menu_buttons[(i - 1 + btn_count) % btn_count]["button"]
		var next_btn: Button = _menu_buttons[(i + 1) % btn_count]["button"]
		cur_btn.focus_neighbor_top = prev_btn.get_path()
		cur_btn.focus_neighbor_bottom = next_btn.get_path()

	var mid_spacer_bot := Control.new()
	mid_spacer_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(mid_spacer_bot)

	# Bottom Bar: Version + Control Hint
	var footer_row := HBoxContainer.new()
	footer_row.name = "FooterRow"
	root_vbox.add_child(footer_row)

	var ver_lbl := Label.new()
	ver_lbl.text = "BUILD v1.0 • SYNTAX SHORE"
	ver_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _font_regular:
		ver_lbl.add_theme_font_override("font", _font_regular)
	ver_lbl.add_theme_font_size_override("font_size", 11)
	ver_lbl.add_theme_color_override("font_color", Color(0.392, 0.455, 0.545))
	footer_row.add_child(ver_lbl)

	var hint_lbl := Label.new()
	hint_lbl.text = "↑↓ PILIH  |  ENTER BUKA  |  ESC TUTUP"
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if _font_regular:
		hint_lbl.add_theme_font_override("font", _font_regular)
	hint_lbl.add_theme_font_size_override("font_size", 11)
	hint_lbl.add_theme_color_override("font_color", Color(0.492, 0.555, 0.645))
	footer_row.add_child(hint_lbl)

	# 3.5 Interactive Skin Selector Bar (Bottom-Right Diorama)
	_build_skin_selector_overlay()

	# 4. Modal Dimmer Overlay
	_modal_dimmer = ColorRect.new()
	_modal_dimmer.name = "ModalDimmer"
	_modal_dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_dimmer.color = Color(0.015, 0.025, 0.05, 0.74)
	_modal_dimmer.visible = false
	add_child(_modal_dimmer)

	# 5. Build Pop-up Modals
	_build_level_select_modal()
	_build_bug_log_modal()
	_build_settings_modal()


func _make_sheet_icon(sheet_path: String, col_idx: int, total_cols: int) -> AtlasTexture:
	if not ResourceLoader.exists(sheet_path):
		return null
	var tex: Texture2D = load(sheet_path)
	if not tex:
		return null
	var frame_w := int(tex.get_width() / maxi(1, total_cols))
	var at := AtlasTexture.new()
	at.atlas = tex
	at.region = Rect2(col_idx * frame_w, 0, frame_w, tex.get_height())
	at.filter_clip = true
	return at


func _create_menu_button(label_text: String, accent_color: Color, icon_tex: Texture2D) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(330, 38)
	btn.flat = true
	btn.focus_mode = Control.FOCUS_ALL

	var empty_sb := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty_sb)
	btn.add_theme_stylebox_override("hover", empty_sb)
	btn.add_theme_stylebox_override("pressed", empty_sb)
	btn.add_theme_stylebox_override("focus", empty_sb)

	# Gradient bar (visible when active/hovered/focused)
	var active_bg := ColorRect.new()
	active_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	active_bg.color = Color(accent_color.r, accent_color.g, accent_color.b, 0.14)
	active_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	active_bg.visible = false
	btn.add_child(active_bg)

	# 3px Left neon indicator strip
	var strip := ColorRect.new()
	strip.anchor_left = 0.0
	strip.anchor_top = 0.0
	strip.anchor_bottom = 1.0
	strip.offset_left = 0.0
	strip.offset_right = 3.0
	strip.color = accent_color
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.visible = false
	btn.add_child(strip)

	# Content row that slides +6px right on hover/focus
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12.0
	row.offset_right = -10.0
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)

	var marker_lbl := Label.new()
	marker_lbl.text = ">"
	marker_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _font_bold:
		marker_lbl.add_theme_font_override("font", _font_bold)
	marker_lbl.add_theme_font_size_override("font_size", 14)
	marker_lbl.add_theme_color_override("font_color", accent_color)
	marker_lbl.modulate.a = 0.25
	marker_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(marker_lbl)

	var icon_rect: TextureRect = null
	if icon_tex:
		icon_rect = TextureRect.new()
		icon_rect.texture = icon_tex
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.custom_minimum_size = Vector2(16, 16)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon_rect.modulate = Color(0.65, 0.72, 0.82, 0.65)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_rect)

	var text_lbl := Label.new()
	text_lbl.text = label_text
	text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _font_semibold:
		text_lbl.add_theme_font_override("font", _font_semibold)
	text_lbl.add_theme_font_size_override("font_size", 14)
	text_lbl.add_theme_color_override("font_color", COLOR_SLATE_TEXT)
	text_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_lbl)

	var entry := {
		"button": btn,
		"bg": active_bg,
		"strip": strip,
		"row": row,
		"marker": marker_lbl,
		"icon": icon_rect,
		"label": text_lbl,
		"accent": accent_color,
	}
	_menu_buttons.append(entry)

	var update_visual := func() -> void:
		var active: bool = btn.has_focus() or btn.is_hovered()
		active_bg.visible = active
		strip.visible = active
		marker_lbl.modulate.a = 1.0 if active else 0.25
		text_lbl.add_theme_color_override("font_color", Color(0.973, 0.98, 0.988) if active else COLOR_SLATE_TEXT)
		if icon_rect:
			icon_rect.modulate = Color(1.0, 1.0, 1.0, 1.0) if active else Color(0.65, 0.72, 0.82, 0.65)
		var tw := create_tween()
		tw.tween_property(row, "offset_left", 18.0 if active else 12.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	btn.mouse_entered.connect(func() -> void:
		btn.grab_focus()
		update_visual.call()
	)
	btn.mouse_exited.connect(update_visual)
	btn.focus_entered.connect(update_visual)
	btn.focus_exited.connect(update_visual)

	return btn


func _build_diorama_layers() -> void:
	# Layer 0: Far Facility Background (0.05x parallax)
	_layer_far = Control.new()
	_layer_far.name = "Layer0_FarBackground"
	_layer_far.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer_far.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_layer_far)

	# Atmospheric radial-like facility glow on the right
	var glow_bg := ColorRect.new()
	glow_bg.anchor_left = 0.38
	glow_bg.anchor_top = 0.0
	glow_bg.anchor_right = 1.0
	glow_bg.anchor_bottom = 1.0
	glow_bg.color = Color(0.065, 0.11, 0.20, 0.55)
	glow_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer_far.add_child(glow_bg)

	# Far server rack silhouettes
	for rack_cfg in [
		{"l": 0.56, "r": 0.68, "t": 0.16, "b": 0.78},
		{"l": 0.72, "r": 0.90, "t": 0.10, "b": 0.78},
	]:
		var rack := ColorRect.new()
		rack.anchor_left = float(rack_cfg["l"])
		rack.anchor_right = float(rack_cfg["r"])
		rack.anchor_top = float(rack_cfg["t"])
		rack.anchor_bottom = float(rack_cfg["b"])
		rack.color = Color(0.043, 0.065, 0.115, 0.88)
		rack.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layer_far.add_child(rack)

		var rack_trim := ColorRect.new()
		rack_trim.anchor_left = 0.0
		rack_trim.anchor_right = 0.0
		rack_trim.offset_right = 2.0
		rack_trim.anchor_top = 0.0
		rack_trim.anchor_bottom = 1.0
		rack_trim.color = Color(0.09, 0.145, 0.24, 0.65)
		rack_trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rack.add_child(rack_trim)

	# Layer 1: Midground Facility & Platform (0.15x parallax)
	_layer_mid = Control.new()
	_layer_mid.name = "Layer1_MidgroundFacility"
	_layer_mid.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer_mid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_layer_mid)

	# Volumetric Light Shaft Polygon (anchored right)
	var shaft_anchor := Control.new()
	shaft_anchor.anchor_left = 1.0
	shaft_anchor.anchor_right = 1.0
	shaft_anchor.anchor_top = 0.0
	shaft_anchor.anchor_bottom = 1.0
	shaft_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer_mid.add_child(shaft_anchor)

	var shaft := Polygon2D.new()
	shaft.polygon = PackedVector2Array([
		Vector2(-390, -20), Vector2(-240, -20),
		Vector2(-100, 560), Vector2(-510, 560)
	])
	shaft.vertex_colors = PackedColorArray([
		Color(0.22, 0.74, 0.97, 0.16),
		Color(0.22, 0.74, 0.97, 0.14),
		Color(0.13, 0.77, 0.37, 0.01),
		Color(0.13, 0.77, 0.37, 0.02),
	])
	shaft_anchor.add_child(shaft)

	# Dust motes inside the light shaft
	for i in range(10):
		var mote := ColorRect.new()
		mote.size = Vector2(3, 3) if (i % 2 == 0) else Vector2(2, 2)
		mote.color = Color(0.55, 0.9, 1.0, 0.55)
		var base_p := Vector2(-430.0 + float((i * 37) % 260), 70.0 + float((i * 53) % 360))
		mote.position = base_p
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shaft_anchor.add_child(mote)
		_dust_motes.append({"node": mote, "base_pos": base_p, "phase": float(i) * 0.9, "speed": 0.65 + float(i % 3) * 0.25})

	# Right-side Chamber Deck Floor (bottom 27%)
	var floor_deck := ColorRect.new()
	floor_deck.anchor_left = 0.38
	floor_deck.anchor_right = 1.05
	floor_deck.anchor_top = 0.73
	floor_deck.anchor_bottom = 1.08
	floor_deck.color = Color(0.067, 0.094, 0.153, 1.0)
	floor_deck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer_mid.add_child(floor_deck)

	var floor_trim := ColorRect.new()
	floor_trim.anchor_left = 0.0
	floor_trim.anchor_right = 1.0
	floor_trim.anchor_top = 0.0
	floor_trim.offset_bottom = 3.0
	floor_trim.color = Color(0.145, 0.21, 0.32, 1.0)
	floor_trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor_deck.add_child(floor_trim)

	# Dormant Turret Silhouette on far right of deck
	if ResourceLoader.exists(TURRET_BASE_PATH):
		var turret_sp := Sprite2D.new()
		turret_sp.texture = load(TURRET_BASE_PATH)
		turret_sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		turret_sp.scale = Vector2(3.0, 3.0)
		turret_sp.modulate = Color(0.35, 0.42, 0.55, 0.55)
		turret_sp.position = Vector2(-115, -26)
		var deck_right_anchor := Control.new()
		deck_right_anchor.anchor_left = 1.0
		deck_right_anchor.anchor_right = 1.0
		deck_right_anchor.anchor_top = 0.73
		deck_right_anchor.anchor_bottom = 0.73
		deck_right_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_layer_mid.add_child(deck_right_anchor)
		deck_right_anchor.add_child(turret_sp)

	# Layer 2: Hero Diorama — Alive Dex, Lint & CodeTerminal (0.30x parallax)
	_layer_hero = Control.new()
	_layer_hero.name = "Layer2_HeroDiorama"
	_layer_hero.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_layer_hero)

	var hero_anchor := Control.new()
	hero_anchor.anchor_left = 0.76
	hero_anchor.anchor_right = 0.76
	hero_anchor.anchor_top = 0.73
	hero_anchor.anchor_bottom = 0.73
	hero_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer_hero.add_child(hero_anchor)

	# CodeTerminal Diorama (right of Dex)
	var term_box := ColorRect.new()
	term_box.position = Vector2(18, -76)
	term_box.size = Vector2(54, 72)
	term_box.color = Color(0.118, 0.161, 0.231, 1.0)
	term_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_anchor.add_child(term_box)

	var term_base := ColorRect.new()
	term_base.position = Vector2(12, -8)
	term_base.size = Vector2(66, 8)
	term_base.color = Color(0.20, 0.255, 0.333, 1.0)
	term_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_anchor.add_child(term_base)

	var term_screen := ColorRect.new()
	term_screen.position = Vector2(8, 10)
	term_screen.size = Vector2(38, 32)
	term_screen.color = Color(0.016, 0.184, 0.18, 1.0)
	term_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	term_box.add_child(term_screen)

	_terminal_glow_lines.clear()
	for li in range(3):
		var gl := ColorRect.new()
		gl.position = Vector2(5, 6 + li * 8)
		gl.size = Vector2(24 - (li % 2) * 8, 3)
		gl.color = COLOR_GREEN if (li % 2 == 0) else COLOR_CYAN
		gl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		term_screen.add_child(gl)
		_terminal_glow_lines.append(gl)

	# Dex Idle Sprite
	_dex_sprite = Sprite2D.new()
	_dex_sprite.name = "DexDioramaSprite"
	_dex_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dex_sprite.scale = Vector2(4.0, 4.0)
	_dex_sprite.position = Vector2(-56, -64)
	if not _dex_atlas_cache.is_empty():
		_dex_sprite.texture = _dex_atlas_cache[0]
	hero_anchor.add_child(_dex_sprite)

	# Lint Companion Drone Hovering above Dex & Terminal
	_lint_sprite = Sprite2D.new()
	_lint_sprite.name = "LintDioramaSprite"
	_lint_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_lint_sprite.scale = Vector2(3.0, 3.0)
	_lint_base_y = -132.0
	_lint_sprite.position = Vector2(-12, _lint_base_y)
	if not _lint_atlas_cache.is_empty():
		_lint_sprite.texture = _lint_atlas_cache[0]
	hero_anchor.add_child(_lint_sprite)

	# Layer 3: Foreground Framing Cables (0.55x parallax, bleed edges)
	_layer_fg = Control.new()
	_layer_fg.name = "Layer3_ForegroundFraming"
	_layer_fg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer_fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_layer_fg)

	# Top-left hanging cable silhouettes
	var tl_cable_1 := Line2D.new()
	tl_cable_1.points = PackedVector2Array([Vector2(-20, 18), Vector2(38, 92), Vector2(18, 195)])
	tl_cable_1.width = 7.0
	tl_cable_1.default_color = Color(0.02, 0.027, 0.047, 0.92)
	_layer_fg.add_child(tl_cable_1)

	var tl_cable_2 := Line2D.new()
	tl_cable_2.points = PackedVector2Array([Vector2(32, -16), Vector2(88, 65), Vector2(72, 145)])
	tl_cable_2.width = 4.5
	tl_cable_2.default_color = Color(0.028, 0.038, 0.065, 0.88)
	_layer_fg.add_child(tl_cable_2)

	# Right-edge framing cable silhouettes
	var right_fg_anchor := Control.new()
	right_fg_anchor.anchor_left = 1.0
	right_fg_anchor.anchor_right = 1.0
	right_fg_anchor.anchor_top = 0.0
	right_fg_anchor.anchor_bottom = 0.0
	right_fg_anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer_fg.add_child(right_fg_anchor)

	var r_cable_1 := Line2D.new()
	r_cable_1.points = PackedVector2Array([Vector2(-35, -20), Vector2(-78, 130), Vector2(-12, 290)])
	r_cable_1.width = 8.0
	r_cable_1.default_color = Color(0.02, 0.027, 0.047, 0.92)
	right_fg_anchor.add_child(r_cable_1)

	var r_cable_2 := Line2D.new()
	r_cable_2.points = PackedVector2Array([Vector2(-85, -20), Vector2(-120, 88), Vector2(-88, 185)])
	r_cable_2.width = 4.5
	r_cable_2.default_color = Color(0.028, 0.038, 0.065, 0.85)
	right_fg_anchor.add_child(r_cable_2)


func _build_skin_selector_overlay() -> void:
	var panel := PanelContainer.new()
	panel.name = "SkinSelectorPanel"
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_right = -56.0
	panel.offset_bottom = -64.0

	var p_sb := StyleBoxFlat.new()
	p_sb.bg_color = Color(0.04, 0.06, 0.10, 0.88)
	p_sb.border_color = COLOR_BORDER
	p_sb.set_border_width_all(1)
	p_sb.set_corner_radius_all(6)
	p_sb.content_margin_left = 10
	p_sb.content_margin_right = 10
	p_sb.content_margin_top = 8
	p_sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", p_sb)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var hdr := Label.new()
	hdr.text = "UNIT SKIN SELECTOR"
	if _font_bold:
		hdr.add_theme_font_override("font", _font_bold)
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.add_theme_color_override("font_color", COLOR_CYAN)
	vbox.add_child(hdr)

	_skin_cards_box = HBoxContainer.new()
	_skin_cards_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_skin_cards_box)

	_rebuild_skin_selector_cards()


func _rebuild_skin_selector_cards() -> void:
	if not is_instance_valid(_skin_cards_box):
		return
	for ch in _skin_cards_box.get_children():
		ch.queue_free()

	var sm: Node = get_node_or_null("/root/SaveManager")
	var skin_ids: Array[String] = ["default", "volt_scout", "plasma_sentinel"]
	if sm and sm.has_method("get_all_skin_ids"):
		skin_ids = sm.call("get_all_skin_ids")

	var portraits_tex: Texture2D = load(SKIN_PORTRAITS_PATH) if ResourceLoader.exists(SKIN_PORTRAITS_PATH) else null
	var badges_tex: Texture2D = load(SKIN_BADGES_PATH) if ResourceLoader.exists(SKIN_BADGES_PATH) else null

	for sid in skin_ids:
		var meta: Dictionary = sm.call("get_skin_metadata", sid) if sm else {"name": sid, "col_index": 0, "trail_color": COLOR_CYAN, "unlock_hint": ""}
		var unlocked: bool = sm.call("is_skin_unlocked", sid) if sm else (sid == "default")
		var is_active: bool = (str(sm.get("active_skin")) == sid) if sm else (sid == "default")
		var col_idx: int = int(meta.get("col_index", 0))
		var accent: Color = meta.get("trail_color", COLOR_CYAN)

		var card := Button.new()
		card.custom_minimum_size = Vector2(158, 60)
		card.disabled = not unlocked
		card.tooltip_text = str(meta.get("name", sid)) if unlocked else ("Terkunci: " + str(meta.get("unlock_hint", "")))

		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.12, 0.19, 0.96) if is_active else (Color(0.06, 0.08, 0.13, 0.9) if unlocked else Color(0.04, 0.05, 0.08, 0.85))
		sb.border_color = accent if is_active else (COLOR_BORDER if unlocked else Color(0.16, 0.19, 0.25, 0.6))
		sb.set_border_width_all(2 if is_active else 1)
		sb.set_corner_radius_all(5)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		sb.content_margin_top = 5
		sb.content_margin_bottom = 5
		card.add_theme_stylebox_override("normal", sb)
		card.add_theme_stylebox_override("hover", sb)
		card.add_theme_stylebox_override("pressed", sb)
		card.add_theme_stylebox_override("disabled", sb)

		var hbox := HBoxContainer.new()
		hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		hbox.offset_left = 6
		hbox.offset_right = -6
		hbox.offset_top = 5
		hbox.offset_bottom = -5
		hbox.add_theme_constant_override("separation", 6)
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(hbox)

		if portraits_tex:
			var prt := TextureRect.new()
			var at := AtlasTexture.new()
			at.atlas = portraits_tex
			at.region = Rect2(col_idx * 64, 0, 64, 64)
			at.filter_clip = true
			prt.texture = at
			prt.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			prt.custom_minimum_size = Vector2(44, 44)
			prt.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			prt.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			prt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			prt.modulate = Color.WHITE if unlocked else Color(0.35, 0.38, 0.45, 0.7)
			prt.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(prt)

		var iv := VBoxContainer.new()
		iv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		iv.add_theme_constant_override("separation", 2)
		iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(iv)

		var name_lbl := Label.new()
		name_lbl.text = str(meta.get("name", sid))
		name_lbl.clip_text = true
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_lbl.custom_minimum_size = Vector2(72, 0)
		if _font_semibold:
			name_lbl.add_theme_font_override("font", _font_semibold)
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color.WHITE if unlocked else Color(0.5, 0.55, 0.65))
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		iv.add_child(name_lbl)

		var status_row := HBoxContainer.new()
		status_row.add_theme_constant_override("separation", 4)
		status_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		iv.add_child(status_row)

		if badges_tex:
			var b_rect := TextureRect.new()
			var b_at := AtlasTexture.new()
			b_at.atlas = badges_tex
			b_at.region = Rect2((col_idx if unlocked else 3) * 16, 0, 16, 16)
			b_at.filter_clip = true
			b_rect.texture = b_at
			b_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			b_rect.custom_minimum_size = Vector2(14, 14)
			b_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			b_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			status_row.add_child(b_rect)

		var st_lbl := Label.new()
		st_lbl.text = "AKTIF" if is_active else ("PILIH" if unlocked else str(meta.get("unlock_hint", "Terkunci")))
		st_lbl.clip_text = true
		st_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		st_lbl.custom_minimum_size = Vector2(54, 0)
		if _font_regular:
			st_lbl.add_theme_font_override("font", _font_regular)
		st_lbl.add_theme_font_size_override("font_size", 9)
		st_lbl.add_theme_color_override("font_color", accent if is_active else (COLOR_GREEN if unlocked else Color(0.55, 0.6, 0.7)))
		st_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_row.add_child(st_lbl)

		if unlocked:
			var target_sid := sid
			card.pressed.connect(func() -> void:
				if sm and sm.has_method("equip_skin"):
					sm.call("equip_skin", target_sid)
			)

		_skin_cards_box.add_child(card)


func _refresh_modals_after_progression() -> void:
	if is_instance_valid(_level_select_modal):
		_level_select_modal.queue_free()
		_level_select_modal = null
	if is_instance_valid(_bug_log_modal):
		_bug_log_modal.queue_free()
		_bug_log_modal = null
	_build_level_select_modal()
	_build_bug_log_modal()


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
			var sm: Node = get_node_or_null("/root/SaveManager")
			var l1_done: bool = sm and sm.call("is_level_completed", "world_1_level_1")
			var l2_done: bool = sm and sm.call("is_level_completed", "world_1_level_2")
			var l3_done: bool = sm and sm.call("is_level_completed", "world_1_level_3")

			var btn_box := HBoxContainer.new()
			btn_box.add_theme_constant_override("separation", 8)
			ih.add_child(btn_box)

			var play_btn := Button.new()
			play_btn.text = "✓ Level 1" if l1_done else "Level 1"
			if _font_semibold:
				play_btn.add_theme_font_override("font", _font_semibold)
			play_btn.custom_minimum_size = Vector2(104, 34)
			play_btn.pressed.connect(_on_continue_pressed)
			btn_box.add_child(play_btn)

			var l2_btn := Button.new()
			l2_btn.text = "✓ Level 2" if l2_done else "Level 2"
			if _font_semibold:
				l2_btn.add_theme_font_override("font", _font_semibold)
			l2_btn.custom_minimum_size = Vector2(104, 34)
			l2_btn.pressed.connect(func() -> void:
				get_tree().change_scene_to_file("res://scenes/levels/world_1_syntax_shore/level_2.tscn")
			)
			btn_box.add_child(l2_btn)

			var l3_btn := Button.new()
			l3_btn.text = "✓ Level 3" if l3_done else "Level 3"
			if _font_semibold:
				l3_btn.add_theme_font_override("font", _font_semibold)
			l3_btn.custom_minimum_size = Vector2(104, 34)
			l3_btn.pressed.connect(func() -> void:
				get_tree().change_scene_to_file("res://scenes/levels/world_1_syntax_shore/level_3.tscn")
			)
			btn_box.add_child(l3_btn)
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
			"desc": "Angka pembagi tidak boleh bernilai nol dalam operasi matematika komputer.",
			"unlock": "Tersedia sejak awal"
		},
		{
			"id": "BUG-06",
			"name": "PEMDAS Operator Precedence",
			"world": "Dunia 1: Level 2 (Terminal 1)",
			"sample_bad": "total = a + b * c",
			"sample_good": "total = (a + b) * c",
			"desc": "Perkalian (*) dijalankan sebelum penjumlahan (+) kecuali diberi tanda kurung (...).",
			"unlock": "Tamatkan Level 2"
		},
		{
			"id": "BUG-07",
			"name": "Modulo Off-by-One / Zero Remainder",
			"world": "Dunia 1: Level 2 (Terminal 2)",
			"sample_bad": "tinggi = (base + off) % 4",
			"sample_good": "tinggi = (base + off) % 5",
			"desc": "Pembagi modulo (%) yang salah menyebabkan siklus lift berhenti di sisa 0 atau kurang 1 langkah.",
			"unlock": "Tamatkan Level 2"
		},
		{
			"id": "BUG-08",
			"name": "Variable Overwrite / Shadowing",
			"world": "Dunia 1: Level 2 (Terminal 3)",
			"sample_bad": "daya = 120\ndaya = 0",
			"sample_good": "daya = 120",
			"desc": "Nilai variabel yang sudah benar tertimpa ulang oleh assignment berikutnya sebelum dipakai.",
			"unlock": "Tamatkan Level 2"
		},
		{
			"id": "BUG-09",
			"name": "Integer Division (//) & abs()",
			"world": "Dunia 1: Level 2 T4 / Level 3 T1",
			"sample_bad": "langkah = -1 * (28 / 2)",
			"sample_good": "langkah = abs(28 // 2)",
			"desc": "Pembagian '/' menghasilkan float, sedangkan '//' menghasilkan bilangan bulat dan abs() mempositifkan arah.",
			"unlock": "Tamatkan Level 3"
		},
		{
			"id": "BUG-10",
			"name": "String-to-Int Type Casting (str() / int())",
			"world": "Dunia 1: Level 3 (Terminal 4 & 5)",
			"sample_bad": "kode = \"PORT_\" + 8080",
			"sample_good": "kode = \"PORT_\" + str(8080)",
			"desc": "Menggabungkan string dan angka memicu TypeError; konversi angka terlebih dahulu dengan str(...).",
			"unlock": "Tamatkan Level 3"
		}
	]

	var sm: Node = get_node_or_null("/root/SaveManager")
	for e in entries:
		var bug_id: String = str(e["id"])
		var is_unlocked: bool = sm.call("is_bug_log_unlocked", bug_id) if sm else true

		var card := PanelContainer.new()
		var c_style := StyleBoxFlat.new()
		c_style.bg_color = Color(0.1, 0.13, 0.19, 0.95) if is_unlocked else Color(0.06, 0.075, 0.11, 0.85)
		c_style.border_color = COLOR_AMBER if is_unlocked else Color(0.22, 0.26, 0.34, 0.7)
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
		h.text = "[%s] %s" % [bug_id, str(e["name"]) if is_unlocked else (str(e["name"]) + " (🔒 Terkunci)")]
		if _font_bold:
			h.add_theme_font_override("font", _font_bold)
		h.add_theme_font_size_override("font_size", 13)
		h.add_theme_color_override("font_color", COLOR_AMBER if is_unlocked else Color(0.55, 0.6, 0.7))
		cv.add_child(h)

		var w_lbl := Label.new()
		w_lbl.text = "Lokasi: %s" % str(e["world"]) if is_unlocked else ("Syarat Terbuka: " + str(e.get("unlock", "Selesaikan level")))
		if _font_semibold:
			w_lbl.add_theme_font_override("font", _font_semibold)
		w_lbl.add_theme_font_size_override("font_size", 11)
		w_lbl.add_theme_color_override("font_color", COLOR_CYAN if is_unlocked else Color(0.5, 0.56, 0.66))
		cv.add_child(w_lbl)

		if is_unlocked:
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

	a_vbox.add_child(_create_slider_row("Master Volume", int(_user_settings.get("master_vol", 80)), "Master", "master_vol"))
	a_vbox.add_child(_create_slider_row("Musik Latar (BGM)", int(_user_settings.get("bgm_vol", 75)), "BGM", "bgm_vol"))
	a_vbox.add_child(_create_slider_row("Efek Suara (SFX)", int(_user_settings.get("sfx_vol", 85)), "SFX", "sfx_vol"))

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
	fs_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	if _font_semibold:
		fs_check.add_theme_font_override("font", _font_semibold)
	fs_check.add_theme_font_size_override("font_size", 12)
	fs_check.toggled.connect(func(toggled_on: bool) -> void:
		if toggled_on:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_user_settings["fullscreen"] = toggled_on
		_save_user_settings()
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

	# Section 4: Data & Progres Reward
	var p_header := Label.new()
	p_header.text = "💾 PROGRES & DATA SIMPAN"
	if _font_bold:
		p_header.add_theme_font_override("font", _font_bold)
	p_header.add_theme_font_size_override("font_size", 14)
	p_header.add_theme_color_override("font_color", Color(0.97, 0.45, 0.45))
	vbox.add_child(p_header)

	var p_panel := _create_sub_box()
	vbox.add_child(p_panel)
	var p_vbox := VBoxContainer.new()
	p_vbox.add_theme_constant_override("separation", 8)
	p_panel.add_child(p_vbox)

	var p_desc := Label.new()
	p_desc.text = "Hapus progres level selesai, skin terbuka, debug tools, dan Bug Log (kembali ke kondisi awal)."
	if _font_regular:
		p_desc.add_theme_font_override("font", _font_regular)
	p_desc.add_theme_font_size_override("font_size", 11)
	p_desc.add_theme_color_override("font_color", Color(0.8, 0.85, 0.92))
	p_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p_vbox.add_child(p_desc)

	var p_row := HBoxContainer.new()
	p_row.add_theme_constant_override("separation", 10)
	p_vbox.add_child(p_row)

	var reset_btn := Button.new()
	reset_btn.text = "↺ Reset Progres Reward"
	reset_btn.custom_minimum_size = Vector2(200, 32)
	if _font_semibold:
		reset_btn.add_theme_font_override("font", _font_semibold)
	p_row.add_child(reset_btn)

	var confirm_row := HBoxContainer.new()
	confirm_row.visible = false
	confirm_row.add_theme_constant_override("separation", 8)
	p_row.add_child(confirm_row)

	var confirm_lbl := Label.new()
	confirm_lbl.text = "Yakin reset?"
	if _font_semibold:
		confirm_lbl.add_theme_font_override("font", _font_semibold)
	confirm_lbl.add_theme_font_size_override("font_size", 12)
	confirm_lbl.add_theme_color_override("font_color", COLOR_AMBER)
	confirm_row.add_child(confirm_lbl)

	var yes_btn := Button.new()
	yes_btn.text = "Ya, Reset"
	yes_btn.custom_minimum_size = Vector2(90, 30)
	confirm_row.add_child(yes_btn)

	var no_btn := Button.new()
	no_btn.text = "Batal"
	no_btn.custom_minimum_size = Vector2(72, 30)
	confirm_row.add_child(no_btn)

	var done_lbl := Label.new()
	done_lbl.text = "✓ Progres direset!"
	done_lbl.visible = false
	if _font_semibold:
		done_lbl.add_theme_font_override("font", _font_semibold)
	done_lbl.add_theme_font_size_override("font_size", 12)
	done_lbl.add_theme_color_override("font_color", COLOR_GREEN)
	p_row.add_child(done_lbl)

	reset_btn.pressed.connect(func() -> void:
		confirm_row.visible = true
		done_lbl.visible = false
	)
	no_btn.pressed.connect(func() -> void:
		confirm_row.visible = false
	)
	yes_btn.pressed.connect(func() -> void:
		var sm := get_node_or_null("/root/SaveManager")
		if sm and sm.has_method("reset_progression"):
			sm.call("reset_progression")
		confirm_row.visible = false
		done_lbl.visible = true
	)


func _ensure_audio_buses() -> void:
	for bus_name in ["BGM", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.get_bus_count()
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")


func _apply_bus_volume(bus_name: String, pct: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return
	var db := linear_to_db(pct / 100.0) if pct > 0.0 else -80.0
	AudioServer.set_bus_volume_db(bus_idx, db)


func _load_user_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		_user_settings["master_vol"] = int(cfg.get_value("audio", "master_vol", 80))
		_user_settings["bgm_vol"] = int(cfg.get_value("audio", "bgm_vol", 75))
		_user_settings["sfx_vol"] = int(cfg.get_value("audio", "sfx_vol", 85))
		_user_settings["fullscreen"] = bool(cfg.get_value("display", "fullscreen", false))

	_apply_bus_volume("Master", float(_user_settings["master_vol"]))
	_apply_bus_volume("BGM", float(_user_settings["bgm_vol"]))
	_apply_bus_volume("SFX", float(_user_settings["sfx_vol"]))
	if bool(_user_settings["fullscreen"]):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _save_user_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_vol", int(_user_settings.get("master_vol", 80)))
	cfg.set_value("audio", "bgm_vol", int(_user_settings.get("bgm_vol", 75)))
	cfg.set_value("audio", "sfx_vol", int(_user_settings.get("sfx_vol", 85)))
	cfg.set_value("display", "fullscreen", bool(_user_settings.get("fullscreen", false)))
	cfg.save(SETTINGS_PATH)


func _create_slider_row(label_text: String, default_val: int, bus_name: String = "Master", setting_key: String = "") -> HBoxContainer:
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
		_apply_bus_volume(bus_name, v)
		if not setting_key.is_empty():
			_user_settings[setting_key] = int(v)
			_save_user_settings()
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
	c_btn.name = "CloseButton"
	c_btn.text = "✕ Tutup [Esc]"
	if _font_semibold:
		c_btn.add_theme_font_override("font", _font_semibold)
	c_btn.pressed.connect(_close_all_modals)
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
	var is_cancel: bool = (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE) or event.is_action_pressed("ui_cancel")
	if is_cancel:
		if (_level_select_modal and _level_select_modal.visible) or (_bug_log_modal and _bug_log_modal.visible) or (_settings_modal and _settings_modal.visible):
			_close_all_modals()
			get_viewport().set_input_as_handled()


func _on_continue_pressed() -> void:
	if ResourceLoader.exists(LEVEL_1_PATH):
		get_tree().change_scene_to_file(LEVEL_1_PATH)


func _open_modal(modal: PanelContainer) -> void:
	_last_focused_button = get_viewport().gui_get_focus_owner()
	_close_all_modals(false)
	if _modal_dimmer:
		_modal_dimmer.visible = true
	if modal:
		modal.visible = true
		var close_btn: Button = modal.find_child("CloseButton", true, false) as Button
		if close_btn:
			close_btn.call_deferred("grab_focus")


func _on_level_select_pressed() -> void:
	_open_modal(_level_select_modal)


func _on_bug_log_pressed() -> void:
	_open_modal(_bug_log_modal)


func _on_settings_pressed() -> void:
	_open_modal(_settings_modal)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _close_all_modals(restore_focus: bool = true) -> void:
	if _modal_dimmer:
		_modal_dimmer.visible = false
	if _level_select_modal:
		_level_select_modal.visible = false
	if _bug_log_modal:
		_bug_log_modal.visible = false
	if _settings_modal:
		_settings_modal.visible = false
	if restore_focus and is_instance_valid(_last_focused_button):
		_last_focused_button.call_deferred("grab_focus")
		_last_focused_button = null
