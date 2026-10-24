extends RefCounted
## Репліки Чечека, коли предмет використано неправильно.
## Підключається через const Replies = preload("res://replies.gd")

# Предмет не підходить до об'єкта (загальні)
const GENERAL: Array[String] = [
	"Nope. Not even close.",
	"Nah, that ain’t gonna work.",
	"That’s not gonna help here.",
	"Not even gonna try.",
	"Hmm… nah.",
	"That’s not how this works.",
]

# Особливі репліки: ключ "id_предмета@reply_key_об'єкта"
const SPECIFIC := {
	"shovel@river": [
		"Digging water? Seriously?",
		"You can’t bury a river.",
		"It’s wet. The shovel would be too.",
	],
	"plank@swamp": [
		"It’ll just sink.",
		"The swamp’ll swallow it whole.",
		"Just leave it here? Nah.",
	],
}

# Предмет відпустили на порожнє місце або стіну
const EMPTY: Array[String] = [
	"There’s nothing here.",
	"Who am I even talking to?",
	"Walls don’t talk back.",
	"What does a wall need this for?",
]

# Та сама помилка підряд: по зростанню (остання лишається на 5-й і далі спробі)
const REPEAT: Array[String] = [
	"Again? Alright, then…",
	"Told you that wouldn’t work.",
	"That’s twice now…",
	"You’re stubborn. So am I.",
]

# Об'єкт уже використаний
const USED: Array[String] = [
	"Nothing left to do here.",
	"Once was enough.",
]

static var _last_key := ""
static var _count := 0
static var _last_line := ""

## Викликати після вдалого використання предмета або при зміні кімнати.
static func reset() -> void:
	_last_key = ""
	_count = 0

## kind: "empty" (порожнє місце) або "target" (об'єкт, якому предмет не підійшов).
static func pick(item_id: String, target_key: String, kind: String, used := false) -> String:
	var key := "%s|%s|%s" % [item_id, target_key, kind]
	if key == _last_key:
		_count += 1
	else:
		_last_key = key
		_count = 1
	var line: String
	if _count >= 2:
		line = REPEAT[mini(_count - 2, REPEAT.size() - 1)]
	else:
		line = _random(_pool(item_id, target_key, kind, used))
	_last_line = line
	return line

static func _pool(item_id: String, target_key: String, kind: String, used: bool) -> Array:
	if kind == "empty":
		return EMPTY
	var special_key := "%s@%s" % [item_id, target_key]
	if SPECIFIC.has(special_key):
		return SPECIFIC[special_key]
	if used:
		return USED
	return GENERAL

static func _random(pool: Array) -> String:
	var options := pool.filter(func(l): return l != _last_line)
	if options.is_empty():
		options = pool
	return options.pick_random()
