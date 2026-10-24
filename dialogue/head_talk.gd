extends RefCounted
## Ліва голова на брамі (та, що з відкритим ротом): базікає, поки їй не заткнуть рота камінцем.

static func steps() -> Array:
	if Game.has_flag(&"head1_plugged"):
		return [{"who": "Head", "say": "Mmmph! Mmmmph!!"}]
	# TODO: у PDD сказано лише «кожна щось каже» — репліки вигадані як заглушки
	return [
		{"who": "Head", "say": "Halt! Nobody passes the gate of Raphael!"},
		{"who": "Head", "say": "Go away, little man! Blah blah blah blah blah!"},
	]
