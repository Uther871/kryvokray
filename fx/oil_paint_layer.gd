extends CanvasLayer
## Повноекранний ефект "картина маслом".
## Передає в шейдер позицію камери, щоб мазки були прив'язані до світу, а не до екрана.
## F9 — увімкнути/вимкнути ефект (зручно порівнювати "до/після").

## Шар інвентаря. Має бути вищим за шар ефекту, щоб UI лишався чітким.
@export var ui_layer: int = 10
@export var toggle_key: Key = KEY_F9

@onready var _rect: ColorRect = $Rect
var _mat: ShaderMaterial


func _ready() -> void:
	_mat = _rect.material as ShaderMaterial
	var inv := get_node_or_null("/root/Inventory")
	if inv is CanvasLayer:
		(inv as CanvasLayer).layer = ui_layer


func _process(_delta: float) -> void:
	var vp := get_viewport()
	var ct := vp.get_canvas_transform()
	_mat.set_shader_parameter("viewport_size", vp.get_visible_rect().size)
	_mat.set_shader_parameter("cam_origin", ct.origin)
	_mat.set_shader_parameter("cam_zoom", ct.x.x)


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == toggle_key:
		_rect.visible = not _rect.visible
