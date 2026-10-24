extends Node

signal flag_set(id: StringName)

const FADE_TIME := 0.3

var flags := {}
var data := {}
var next_spawn_x := -1.0

var _fade: ColorRect
var _busy := false

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	layer.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_flag(id: StringName) -> void:
	if flags.get(id, false):
		return
	flags[id] = true
	flag_set.emit(id)

func has_flag(id: StringName) -> bool:
	return flags.get(id, false)

func go_to(scene_path: String, spawn_x := -1.0) -> void:
	if _busy:
		return
	_busy = true
	next_spawn_x = spawn_x
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, FADE_TIME)
	await tw.finished
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await get_tree().process_frame
	tw = create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, FADE_TIME)
	await tw.finished
	_busy = false
