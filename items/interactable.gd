extends Area2D

@export var required_item: ItemData

func use_item(item: ItemData) -> bool:
	if required_item == null or item.id != required_item.id:
		print("Не підходить")
		return false
	print("Підійшло!")
	
	return true
	
