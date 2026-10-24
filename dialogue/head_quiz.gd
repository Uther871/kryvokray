extends RefCounted
## Права голова: ставить три запитання (пазл 3 з PDD).
## Хибна відповідь -> «Fuck off!» і гравця викидає з діалогу (треба клікнути на голову знову).

static func steps() -> Array:
	if Game.has_flag(&"gate_open"):
		return [{"who": "Head", "say": "Go on, then."}]
	if not Game.has_flag(&"head1_plugged"):
		# TODO: у PDD немає — заглушка, поки ліву голову не заткнули
		return [{"who": "Head", "say": "I can’t hear a thing over that babbling idiot!"}]
	var result: Array = [
		# TODO: вступна репліка вигадана як заглушка
		{"who": "Head", "say": "Finally, some quiet. Answer my three questions, and the gate will open."},
	]
	result += _question(
		"What belongs to you, but others use it more than you do?",
		["Your shadow", "Your name", "Your soul", "Your face"], 1,
		[{"who": "Head", "say": "Yes!"}])
	result += _question(
		"What gets bigger the more you take away from it?",
		["A hole", "A fire", "A mountain", "A shadow"], 0,
		[{"who": "Head", "say": "Yes!"}])
	result += _question(
		"What can you break without ever touching it?",
		["A bone", "A mirror", "A promise", "A chain"], 2,
		[{"who": "Head", "say": "Your welcome!"}, {"flag": "gate_open"}])
	return result

static func _question(text: String, options: Array, correct: int, right: Array) -> Array:
	return [
		{"who": "Head", "say": text},
		{
			"choice": options,
			"correct": correct,
			"right": right,
			"wrong": [{"who": "Head", "say": "Fuck off!"}],
			"retry": false,
		},
	]
