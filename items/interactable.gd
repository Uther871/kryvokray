@tool
extends Area2D

signal used

@export var required_item: ItemData
@export var stop_distance := 150.0
@export var result_texture: Texture2D
@export var result_offset := Vector2.ZERO
@export var result_scale := Vector2.ONE
@export var sets_flag: StringName = &""
@export var invisible_zone := false
@export var spawn_scene: PackedScene
@export var spawn_item: ItemData
@export var spawn_scale := 4.0
@export var highlight_target: CanvasItem
@export var hover_strength := 1.35
## Розмір зони кліку в пікселях. (0,0) = лишити форму із заготовки.
@export var zone_size := Vector2.ZERO:
	set(value):
		zone_size = value
		if is_node_ready():
			_apply_zone()

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

var _done := false
var _flag: StringName
var _drop_pos := Vector2.ZERO

func _ready() -> void:
	_apply_zone()
	if Engine.is_editor_hint():
		return
	# Зона лише приймає предмети (перетягування), кліки не ловить
	input_pickable = false
	var scene_path := owner.scene_file_path if owner else ""
	_flag = StringName("used/%s/%s" % [scene_path, name])
	if sprite and invisible_zone:
		sprite.visible = false
	if Game.has_flag(_flag):
		_done = true
		_apply_result()
		if Game.data.has(_flag):
			_spawn.call_deferred(Game.data[_flag], false)
		return
	var target: CanvasItem = highlight_target if highlight_target else sprite
	HoverFX.register(self, target, hover_strength)

func _apply_zone() -> void:
	if zone_size == Vector2.ZERO:
		return
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null:
		return
	var rect := RectangleShape2D.new()
	rect.size = zone_size
	cs.shape = rect

## Чи підходить цей предмет до об'єкта (для підсвітки під час перетягування)
func accepts(item: ItemData) -> bool:
	return not _done and required_item != null and item != null and item.id == required_item.id

func use_item(item: ItemData) -> bool:
	if not accepts(item):
		return false
	_done = true
	_drop_pos = get_global_mouse_position()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var target_x := _drop_pos.x if invisible_zone else global_position.x
		player.walk_to(target_x, _on_used, stop_distance)
	else:
		_on_used()
	return true

func _on_used() -> void:
	HoverFX.unregister(self)
	Game.set_flag(_flag)
	if sets_flag != &"":
		Game.set_flag(sets_flag)
	if spawn_scene and spawn_item:
		Game.data[_flag] = _drop_pos
		_spawn(_drop_pos, true)
	_apply_result()
	used.emit()

func _spawn(pos: Vector2, animate: bool) -> void:
	var p = spawn_scene.instantiate()
	p.item = spawn_item
	p.world_scale = spawn_scale
	p.persistent_id = StringName("spawned/%s" % _flag)
	get_parent().add_child(p)
	p.global_position = pos
	if animate:
		p.global_position = pos + Vector2(0, 220)
		p.modulate.a = 0.0
		p.scale = Vector2(0.3, 0.3)
		var tw = p.create_tween().set_parallel(true)
		tw.tween_property(p, "global_position", pos, 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "scale", Vector2.ONE, 1.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 1.0, 0.8)

func _apply_result() -> void:
	if sprite and result_texture:
		sprite.texture = result_texture
		sprite.position = result_offset
		sprite.scale = result_scale
		sprite.visible = true
