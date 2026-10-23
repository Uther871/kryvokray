extends CanvasLayer

@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("idle")

func _process(_delta: float) -> void:
	sprite.position = get_viewport().get_mouse_position()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		sprite.stop()
		sprite.play("click")

func _on_animation_finished() -> void:
	sprite.play("idle")
