extends Node2D
## Керований Грець для Сцени 4. Рух такий самий, як у Чечека,
## але без копіювання залежностей попередніх рівнів.

@export var speed := 500.0
@export var min_x := 120.0
@export var max_x := 1780.0

@onready var sprite: Sprite2D = $Sprite2D

var target_x := 0.0
var _on_arrive := Callable()

func _ready() -> void:
	add_to_group("player")
	if Game.next_spawn_x >= 0.0:
		position.x = Game.next_spawn_x
		Game.next_spawn_x = -1.0
	target_x = position.x

func walk_to(x: float, on_arrive: Callable = Callable(), stop_distance := 0.0) -> void:
	var dx := x - position.x
	if absf(dx) <= stop_distance:
		target_x = position.x
	else:
		target_x = clampf(x - signf(dx) * stop_distance, min_x, max_x)
	_on_arrive = on_arrive

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		walk_to(get_global_mouse_position().x)

func _process(delta: float) -> void:
	var dx := target_x - position.x
	if absf(dx) > 2.0:
		position.x += signf(dx) * minf(speed * delta, absf(dx))
		sprite.flip_h = dx < 0.0
		return
	if _on_arrive.is_valid():
		var callback := _on_arrive
		_on_arrive = Callable()
		callback.call()
