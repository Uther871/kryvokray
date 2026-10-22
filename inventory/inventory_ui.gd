extends CanvasLayer

@export var test_item: ItemData

@onready var slots = $Bar/Margin/Slots

func _ready() -> void:
	slots.get_child(0).set_item(test_item)
