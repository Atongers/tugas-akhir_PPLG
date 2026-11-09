extends CanvasLayer
class_name TerminalOverlay

signal terminal_closed
signal terminal_solved(terminal_id: String, bug_info: Dictionary)
signal level_action_triggered(action_name: String, arg_value: Variant)

var _backdrop: ColorRect = null
var _main_panel: PanelContainer = null
var _header_label: Label = null
var _close_btn: Button = null
var _code_edit: CodeEdit = null
var _locked_info_label: Label = null
var _output_rtl: RichTextLabel = null
var _watch_rtl: RichTextLabel = null
var _lint_rtl: RichTextLabel = null
var _run_btn: Button = null
var _reset_btn: Button = null
var _hint_btn: Button = null
var _speed_1x_btn: Button = null
var _speed_2x_btn: Button = null
var _speed_skip_btn: Button = null

var _current_terminal_id: String = ""
var _current_config: Dictionary = {}
var _saved_codes: Dictionary = {}
var _hint_levels: Dictionary = {}
var _solved_terminals: Dictionary = {}

var _is_open: bool = false
var _is_running_steps: bool = false
var _step_delay: float = 0.42
var _locked_lines_map: Dictionary = {}
var _suppress_text_change: bool = false


func _ready() -> void:
	layer = 20
	_build_ui()
	visible = false


func _process(_delta: float) -> void:
	if not _is_open:
		return
	if Input.is_action_just_pressed("terminal_close"):
		close_terminal()
	elif Input.is_action_just_pressed("terminal_run"):
		_on_run_pressed()
	elif Input.is_action_just_pressed("terminal_reset"):
		_on_reset_pressed()
	elif Input.is_action_just_pressed("terminal_hint"):
		_on_hint_pressed()


func is_open() -> bool:
	return _is_open


func _extract_initial_code(config: Dictionary) -> String:
	var raw = config.get("initial_code", "")
	if raw is Array:
		var parts: PackedStringArray = []
		for item in raw:
			parts.append(str(item))
		return "\n".join(parts)
	return str(raw)


func open_terminal(terminal_id: String, config: Dictionary, total_terminals: int = 4) -> void:
	_current_terminal_id = terminal_id
	_current_config = config
	_is_open = true
	visible = true

	var default_idx := 1
	if terminal_id.begins_with("Terminal_"):
		default_idx = maxi(1, int(terminal_id.trim_prefix("Terminal_")))
	var idx: int = int(config.get("index", default_idx))
	var title: String = str(config.get("title", terminal_id))
	var is_done: bool = _solved_terminals.get(terminal_id, false)
	var status_tag: String = " [SELESAI ✓]" if is_done else ""
	_header_label.text = "Terminal %d/%d — %s%s" % [idx, total_terminals, title, status_tag]

	var initial_code: String = _extract_initial_code(config)
	var code_to_show: String = _saved_codes.get(terminal_id, initial_code)

	_setup_locked_lines(initial_code, config.get("locked_lines", []))

	_suppress_text_change = true
	_code_edit.text = code_to_show
	_suppress_text_change = false
	_clear_line_highlights()

	var hint_lvl: int = int(_hint_levels.get(terminal_id, 0))
	_update_hint_display(hint_lvl)

	_output_rtl.clear()
	_output_rtl.append_text("[color=#94a3b8]Siap menjalankan kode Python.\nTekan [b]Run (Ctrl+Enter)[/b] untuk menguji perbaikanmu![/color]")

	_watch_rtl.clear()
	_watch_rtl.append_text("[color=#94a3b8]Belum ada variabel yang dievaluasi.[/color]")

	_code_edit.grab_focus()


func close_terminal() -> void:
	if not _is_open:
		return
	if not _current_terminal_id.is_empty() and is_instance_valid(_code_edit):
		_saved_codes[_current_terminal_id] = _code_edit.text
	_is_open = false
	visible = false
	terminal_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_terminal()


func _setup_locked_lines(initial_code: String, locked_indices: Array) -> void:
	_locked_lines_map.clear()
	var lines := initial_code.split("\n")
	var lock_nums: PackedStringArray = []
	for li in locked_indices:
		var line_idx := int(li)
		if line_idx >= 0 and line_idx < lines.size():
			_locked_lines_map[line_idx] = lines[line_idx]
			lock_nums.append(str(line_idx + 1))
	if lock_nums.size() > 0:
		_locked_info_label.text = "🔒 Baris terkunci: Baris " + ", ".join(lock_nums) + " (fokus perbaiki baris lainnya)"
	else:
		_locked_info_label.text = "✏️ Semua baris kode dapat diedit"


