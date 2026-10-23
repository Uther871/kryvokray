extends Area2D

signal used

@export var required_item: ItemData
@export var stop_distance := 150.0

func use_item(item: ItemData) -> bool:
	if required_item == null or item.id != required_item.id:
		print("Пішов нахуй")
		return false
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.walk_to(global_position.x, _on_used, stop_distance)
	else:
		_on_used()
	return true

func _on_used() -> void:
	print("Заєбісь")
	used.emit()
