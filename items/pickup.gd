@tool
extends Area2D

@export var item: ItemData:
	set(value):
		item = value
		if is_node_ready():
			_update_sprite()
@export var world_scale := 4.0:
	set(value):
		world_scale = value
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
	var s := get_node_or_null("Sprite2D") as Sprite2D
	if s == null:
		return
	s.scale = Vector2.ONE * world_scale
	if item == null or item.icon == null:
		return
	s.texture = item.icon
	# Зона кліку підганяється під справжні (непрозорі) пікселі іконки
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var img := item.icon.get_image()
	if cs == null or img == null:
		return
	var r := img.get_used_rect()
	if r.size == Vector2i.ZERO:
		return
	var rect := RectangleShape2D.new()
	rect.size = Vector2(r.size) * world_scale + Vector2(32, 32)
	cs.shape = rect
	cs.position = (Vector2(r.position) + Vector2(r.size) / 2.0 - Vector2(img.get_size()) / 2.0) * world_scale

func _on_flag_set(id: StringName) -> void:
	if id == requires_flag:
		_set_active(true)

func _set_active(on: bool) -> void:
	visible = on
	input_pickable = on

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[pickup ", name, "] клік, предмет: ", item.id if item else "НЕМАЄ")
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.walk_to(global_position.x, _pick_up, stop_distance)
		else:
			_pick_up()

func _pick_up() -> void:
	var ok: bool = Inventory.add_item(item)
	print("[pickup ", name, "] додано в інвентар: ", ok)
	if ok:
		Game.set_flag(_flag)
		queue_free()
	else:
		push_warning("Інвентар повний: %s лишається на місці" % item.id)