func _on_code_text_changed() -> void:
	if _suppress_text_change or _locked_lines_map.is_empty():
		return
	var current_lines := _code_edit.text.split("\n")
	var modified := false
	for idx in _locked_lines_map.keys():
		var line_idx: int = int(idx)
		var locked_str: String = _locked_lines_map[line_idx]
		if line_idx < current_lines.size() and current_lines[line_idx] != locked_str:
			current_lines[line_idx] = locked_str
			modified = true
	if modified:
		var caret_l := _code_edit.get_caret_line()
		var caret_c := _code_edit.get_caret_column()
		_suppress_text_change = true
		_code_edit.text = "\n".join(current_lines)
		_code_edit.set_caret_line(caret_l)
		_code_edit.set_caret_column(caret_c)
		_suppress_text_change = false


func _clear_line_highlights() -> void:
	if not is_instance_valid(_code_edit):
		return
	for i in range(_code_edit.get_line_count()):
		if _locked_lines_map.has(i):
			_code_edit.set_line_background_color(i, Color(0.18, 0.22, 0.3, 0.45))
		else:
			_code_edit.set_line_background_color(i, Color(0, 0, 0, 0))


func _on_run_pressed() -> void:
	if _is_running_steps:
		return
	_saved_codes[_current_terminal_id] = _code_edit.text
	_clear_line_highlights()

	var allowed_fn: Array[String] = []
	var req_fn: String = str(_current_config.get("required_call", ""))
	if not req_fn.is_empty():
		allowed_fn.append(req_fn)

	var res: Dictionary = PythonInterpreter.run_script(_code_edit.text, allowed_fn)
	await _animate_execution(res)


func _animate_execution(res: Dictionary) -> void:
	_is_running_steps = true
	_run_btn.disabled = true
	_output_rtl.clear()
	_watch_rtl.clear()

	var steps: Array = res.get("steps", [])
	for step in steps:
		if not _is_open:
			break
		_clear_line_highlights()
		var line_idx: int = int(step.get("line", 1)) - 1
		var step_err: String = str(step.get("error", ""))

		if line_idx >= 0 and line_idx < _code_edit.get_line_count():
			if not step_err.is_empty():
				_code_edit.set_line_background_color(line_idx, Color(0.85, 0.2, 0.25, 0.45))
			else:
				_code_edit.set_line_background_color(line_idx, Color(0.95, 0.78, 0.15, 0.38))

		# Update Watch / Variables panel
		var env: Dictionary = step.get("env", {})
		_render_watch_env(env, int(step.get("line", 1)))

		# Append outputs from print()
		var outs: Array = step.get("outputs", [])
		for o in outs:
			_output_rtl.append_text("[color=#38bdf8]> print:[/color] [b]%s[/b]\n" % str(o))

		# Check level function call
		var call_info: Dictionary = step.get("call", {})
		if not call_info.is_empty():
			var fn_name: String = str(call_info.get("name", ""))
			var fn_args: Array = call_info.get("args", [])
			var arg0 = fn_args[0] if fn_args.size() > 0 else null
			_output_rtl.append_text("[color=#a78bfa]> Memanggil:[/color] [code]%s(%s)[/code]\n" % [fn_name, str(arg0)])
			level_action_triggered.emit(fn_name, arg0)

		if not step_err.is_empty():
			_output_rtl.append_text("\n[color=#f87171][b]❌ %s[/b][/color]\n" % step_err)
			_is_running_steps = false
			_run_btn.disabled = false
			return

		if _step_delay > 0.0:
			await get_tree().create_timer(_step_delay).timeout

	_clear_line_highlights()
	_evaluate_terminal_goal(res)
	_is_running_steps = false
	_run_btn.disabled = false


