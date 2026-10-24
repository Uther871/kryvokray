shader_type canvas_item;
render_mode unshaded;

// Піксельний пар: клаптики туману, що піднімаються від землі й дрейфують убік.
// Дві шумові текстури рухаються з різною швидкістю — звідси глибина.
uniform sampler2D noise_a : repeat_enable, filter_linear;
uniform sampler2D noise_b : repeat_enable, filter_linear;
uniform vec4 steam_color : source_color = vec4(0.86, 0.46, 0.52, 1.0);
uniform float density : hint_range(0.0, 1.0) = 0.5;        // загальна густина
uniform float rise_speed = 0.025;                           // швидкість підйому
uniform float drift_speed = 0.012;                          // бічний дрейф
uniform float scale_a = 2.0;                                // розмір великих клаптиків
uniform float scale_b = 3.6;                                // розмір дрібних
uniform float floor_line : hint_range(0.0, 1.0) = 0.8;      // де «земля» (частка висоти екрана)
uniform float height : hint_range(0.05, 1.0) = 0.6;         // на яку висоту піднімається пар
uniform float cut_low : hint_range(0.0, 1.0) = 0.5;         // поріг появи клаптиків
uniform float cut_high : hint_range(0.0, 1.0) = 0.9;
uniform int steps : hint_range(2, 8) = 4;                   // скільки рівнів прозорості (піксельний вигляд)
uniform vec2 grid = vec2(320.0, 180.0);                     // розмір «пікселя» пару: 1920/320 = 6 px

void fragment() {
	vec2 uv = floor(UV * grid) / grid;
	vec2 pa = vec2(uv.x * scale_a * 1.78 + TIME * drift_speed, uv.y * scale_a + TIME * rise_speed);
	vec2 pb = vec2(uv.x * scale_b * 1.78 - TIME * drift_speed * 1.7, uv.y * scale_b + TIME * rise_speed * 1.6);
	float n = texture(noise_a, pa).r * 0.6 + texture(noise_b, pb).r * 0.4;

	// Біля землі густо, вгорі розсіюється
	float t = clamp((uv.y - (floor_line - height)) / height, 0.0, 1.0);
	float mask = smoothstep(0.0, 1.0, t);
	mask *= 1.0 - 0.35 * smoothstep(floor_line, 1.0, uv.y);

	float a = smoothstep(cut_low, cut_high, n) * mask * density;
	a = floor(a * float(steps)) / float(steps);
	COLOR = vec4(steam_color.rgb, a * steam_color.a);
}
