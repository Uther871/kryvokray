extends Area2D

@export var item: ItemData
@export var stop_distance := 150.0

func _ready() -> void:
	$Sprite2D.texture = item.icon

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.walk_to(global_position.x, _pick_up, stop_distance)
		else:
			_pick_up()

func _pick_up() -> void:
	if Inventory.add_item(item):
		queue_free()
		
