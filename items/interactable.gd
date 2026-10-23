extends Area2D

signal used

@export var required_item: ItemData
@export var stop_distance := 150.0
@export var result_texture: Texture2D  # що показати після використання

var _done := false

func use_item(item: ItemData) -> bool:
	if _done or required_item == null or item.id != required_item.id:
		print("Не підходить")
		return false
	_done = true
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.walk_to(global_position.x, _on_used, stop_distance)
	else:
		_on_used()
	return true

func _on_used() -> void:
	print("Підійшло!")
	if result_texture:
		$Sprite2D.texture = result_texture
	used.emit()
