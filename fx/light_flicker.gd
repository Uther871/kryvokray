extends PointLight2D
## Джерело світла, що ледь мерехтить (вогонь, вікно, світіння річки).

@export var flicker := 0.1      # сила мерехтіння (0 = рівне світло)
@export var speed := 6.0

var _base := 1.0
var _phase := 0.0

func _ready() -> void:
	_base = energy
	_phase = randf() * 100.0

func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 * speed + _phase
	energy = _base * (1.0 + flicker * (sin(t) * 0.5 + sin(t * 2.7) * 0.3 + sin(t * 5.3) * 0.2))
