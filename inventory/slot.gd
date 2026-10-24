extends PanelContainer

const GLOW_COLOR := Color(1.0, 0.82, 0.35)

@onready var icon: TextureRect = $Icon
var item: ItemData
var _dragging := false
var _glow_style: StyleBoxFlat
var _pulse: Tween

func _ready() -> void:
	var base := get_theme_stylebox("panel")
	if base is StyleBoxFlat:
		_glow_style = base.duplicate()
		_glow_style.bg_color = _glow_style.bg_color.lightened(0.12)
		_glow_style.set_border_width_all(2)
		_glow_style.border_color = GLOW_COLOR
		_glow_style.shadow_color = Color(GLOW_COLOR, 0.6)
		_glow_style.shadow_size = 10
		_glow_style.shadow_offset = Vector2.ZERO
	_update_glow()

func set_item(new_item: ItemData) -> void:
	item = new_item
	icon.texture = item.icon if item else null
	_update_glow()

func _update_glow() -> void:
	if _glow_style == null:
		return
	if _pulse:
		_pulse.kill()
		_pulse = null
	if item:
		add_theme_stylebox_override("panel", _glow_style)
		_pulse = create_tween().set_loops()
		_pulse.tween_property(_glow_style, "shadow_color:a", 0.25, 0.9).set_trans(Tween.TRANS_SINE)
		_pulse.tween_property(_glow_style, "shadow_color:a", 0.7, 0.9).set_trans(Tween.TRANS_SINE)
	else:
		remove_theme_stylebox_override("panel")

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null:
		return null
	_dragging = true
	HoverFX.drag_item = item
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
		HoverFX.drag_item = null
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
