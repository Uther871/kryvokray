extends Node2D
## Рівень 3: брама палацу Рафаеля. Коли стоїть прапорець gate_open, замкнена брама
## змінюється на відчинену, голови зникають, з'являється вихід.

@onready var gate_closed: Sprite2D = $GateClosed
@onready var gate_open: Sprite2D = $GateOpen

func _ready() -> void:
	# На старті видно лише замкнену браму, незалежно від того, що ввімкнено в редакторі
	gate_closed.visible = true
	gate_open.visible = false
	if Game.has_flag(&"gate_open"):
		_open(true)
	else:
		Game.flag_set.connect(_on_flag_set)

func _on_flag_set(id: StringName) -> void:
	if id == &"gate_open":
		_open(false)

func _open(instant: bool) -> void:
	for head in get_tree().get_nodes_in_group("gate_heads"):
		head.disable()
	gate_open.visible = true
	if instant:
		gate_closed.visible = false
		return
	gate_open.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(gate_open, "modulate:a", 1.0, 0.9)
	tw.tween_property(gate_closed, "modulate:a", 0.0, 0.9)
	tw.chain().tween_callback(func(): gate_closed.visible = false)
