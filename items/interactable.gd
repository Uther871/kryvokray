extends Area2D

signal used

@export var required_item: ItemData
@export var stop_distance := 150.0
@export var result_texture: Texture2D
@export var sets_flag: StringName = &""
@export var invisible_zone := false
@export var spawn_scene: PackedScene
@export var spawn_item: ItemData
@export var highlight_target: CanvasItem
@export var hover_strength := 1.35

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

var _done := false
var _flag: StringName
var _drop_pos := Vector2.ZERO

func _ready() -> void:
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

func use_item(item: ItemData) -> bool:
	if _done or required_item == null or item.id != required_item.id:
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
	p.persistent_id = StringName("spawned/%s" % _flag)
	get_parent().add_child(p)
	p.global_position = pos
	if animate:
		p.global_position = pos + Vector2(0, 40)
		p.modulate.a = 0.0
		var tw = p.create_tween().set_parallel(true)
		tw.tween_property(p, "global_position", pos, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 1.0, 0.6)

func _apply_result() -> void:
	if sprite and result_texture:
		sprite.texture = result_texture
		sprite.visible = true
