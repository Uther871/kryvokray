extends RefCounted
## Діалог-загадка Греця (пазл 2 з PDD).
## Репліки взято з PDD. Позначені TODO — місця, яких у PDD ще немає.

const ALLY_FLAG := &"grets_ally"

static func steps() -> Array:
	return [
		{"who": "Chechek", "say": "Aaaaaa!!!"},
		{"who": "Grets", "say": "Don’t be afraid, I’m not angry!"},
		{"who": "Chechek", "say": "You fucking bitch, I’m gonna beat the shit out of you right now!"},
		{"who": "Grets", "say": "No, I just want to help you, but if you can solve my riddle!!!"},
		{"who": "Chechek", "say": "Oh, all right, go ahead and tell your riddle."},
		{"who": "Grets", "say": "There was once a father. He had three sons, but the devils took one of them. The father came to the gates of Hell and asked for his child back."},
		{"who": "Grets", "say": "And they said to him, “We’ll give him back if you can prove that you know your son better than we do.”"},
		{"who": "Grets", "say": "Tell me, man: what can a father give his son that even the devil cannot take away?"},
		{
			"choice": ["Life.", "Love.", "A name.", "A soul."],
			"correct": 2,
			"right": [
				# TODO: реакція Греця на правильну відповідь (у PDD немає)
				{"who": "Grets", "say": "A name. Yes… that’s right. I’ll go with you, man."},
				{"flag": "grets_ally"},
			],
			"wrong": [
				# TODO: реакція на хибну відповідь (у PDD немає). Зараз просто даємо спробувати ще раз.
				{"who": "Grets", "say": "Wrong! Think again, man."},
			],
		},
	]
