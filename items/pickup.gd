extends Area2D

@export var item: ItemData

func _ready() -> void:
	$Sprite2D.texture = item.icon

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Inventory.add_item(item):
			queue_free()