func _render_watch_env(env: Dictionary, active_line: int) -> void:
	_watch_rtl.clear()
	_watch_rtl.append_text("[color=#fbbf24]Baris dieksekusi: #%d[/color]\n" % active_line)
	if env.is_empty():
		_watch_rtl.append_text("[color=#94a3b8](Belum ada variabel)[/color]")
		return
	for k in env.keys():
		var v = env[k]
		var type_label := "int"
		if typeof(v) == TYPE_STRING:
			type_label = "str"
			v = "\"%s\"" % v
		elif typeof(v) == TYPE_FLOAT:
			type_label = "float"
		elif typeof(v) == TYPE_BOOL:
			type_label = "bool"
		_watch_rtl.append_text("• [b]%s[/b] = [color=#4ade80]%s[/color] [color=#64748b](%s)[/color]\n" % [str(k), str(v), type_label])


func _evaluate_terminal_goal(res: Dictionary) -> void:
	if not bool(res.get("ok", false)):
		return

	var req_call: String = str(_current_config.get("required_call", ""))
	var expected_arg = _current_config.get("expected_arg", null)
	var req_print: bool = bool(_current_config.get("require_print", false))
	var expected_print: String = str(_current_config.get("expected_print", ""))

	var outputs: Array = res.get("outputs", [])
	var calls: Array = res.get("calls", [])

	if req_print:
		if outputs.is_empty():
			_output_rtl.append_text("\n[color=#fb923c][b]⚠️ Belum Sesuai Target:[/b] Kamu belum mencetak status dengan [code]print()[/code].[/color]\n")
			return
		if not expected_print.is_empty() and not outputs.has(expected_print):
			_output_rtl.append_text("\n[color=#fb923c][b]⚠️ Belum Sesuai Target:[/b] Hasil [code]print()[/code] adalah '%s', seharusnya '%s'.[/color]\n" % [str(outputs[0]), expected_print])
			return

	var matched_call := false
	var actual_arg = null
	for c in calls:
		if str(c.get("name", "")) == req_call:
			matched_call = true
			var c_args: Array = c.get("args", [])
			if c_args.size() > 0:
				actual_arg = c_args[0]

	if not matched_call:
		_output_rtl.append_text("\n[color=#fb923c][b]⚠️ Belum Sesuai Target:[/b] Fungsi [code]%s()[/code] belum dipanggil.[/color]\n" % req_call)
		return

	if typeof(actual_arg) != typeof(expected_arg) or actual_arg != expected_arg:
		var fail_reason: String = str(_current_config.get("logical_fail_hint", "Nilai argumen yang dikirim belum tepat."))
		_output_rtl.append_text(
			"\n[color=#fb923c][b]⚠️ Bug Logika Terdeteksi:[/b]\nFungsi [code]%s(%s)[/code] menerima nilai [b]%s[/b], padahal target yang dibutuhkan adalah [b]%s[/b].\n💡 %s[/color]\n"
			% [req_call, str(actual_arg), str(actual_arg), str(expected_arg), fail_reason]
		)
		return

	# Success!
	for i in range(_code_edit.get_line_count()):
		if not _locked_lines_map.has(i):
			_code_edit.set_line_background_color(i, Color(0.15, 0.75, 0.35, 0.3))

	var success_msg: String = str(_current_config.get("success_message", "Target terpenuhi! Objek level telah aktif."))
	_output_rtl.append_text("\n[color=#4ade80][b]✅ BERHASIL![/b]\n%s[/color]\n" % success_msg)

	_solved_terminals[_current_terminal_id] = true
	var bug_info: Dictionary = _current_config.get("bug_log_entry", {})
	terminal_solved.emit(_current_terminal_id, bug_info)


func _on_reset_pressed() -> void:
	if _is_running_steps:
		return
	var initial_code: String = _extract_initial_code(_current_config)
	_saved_codes[_current_terminal_id] = initial_code
	_suppress_text_change = true
	_code_edit.text = initial_code
	_suppress_text_change = false
	_clear_line_highlights()
	_output_rtl.clear()
	_output_rtl.append_text("[color=#94a3b8]Kode telah dikembalikan ke kondisi awal.[/color]")


func _on_hint_pressed() -> void:
	var cur_lvl: int = int(_hint_levels.get(_current_terminal_id, 0))
	cur_lvl = mini(cur_lvl + 1, 3)
	_hint_levels[_current_terminal_id] = cur_lvl
	_update_hint_display(cur_lvl)


