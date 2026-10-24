shader_type canvas_item;

// Річка «в глибину»: вгорі далеко (вужча, темніша), внизу близько (ширша, світліша).
uniform float far_width : hint_range(0.2, 1.0) = 0.55;   // ширина річки вгорі відносно низу
uniform float far_fog : hint_range(0.0, 1.0) = 0.55;     // наскільки темніє вдалині
uniform vec4 fog_color : source_color = vec4(0.12, 0.01, 0.02, 1.0);
uniform float flow_speed = 1.6;                          // швидкість течії
uniform float ripple_strength : hint_range(0.0, 0.6) = 0.22;
uniform float bank_shade : hint_range(0.0, 1.0) = 0.45;  // затемнення біля берегів

void fragment() {
	float v = UV.y;                                      // 0 вгорі, 1 внизу
	float depth = mix(far_width, 1.0, pow(v, 0.8));      // масштаб за перспективою
	float src_u = (UV.x - 0.5) / depth + 0.5;
	if (src_u < 0.0 || src_u > 1.0) {
		COLOR = vec4(0.0);
	} else {
		vec4 tex = texture(TEXTURE, vec2(src_u, v));
		// Хвилі: смуги, що біжать до глядача, ближче — ширші
		float z = 1.0 / mix(0.25, 1.0, v);
		float wave = sin(z * 14.0 - TIME * flow_speed) * 0.5 + 0.5;
		wave *= sin(src_u * 9.0 + z * 3.0 - TIME * 0.6) * 0.5 + 0.5;
		vec3 col = tex.rgb * (1.0 + (wave - 0.35) * ripple_strength);
		// Береги затемнені — видно, що русло заглиблене
		float edge = abs(src_u - 0.5) * 2.0;
		col *= 1.0 - bank_shade * smoothstep(0.55, 1.0, edge);
		// Туман дальнього плану
		col = mix(col, fog_color.rgb, far_fog * (1.0 - v) * (1.0 - v));
		COLOR = vec4(col, tex.a) * COLOR;
	}
}
