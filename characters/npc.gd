extends Area2D
## Персонаж, з яким можна говорити (клік -> Чечек підходить -> діалог).
## Після діалогу, якщо стоїть ally_flag, перетворюється на компаньйона і ходить за Чечеком.

const DialogueUI = preload("res://dialogue/dialogue_ui.gd")

## Скрипт із функцією static steps() -> Array (див. dialogue/grets_riddle.gd)
@export var dialogue: Script
@export var stop_distance := 220.0
## Прапорець, який ставить діалог, коли персонаж стає союзником
@export var ally_flag: StringName = &""
## Ключ для реплік Чечека при спробі використати на ньому предмет (replies.gd)
@export var reply_key: StringName = &""
@export var follow_offset := 170.0
@export var follow_speed := 5.0

@onready var sprite: Sprite2D = $Sprite2D

var _talking := false
var _ally := false

func _ready() -> void:
	if ally_flag != &"" and Game.has_flag(ally_flag):
		_become_ally(true)
	else:
		HoverFX.register(self, sprite)

func _input_event(_viewport, event, _shape_idx) -> void:
	if _ally or _talking:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.walk_to(global_position.x, _talk, stop_distance)
		else:
			_talk()

## Предмети на персонажа не діють (Чечек відповість загальною реплікою)
func use_item(_item: ItemData) -> bool:
	return false

func _talk() -> void:
	if _talking or dialogue == null:
		return
	_talking = true
	var player = get_tree().get_first_node_in_group("player")
	if player:
		sprite.flip_h = player.global_position.x < global_position.x
	var ui = DialogueUI.new()
	add_child(ui)
	await ui.play(dialogue.call("steps"))
	_talking = false
	if ally_flag != &"" and Game.has_flag(ally_flag):
		_become_ally(false)

func _become_ally(snap: bool) -> void:
	_ally = true
	input_pickable = false
	HoverFX.unregister(self)
	if snap:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			global_position.x = player.global_position.x - follow_offset

func _process(delta: float) -> void:
	if not _ally:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var target_x: float = player.global_position.x - follow_offset
	var dx := target_x - global_position.x
	global_position.x += dx * clampf(follow_speed * delta, 0.0, 1.0)
	if absf(dx) > 4.0:
		sprite.flip_h = dx < 0.0