func _update_hint_display(hint_lvl: int) -> void:
	_hint_btn.text = "💡 Hint (%d/3) [F1]" % hint_lvl
	_lint_rtl.clear()
	var objective: String = str(_current_config.get("objective", ""))
	_lint_rtl.append_text("[color=#38bdf8][b]🤖 Lint (AI Pendamping):[/b][/color]\n")
	_lint_rtl.append_text("[color=#e2e8f0]Tujuan: %s[/color]\n" % objective)

	var hints: Array = _current_config.get("hints", [])
	if hint_lvl == 0:
		_lint_rtl.append_text("[color=#94a3b8]Tekan [b]Hint (F1)[/b] jika kamu butuh petunjuk bertahap (1–3).[/color]")
	else:
		for i in range(mini(hint_lvl, hints.size())):
			_lint_rtl.append_text("\n[color=#fde047][b]Hint %d:[/b] %s[/color]" % [i + 1, str(hints[i])])


func _set_speed(delay: float, active_btn: Button) -> void:
	_step_delay = delay
	for b in [_speed_1x_btn, _speed_2x_btn, _speed_skip_btn]:
		if is_instance_valid(b):
			b.button_pressed = (b == active_btn)


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.04, 0.06, 0.1, 0.72)
	add_child(_backdrop)

	_main_panel = PanelContainer.new()
	_main_panel.name = "TerminalWindow"
	_main_panel.set_anchors_preset(Control.PRESET_CENTER)
	_main_panel.custom_minimum_size = Vector2(920, 520)
	_main_panel.offset_left = -460
	_main_panel.offset_top = -260
	_main_panel.offset_right = 460
	_main_panel.offset_bottom = 260

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.11, 0.16, 0.97)
	style.border_color = Color(0.22, 0.65, 0.95, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	_main_panel.add_theme_stylebox_override("panel", style)
	add_child(_main_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	_main_panel.add_child(root_vbox)

	# 1. Header Bar
	var header_hbox := HBoxContainer.new()
	root_vbox.add_child(header_hbox)

	_header_label = Label.new()
	_header_label.text = "Terminal 1/4"
	_header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_label.add_theme_font_size_override("font_size", 18)
	_header_label.add_theme_color_override("font_color", Color(0.35, 0.85, 1.0))
	header_hbox.add_child(_header_label)

	_close_btn = Button.new()
	_close_btn.text = "✕ Tutup [Esc]"
	_close_btn.pressed.connect(close_terminal)
	header_hbox.add_child(_close_btn)

	# 2. Body Split (Left: Code Editor, Right: Output/Error + Watch/Lint)
	var body_hbox := HBoxContainer.new()
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hbox.add_theme_constant_override("separation", 12)
	root_vbox.add_child(body_hbox)

	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.size_flags_stretch_ratio = 1.25
	body_hbox.add_child(left_vbox)

	_locked_info_label = Label.new()
	_locked_info_label.add_theme_font_size_override("font_size", 12)
	_locked_info_label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.92))
	left_vbox.add_child(_locked_info_label)

	_code_edit = CodeEdit.new()
	_code_edit.name = "CodeEditor"
	_code_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_code_edit.gutters_draw_line_numbers = true
	_code_edit.indent_automatic = true
	_code_edit.auto_brace_completion_enabled = true
	_code_edit.add_theme_font_size_override("font_size", 16)
	_code_edit.syntax_highlighter = _create_python_highlighter()
	_code_edit.text_changed.connect(_on_code_text_changed)
	left_vbox.add_child(_code_edit)

	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.size_flags_stretch_ratio = 1.0
	right_vbox.add_theme_constant_override("separation", 8)
	body_hbox.add_child(right_vbox)

	var out_title := Label.new()
	out_title.text = "📺 OUTPUT & PESAN ERROR"
	out_title.add_theme_font_size_override("font_size", 13)
	out_title.add_theme_color_override("font_color", Color(0.95, 0.75, 0.3))
	right_vbox.add_child(out_title)

	var out_panel := _make_sub_panel()
	out_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(out_panel)

	_output_rtl = RichTextLabel.new()
	_output_rtl.bbcode_enabled = true
	_output_rtl.scroll_following = true
	_output_rtl.selection_enabled = true
	out_panel.add_child(_output_rtl)

	var watch_title := Label.new()
	watch_title.text = "🔍 STATUS VARIABEL & BANTUAN LINT"
	watch_title.add_theme_font_size_override("font_size", 13)
	watch_title.add_theme_color_override("font_color", Color(0.45, 0.9, 0.65))
	right_vbox.add_child(watch_title)

	var watch_panel := _make_sub_panel()
	watch_panel.custom_minimum_size = Vector2(0, 95)
	right_vbox.add_child(watch_panel)

	_watch_rtl = RichTextLabel.new()
	_watch_rtl.bbcode_enabled = true
	watch_panel.add_child(_watch_rtl)

	var lint_panel := _make_sub_panel()
	lint_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(lint_panel)

	_lint_rtl = RichTextLabel.new()
	_lint_rtl.bbcode_enabled = true
	_lint_rtl.scroll_following = true
	lint_panel.add_child(_lint_rtl)

	# 3. Bottom Action & Speed Bar
	var footer_hbox := HBoxContainer.new()
	footer_hbox.add_theme_constant_override("separation", 10)
	root_vbox.add_child(footer_hbox)

	_run_btn = Button.new()
	_run_btn.text = "▶ Run [Ctrl+Enter]"
	_run_btn.custom_minimum_size = Vector2(150, 36)
	_run_btn.pressed.connect(_on_run_pressed)
	footer_hbox.add_child(_run_btn)

	_reset_btn = Button.new()
	_reset_btn.text = "↺ Reset [Ctrl+R]"
	_reset_btn.custom_minimum_size = Vector2(130, 36)
	_reset_btn.pressed.connect(_on_reset_pressed)
	footer_hbox.add_child(_reset_btn)

	_hint_btn = Button.new()
	_hint_btn.text = "💡 Hint (0/3) [F1]"
	_hint_btn.custom_minimum_size = Vector2(150, 36)
	_hint_btn.pressed.connect(_on_hint_pressed)
	footer_hbox.add_child(_hint_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_hbox.add_child(spacer)

	var spd_lbl := Label.new()
	spd_lbl.text = "Kecepatan:"
	footer_hbox.add_child(spd_lbl)

	_speed_1x_btn = Button.new()
	_speed_1x_btn.text = "1x"
	_speed_1x_btn.toggle_mode = true
	_speed_1x_btn.button_pressed = true
	_speed_1x_btn.pressed.connect(func(): _set_speed(0.42, _speed_1x_btn))
	footer_hbox.add_child(_speed_1x_btn)

	_speed_2x_btn = Button.new()
	_speed_2x_btn.text = "2x"
	_speed_2x_btn.toggle_mode = true
	_speed_2x_btn.pressed.connect(func(): _set_speed(0.18, _speed_2x_btn))
	footer_hbox.add_child(_speed_2x_btn)

	_speed_skip_btn = Button.new()
	_speed_skip_btn.text = "Skip"
	_speed_skip_btn.toggle_mode = true
	_speed_skip_btn.pressed.connect(func(): _set_speed(0.0, _speed_skip_btn))
	footer_hbox.add_child(_speed_skip_btn)


func _make_sub_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.11, 0.95)
	sb.border_color = Color(0.2, 0.28, 0.4, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _create_python_highlighter() -> CodeHighlighter:
	var hl := CodeHighlighter.new()
	hl.number_color = Color(0.98, 0.65, 0.35)
	hl.symbol_color = Color(0.55, 0.82, 0.98)
	hl.function_color = Color(0.4, 0.88, 0.98)
	hl.member_variable_color = Color(0.88, 0.92, 0.98)

	hl.add_color_region("#", "", Color(0.45, 0.55, 0.65), true)
	hl.add_color_region("\"", "\"", Color(0.55, 0.92, 0.55), false)
	hl.add_color_region("'", "'", Color(0.55, 0.92, 0.55), false)

	for kw in ["True", "False", "None", "and", "or", "not", "if", "elif", "else", "for", "while", "in", "def", "return"]:
		hl.add_keyword_color(kw, Color(0.85, 0.5, 0.98))

	for fn in ["print", "int", "str", "abs", "matikan_laser_oranye", "aktifkan_elevator", "set_tegangan_laser_biru", "buka_gerbang_exit"]:
		hl.add_keyword_color(fn, Color(0.35, 0.85, 1.0))

	return hl
