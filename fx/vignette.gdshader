shader_type canvas_item;
render_mode unshaded;

// Віньєтка: темні краї екрана. Піксельна — кілька смуг затемнення великими блоками.
uniform vec4 tint : source_color = vec4(0.04, 0.0, 0.02, 1.0);  // колір затемнення (майже чорно-бордовий)
uniform float strength : hint_range(0.0, 1.0) = 0.65;           // наскільки темні краї
uniform float radius : hint_range(0.0, 1.5) = 0.7;              // де починається затемнення (0 = центр, 1 = середини країв)
uniform float softness : hint_range(0.05, 1.5) = 0.7;           // ширина плавного переходу
uniform int bands : hint_range(2, 16) = 7;                      // скільки смуг (піксельний вигляд)
uniform vec2 grid = vec2(320.0, 180.0);                         // розмір блоку: 1920/320 = 6 px

void fragment() {
	vec2 uv = floor(UV * grid) / grid;
	float d = length((uv - 0.5) * 2.0);
	float v = smoothstep(radius, radius + softness, d);
	v = floor(v * float(bands) + 0.5) / float(bands);
	COLOR = vec4(tint.rgb, v * strength);
}
