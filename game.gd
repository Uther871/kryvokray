extends Node

signal flag_set(id: StringName)

const Replies = preload("res://replies.gd")

const FADE_TIME := 0.3

# --- Діалогова бульбашка ---
const WRONG_USE_TEXT := "That’s not gonna work!"
const BUBBLE_SCALE := 11.0                      # dialog.png 32x32 -> 352x352
const BUBBLE_TIP := Vector2(16, 310)            # кінчик «хвостика» на бульбашці (у пікселях)
const BUBBLE_HEAD_OFFSET := Vector2(50, -105)   # де кінчик має бути відносно спрайта Чечека
const BUBBLE_FADE_IN := 0.25
const BUBBLE_HOLD := 2.0
const BUBBLE_FADE_OUT := 0.4

var flags := {}
var data := {}
var next_spawn_x := -1.0

var _fade: ColorRect
var _busy := false

var _bubble: Control
var _bubble_tex: TextureRect
var _bubble_label: Label
var _bubble_tween: Tween
var _bubble_flipped := false

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	layer.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_bubble()

func _build_bubble() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 80
	add_child(layer)
	var size := Vector2(32, 32) * BUBBLE_SCALE
	_bubble = Control.new()
	_bubble.size = size
	_bubble.pivot_offset = BUBBLE_TIP
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.visible = false
	_bubble.modulate.a = 0.0
	layer.add_child(_bubble)
	_bubble_tex = TextureRect.new()
	_bubble_tex.texture = load("res://assets/dialog.png")
	_bubble_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bubble_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bubble_tex.stretch_mode = TextureRect.STRETCH_SCALE
	_bubble_tex.size = size
	_bubble_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.add_child(_bubble_tex)
	_bubble_label = Label.new()
	_bubble_label.add_theme_font_override("font", load("res://assets/Bristol.ttf"))
	_bubble_label.add_theme_font_size_override("font_size", 40)
	_bubble_label.add_theme_color_override("font_color", Color(0.08, 0.01, 0.03))
	_bubble_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble_label.size = Vector2(230, 150)
	_bubble.add_child(_bubble_label)
	_set_bubble_flip(false)

func _set_bubble_flip(flipped: bool) -> void:
	_bubble_flipped = flipped
	_bubble_tex.flip_h = flipped
	_bubble.pivot_offset = Vector2(_bubble.size.x - BUBBLE_TIP.x, BUBBLE_TIP.y) if flipped else BUBBLE_TIP
	# Центр еліпса бульбашки: (187, 160), у дзеркальному варіанті по X навпаки
	var center_x := _bubble.size.x - 187.0 if flipped else 187.0
	_bubble_label.position = Vector2(center_x - _bubble_label.size.x / 2.0, 160.0 - _bubble_label.size.y / 2.0)

## Показує бульбашку над головою Чечека: плавно з'являється, висить ~2 с, плавно зникає.
func say(text := WRONG_USE_TEXT) -> void:
	_bubble_label.text = text
	# Підбираємо найбільший розмір шрифту, при якому текст вміщується в бульбашку
	var font: Font = _bubble_label.get_theme_font("font")
	var chosen := 40
	for fs in [40, 36, 32, 29, 26]:
		chosen = fs
		if font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, _bubble_label.size.x, fs).y <= _bubble_label.size.y:
			break
	_bubble_label.add_theme_font_size_override("font_size", chosen)
	var was_visible := _bubble.visible
	_bubble.visible = true
	if not was_visible:
		_bubble.modulate.a = 0.0
		_bubble.scale = Vector2(0.8, 0.8)
	_place_bubble()
	if _bubble_tween and _bubble_tween.is_valid():
		_bubble_tween.kill()
	_bubble_tween = create_tween()
	_bubble_tween.set_parallel(true)
	_bubble_tween.tween_property(_bubble, "modulate:a", 1.0, BUBBLE_FADE_IN).set_trans(Tween.TRANS_SINE)
	_bubble_tween.tween_property(_bubble, "scale", Vector2.ONE, BUBBLE_FADE_IN + 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bubble_tween.chain().tween_interval(BUBBLE_HOLD)
	_bubble_tween.chain().tween_property(_bubble, "modulate:a", 0.0, BUBBLE_FADE_OUT).set_trans(Tween.TRANS_SINE)
	_bubble_tween.chain().tween_callback(func(): _bubble.visible = false)

func _place_bubble() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	var sprite: Node2D = null
	if player:
		sprite = player.get_node_or_null("Sprite2D") as Node2D
	var screen_size := get_viewport().get_visible_rect().size
	var tip := screen_size / 2.0
	if sprite:
		tip = get_viewport().get_canvas_transform() * (sprite.global_position + BUBBLE_HEAD_OFFSET)
	# Біля правого краю екрана бульбашку віддзеркалюємо: хвостик дивиться вліво-вниз -> вправо-вниз
	var flip := tip.x + (_bubble.size.x - BUBBLE_TIP.x) > screen_size.x - 20.0
	if flip != _bubble_flipped:
		_set_bubble_flip(flip)
	var tip_local := Vector2(_bubble.size.x - BUBBLE_TIP.x, BUBBLE_TIP.y) if flip else BUBBLE_TIP
	var pos := tip - tip_local
	pos.x = clampf(pos.x, 0.0, screen_size.x - _bubble.size.x)
	pos.y = maxf(pos.y, 80.0)
	_bubble.position = pos

func _process(_delta: float) -> void:
	if _bubble and _bubble.visible:
		_place_bubble()

func set_flag(id: StringName) -> void:
	if flags.get(id, false):
		return
	flags[id] = true
	flag_set.emit(id)

func has_flag(id: StringName) -> bool:
	return flags.get(id, false)

func go_to(scene_path: String, spawn_x := -1.0) -> void:
	if _busy:
		return
	_busy = true
	Replies.reset()
	next_spawn_x = spawn_x
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, FADE_TIME)
	await tw.finished
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	tw = create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, FADE_TIME)
	await tw.finished
	_busy = false
