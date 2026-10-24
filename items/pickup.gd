@tool
extends Area2D

@export var item: ItemData:
	set(value):
		item = value
		if is_node_ready():
			_update_sprite()
@export var stop_distance := 150.0
@export var requires_flag: StringName = &""
@export var persistent_id: StringName = &""

var _flag: StringName

func _ready() -> void:
	_update_sprite()
	if Engine.is_editor_hint():
		return
	if persistent_id != &"":
		_flag = persistent_id
	else:
		var scene_path := owner.scene_file_path if owner else ""
		_flag = StringName("picked/%s/%s" % [scene_path, name])
	if Game.has_flag(_flag):
		queue_free()
		return
	if requires_flag != &"" and not Game.has_flag(requires_flag):
		_set_active(false)
		Game.flag_set.connect(_on_flag_set)
	HoverFX.register(self, get_node_or_null("Sprite2D"))

func _update_sprite() -> void:
	var s := get_node_or_null("Sprite2D")
	if s and item:
		s.texture = item.icon

func _on_flag_set(id: StringName) -> void:
	if id == requires_flag:
		_set_active(true)

func _set_active(on: bool) -> void:
	visible = on
	input_pickable = on

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.walk_to(global_position.x, _pick_up, stop_distance)
		else:
			_pick_up()

func _pick_up() -> void:
	if Inventory.add_item(item):
		Game.set_flag(_flag)
		queue_free()
