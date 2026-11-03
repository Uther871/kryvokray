extends RefCounted
## Entry dialogue for Scene 4's quest chain.

static func steps() -> Array:
	return [
		{"who": "Guard", "say": "Halt! Where do you think you're going?"},
		{"who": "Grets", "say": "I need to get into the dungeon. My friend is locked up there."},
		{"who": "Guard", "say": "And I need a new pair of boots. Doesn't mean I'm getting one today."},
		{"who": "Grets", "say": "What do you want?"},
		{"who": "Guard", "say": "A bouquet. Fresh flowers. Bring me one, and I'll let you pass."},
		{"who": "Grets", "say": "Flowers? Where am I supposed to find those?"},
		{"who": "Guard", "say": "Try the little shop near the casino. The florist there sells all sorts of things. Keep your voice down, though."},
		{"who": "Grets", "say": "Why? What's so special about flowers?"},
		{"who": "Guard", "say": "That's none of your business. Bring me the bouquet, and I'll let you through."},
		{"flag": "guard_asked"}
	]
