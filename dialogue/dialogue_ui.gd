extends CanvasLayer
## Діалогове вікно внизу екрана. Малюється кодом, окремої сцени не потребує.
## Використання:
##   var ui = preload("res://dialogue/dialogue_ui.gd").new()
##   add_child(ui)
##   await ui.play(steps)
##
## Кроки (steps) — масив словників:
##   {"who": "Grets", "say": "Текст репліки"}
##   {"choice": ["А", "Б", "В"], "correct": 2, "right": [кроки], "wrong": [кроки], "retry": true}
##     retry = false: після хибної відповіді діалог одразу закінчується (гравця «викидає»)
##   {"flag": "ім'я_прапорця"}   — ставить прапорець у Game

signal finished

const PANEL_BG := Color(0.29, 0.055, 0.078)
const PANEL_BORDER := Color(0.549, 0.11, 0.165)
const BUTTON_HOVER := Color(0.42, 0.08, 0.12)
const TEXT_COLOR := Color(0.96, 0.89, 0.8)
const FONT_SIZE := 32
const CHARS_PER_SEC := 45.0
const SPEAKER_COLORS := {
	"Chechek": Color(0.98, 0.85, 0.35),
	"Grets": Color(0.95, 0.5, 0.55),
	"Head": Color(0.78, 0.62, 0.64),
}

var _root: Control
var _name: Label
var _text: Label
var _choices: VBoxContainer
var _advance := false
var _chosen := -1
var _aborted := false

func _ready() -> void:
	layer = 50
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP  # ловить кліки, щоб Чечек не ходив під час діалогу
	_root.visible = false
	_root.gui_input.connect(_on_root_input)
	add_child(_root)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.1
	panel.anchor_right = 0.9
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	# Висота за вмістом, росте ВГОРУ від нижнього краю, щоб усі відповіді були видні
	panel.offset_top = -90.0
	panel.offset_bottom = -90.0
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.add_theme_stylebox_override("panel", _box(PANEL_BG, PANEL_BORDER, 24))
	_root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	_name = _label()
	vbox.add_child(_name)

	_text = _label()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(0, 100)
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_text)

	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 8)
	_choices.visible = false
	vbox.add_child(_choices)

func _label() -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", Game.font)
	l.add_theme_font_size_override("font_size", FONT_SIZE)
	l.add_theme_color_override("font_color", TEXT_COLOR)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _box(bg: Color, border: Color, margin: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(3)
	b.set_corner_radius_all(4)
	b.set_content_margin_all(margin)
	return b

func _on_root_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance = true

func _input(event: InputEvent) -> void:
	if _root and _root.visible and event.is_action_pressed("ui_accept"):
		_advance = true
		get_viewport().set_input_as_handled()

func play(steps: Array) -> void:
	_aborted = false
	_root.visible = true
	await _run(steps)
	_root.visible = false
	finished.emit()
	queue_free()

func _run(steps: Array) -> void:
	for step in steps:
		if _aborted:
			return
		if step.has("say"):
			await _say(step["who"], step["say"])
		elif step.has("choice"):
			while true:
				var idx: int = await _ask(step["choice"])
				await _say("Chechek", step["choice"][idx])
				if idx == step.get("correct", -1):
					await _run(step.get("right", []))
					break
				await _run(step.get("wrong", []))
				if not step.get("retry", true):
					_aborted = true
					return
		elif step.has("flag"):
			Game.set_flag(StringName(step["flag"]))

func _say(who: String, text: String) -> void:
	_choices.visible = false
	_name.text = who
	_name.add_theme_color_override("font_color", SPEAKER_COLORS.get(who, TEXT_COLOR))
	_text.text = text
	_text.visible_characters = 0
	_advance = false
	var t := 0.0
	while _text.visible_characters < text.length():
		await get_tree().process_frame
		t += get_process_delta_time()
		_text.visible_characters = int(t * CHARS_PER_SEC)
		if _advance:  # клік під час «друку» одразу показує весь текст
			break
	_text.visible_characters = -1
	_advance = false
	while not _advance:  # чекаємо клік, щоб іти далі
		await get_tree().process_frame
	_advance = false

func _ask(options: Array) -> int:
	for c in _choices.get_children():
		c.queue_free()
	for i in options.size():
		var b := Button.new()
		b.text = options[i]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_override("font", Game.font)
		b.add_theme_font_size_override("font_size", FONT_SIZE)
		b.add_theme_color_override("font_color", TEXT_COLOR)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_stylebox_override("normal", _box(PANEL_BG.darkened(0.2), PANEL_BORDER, 8))
		b.add_theme_stylebox_override("hover", _box(BUTTON_HOVER, Color(0.98, 0.85, 0.35), 8))
		b.add_theme_stylebox_override("pressed", _box(BUTTON_HOVER, Color(0.98, 0.85, 0.35), 8))
		b.pressed.connect(func(): _chosen = i)
		_choices.add_child(b)
	_chosen = -1
	_choices.visible = true
	while _chosen < 0:
		await get_tree().process_frame
	_choices.visible = false
	return _chosen
