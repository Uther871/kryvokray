extends PanelContainer

@onready var icon: TextureRect = $Icon
var item: ItemData
var _dragging := false

func set_item(new_item: ItemData) -> void:
	item = new_item
	icon.texture = item.icon if item else null

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null:
		return null
	_dragging = true
	var preview := TextureRect.new()
	preview.texture = item.icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(48, 48)
	set_drag_preview(preview)
	return item

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _dragging:
		_dragging = false
		_try_use_on_world()

func _try_use_on_world() -> void:
	var viewport := get_viewport()
	var screen_pos := viewport.get_mouse_position()
	var world_pos := viewport.get_canvas_transform().affine_inverse() * screen_pos

	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	query.collide_with_areas = true
	query.collide_with_bodies = false

	for hit in get_world_2d().direct_space_state.intersect_point(query):
		var target = hit.collider
		if target.has_method("use_item") and target.use_item(item):
			set_item(null)
			return
