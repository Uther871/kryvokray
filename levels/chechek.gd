extends Node2D

@export var speed := 500.0
@export var min_x := 100.0
@export var max_x := 1750.0

@export_group("Качання")
@export var sway_angle_deg := 5.0
@export var sway_speed := 9.0
@export var bob_height := 0.6

@onready var sprite: Sprite2D = $Sprite2D

var target_x: float
var _t := 0.0
var _base_offset: Vector2
var _on_arrive := Callable()

func _ready() -> void:
	add_to_group("player")
	target_x = position.x
	_base_offset = sprite.offset

func walk_to(x: float, on_arrive: Callable = Callable(), stop_distance := 0.0) -> void:
	var dir := signf(x - position.x)
	target_x = clampf(x - dir * stop_distance, min_x, max_x)
	_on_arrive = on_arrive

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		walk_to(get_global_mouse_position().x)

func _process(delta: float) -> void:
	var dx := target_x - position.x
	if absf(dx) > 2.0:
		position.x += signf(dx) * minf(speed * delta, absf(dx))
		sprite.flip_h = dx < 0
		_t += delta * sway_speed
		sprite.rotation = sin(_t) * deg_to_rad(sway_angle_deg)
		sprite.offset = _base_offset + Vector2(0, -absf(sin(_t)) * bob_height)
	else:
		_t = 0.0
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, 12.0 * delta)
		sprite.offset = sprite.offset.lerp(_base_offset, 12.0 * delta)
		if _on_arrive.is_valid():
			var cb := _on_arrive
			_on_arrive = Callable()
			cb.call()
