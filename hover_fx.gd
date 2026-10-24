extends Node

const FADE_TIME := 0.12

var _entries := {}
var _hovered := {}

func register(area: Area2D, target: CanvasItem, strength := 1.35) -> void:
	if area == null or target == null:
		return
	_entries[area] = {"target": target, "base": target.modulate, "strength": strength, "tween": null}
	area.tree_exiting.connect(func(): unregister(area, false))

func unregister(area: Area2D, restore := true) -> void:
	if not _entries.has(area):
		return
	if restore and _hovered.has(area):
		_fade(area, false)
	_entries.erase(area)
	_hovered.erase(area)

func _physics_process(_delta: float) -> void:
	if _entries.is_empty():
		return
	var viewport := get_viewport()
	var query := PhysicsPointQueryParameters2D.new()
	query.position = viewport.get_canvas_transform().affine_inverse() * viewport.get_mouse_position()
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var now := {}
	for hit in viewport.world_2d.direct_space_state.intersect_point(query, 32):
		if _entries.has(hit.collider):
			now[hit.collider] = true
	for area in now:
		if not _hovered.has(area):
			_fade(area, true)
	for area in _hovered.keys():
		if not now.has(area):
			_fade(area, false)
	_hovered = now

func _fade(area: Area2D, on: bool) -> void:
	var e: Dictionary = _entries[area]
	var target: CanvasItem = e["target"]
	if not is_instance_valid(target):
		return
	if e["tween"] != null and e["tween"].is_valid():
		e["tween"].kill()
	var base: Color = e["base"]
	var s: float = e["strength"]
	var color := Color(base.r * s, base.g * s, base.b * s, base.a) if on else base
	e["tween"] = target.create_tween()
	e["tween"].tween_property(target, "modulate", color, FADE_TIME)
