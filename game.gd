extends Node

signal flag_set(id: StringName)

var data := {}
var flags := {}
var next_spawn_x := -1.0

func set_flag(id: StringName) -> void:
	if flags.get(id, false):
		return
	flags[id] = true
	flag_set.emit(id)

func has_flag(id: StringName) -> bool:
	return flags.get(id, false)

func go_to(scene_path: String, spawn_x := -1.0) -> void:
	next_spawn_x = spawn_x
	get_tree().change_scene_to_file(scene_path)
