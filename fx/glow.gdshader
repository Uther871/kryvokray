shader_type canvas_item;

// Пульсуюче сяйво навколо силуету предмета.
// Текстура має мати порожні поля навколо іконки (pickup.gd додає їх сам).
uniform vec4 glow_color : source_color = vec4(1.0, 0.82, 0.35, 1.0);
uniform float strength : hint_range(0.0, 2.0) = 1.0;
uniform float pulse_speed = 2.5;

const vec2 DIRS[8] = vec2[8](
	vec2(1.0, 0.0), vec2(0.7071, 0.7071), vec2(0.0, 1.0), vec2(-0.7071, 0.7071),
	vec2(-1.0, 0.0), vec2(-0.7071, -0.7071), vec2(0.0, -1.0), vec2(0.7071, -0.7071)
);

void fragment() {
	float own = texture(TEXTURE, UV).a;
	float m = 0.0;
	for (int i = 0; i < 8; i++) {
		for (int s = 1; s <= 4; s++) {
			float r = float(s) * 1.75;
			float a = texture(TEXTURE, UV + DIRS[i] * TEXTURE_PIXEL_SIZE * r).a;
			m = max(m, a * (1.0 - float(s - 1) / 4.0));
		}
	}
	float pulse = 0.65 + 0.35 * sin(TIME * pulse_speed);
	COLOR = vec4(glow_color.rgb, m * (1.0 - own) * pulse * strength) * COLOR;
}
