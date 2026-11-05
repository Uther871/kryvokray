extends Area2D
## Двері казино. Поки що неробочі: Грець підходить і каже, що зачинено.
## Коли мініігра буде готова, замінити _on_arrive на перехід у сцену казино.

@export var message := "Closed for now."
@export var stop_distance := 150.0

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.walk_to(global_position.x, _on_arrive, stop_distance)
		else:
			_on_arrive()

func _on_arrive() -> void:
	Game.say(message)
