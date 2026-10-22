extends PanelContainer

@onready var icon: TextureRect = $Icon
var item: ItemData

func set_item(new_item: ItemData) -> void:
	item = new_item
	icon.texture = item.icon if item else null
