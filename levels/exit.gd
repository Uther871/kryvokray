extends Area2D

@export_file("*.tscn") var target_scene := ""
@export var spawn_x := -1.0
@export var stop_distance := 0.0
@export var requires_flag: StringName = &""

func _ready() -> void:
	if requires_flag != &"" and not Game.has_flag(requires_flag):
		_set_active(false)
		Game.flag_set.connect(_on_flag_set)

func _on_flag_set(id: StringName) -> void:
	if id == requires_flag:
		_set_active(true)

func _set_active(on: bool) -> void:
	visible = on
	input_pickable = on

func _input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.walk_to(global_position.x, _go, stop_distance)
		else:
			_go()

func _go() -> void:
	if target_scene != "":
		Game.go_to(target_scene, spawn_x)
