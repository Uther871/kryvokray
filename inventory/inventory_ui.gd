extends CanvasLayer

@onready var slots = $Bar/Margin/Slots

func add_item(item: ItemData) -> bool:
	for slot in slots.get_children():
		if slot.item == null:
			slot.set_item(item)
			return true
	return false
