extends Area2D
## Кам'яна голова на брамі. Клік -> Чечек підходить -> діалог.
## Якщо задано plug_item, їй можна заткнути рота цим предметом (перетягнути з інвентарю).

const DialogueUI = preload("res://dialogue/dialogue_ui.gd")

## Текстура й ділянка (Region) з якої вирізається голова. Вузол стоїть у центрі цієї ділянки.
@export var head_texture: Texture2D
@export var head_region := Rect2()
## Скрипт із static steps() -> Array
@export var dialogue: Script
@export var stop_distance := 300.0
@export var reply_key: StringName = &""

@export_group("Затикання")
@export var plug_item: ItemData
@export var plug_flag: StringName = &""
@export var plug_texture: Texture2D
@export var plug_offset := Vector2.ZERO
@export var plug_scale := Vector2(3, 3)

var _sprite: Sprite2D
var _plug: Sprite2D
var _plugging := false
var _talking := false

func _ready() -> void:
	add_to_group("gate_heads")
	if head_texture and head_region.size != Vector2.ZERO:
		_sprite = Sprite2D.new()
		_sprite.texture = head_texture
		_sprite.region_enabled = true
		_sprite.region_rect = head_region
		_sprite.centered = false
		_sprite.position = -head_region.size / 2.0
		add_child(_sprite)
		move_child(_sprite, 0)
		var rect := RectangleShape2D.new()
		rect.size = head_region.size
		($CollisionShape2D as CollisionShape2D).shape = rect
	if _is_plugged():
		_show_plug(false)
	if _sprite:
		HoverFX.register(self, _sprite)

func _is_plugged() -> bool:
	return plug_flag != &"" and Game.has_flag(plug_flag)

## Чи підходить цей предмет (для підсвітки під час перетягування)
func accepts(item: ItemData) -> bool:
	return plug_item != null and not _plugging and not _is_plugged() and item != null and item.id == plug_item.id

func is_used() -> bool:
	return _plugging or _is_plugged()

func use_item(item: ItemData) -> bool:
	if not accepts(item):
		return false
	_plugging = true
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.walk_to(global_position.x, _do_plug, stop_distance)
	else:
		_do_plug()
	return true

func _do_plug() -> void:
	HoverFX.unregister(self)
	Game.set_flag(plug_flag)
	_show_plug(true)

func _show_plug(animate: bool) -> void:
	if plug_texture == null:
		return
	_plug = Sprite2D.new()
	_plug.texture = plug_texture
	_plug.position = plug_offset
	_plug.scale = plug_scale
	add_child(_plug)
	if animate:
		_plug.scale = plug_scale * 2.0
		_plug.modulate.a = 0.0
		var tw := _plug.create_tween().set_parallel(true)
		tw.tween_property(_plug, "scale", plug_scale, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_plug, "modulate:a", 1.0, 0.15)

func _input_event(_viewport, event, _shape_idx) -> void:
	if _talking:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.walk_to(global_position.x, _talk, stop_distance)
		else:
			_talk()

func _talk() -> void:
	if _talking or dialogue == null:
		return
	_talking = true
	var ui = DialogueUI.new()
	add_child(ui)
	await ui.play(dialogue.call("steps"))
	_talking = false

## Викликається, коли брама відкрилась: голови зникають
func disable() -> void:
	HoverFX.unregister(self)
	input_pickable = false
	visible = false
