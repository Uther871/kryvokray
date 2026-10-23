shader_type canvas_item;

// =====================================================================
//  OIL PAINT — повноекранний постпроцес для Godot 4.x (Forward+/Mobile/Compat)
//
//  Етапи:
//   1. Wobble      — легке "плавання" координат, щоб пікселі не були ідеальними сходинками
//   2. Flow field  — напрям мазка з structure tensor (по контурах) + шум (на пласких ділянках)
//   3. Kuwahara    — анізотропний фільтр: згладжує кольори в "мазки", тримаючи краї
//   4. Pigment     — варіація тону/кольору вздовж мазка
//   5. Impasto     — рельєф щетини -> нормаль -> освітлення (товстий шар фарби)
//   6. Canvas      — текстура полотна, віньєтка, колір-грейдинг
//
//  Текстури не потрібні, все процедурне. Мазки прив'язані до СВІТУ (через камеру),
//  тому не "пливуть" по екрану, коли камера їде.
// =====================================================================

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;

// Це виставляє oil_paint_layer.gd кожен кадр (не чіпайте руками)
uniform vec2 viewport_size = vec2(1920.0, 1080.0);
uniform vec2 cam_origin = vec2(0.0);
uniform float cam_zoom = 1.0;

group_uniforms general;
uniform float strength : hint_range(0.0, 1.0) = 1.0;

group_uniforms brush;
// Радіус мазка в пікселях. Головний важіль вартості: 3 = швидко, 6 = дуже "намазано".
uniform int radius : hint_range(2, 8) = 4;
// Наскільки мазок витягнутий уздовж напряму (1 = круглий, 3 = довгий).
uniform float elongation : hint_range(1.0, 4.0) = 2.0;
// Чіткість країв між мазками (більше = різкіше, менше = м'якше).
uniform float sharpness : hint_range(2.0, 16.0) = 8.0;
// Дрижання меж у пікселях і частота (менша частота = плавніші хвилі).
uniform float wobble_amount : hint_range(0.0, 8.0) = 2.5;
uniform float wobble_freq : hint_range(0.002, 0.1) = 0.02;

group_uniforms flow;
// Відстань вибірки градієнта (px) і рівень мипмапа: більше = глобальніші напрямки мазків.
uniform float flow_spread : hint_range(2.0, 16.0) = 6.0;
uniform float flow_lod : hint_range(0.0, 5.0) = 2.0;
// Вплив шумового поля на пласких ділянках (0 = мазки тільки вздовж контурів).
uniform float flow_noise : hint_range(0.0, 0.05) = 0.004;
uniform float flow_noise_scale : hint_range(0.0005, 0.02) = 0.003;

group_uniforms pigment;
uniform float bristle_length : hint_range(5.0, 150.0) = 36.0;
uniform float bristle_width : hint_range(1.0, 12.0) = 3.5;
// Варіація яскравості та відтінку між мазками.
uniform float paint_variation : hint_range(0.0, 0.5) = 0.12;
uniform float color_jitter : hint_range(0.0, 0.15) = 0.03;
// Темніші краї плям (ефект пігменту, що збирається по контуру).
uniform float edge_darkening : hint_range(0.0, 0.6) = 0.2;

group_uniforms impasto;
uniform float impasto_strength : hint_range(0.0, 2.0) = 0.9;
uniform float impasto_depth : hint_range(0.0, 10.0) = 3.0;
uniform vec3 light_dir = vec3(-0.5, -0.6, 0.7);
uniform float shininess : hint_range(2.0, 100.0) = 24.0;
uniform float spec_strength : hint_range(0.0, 1.0) = 0.12;
uniform vec3 light_color : source_color = vec3(1.0, 0.92, 0.8);

group_uniforms canvas;
uniform float canvas_strength : hint_range(0.0, 0.6) = 0.18;
uniform float canvas_size : hint_range(1.5, 8.0) = 3.0;
uniform float saturation : hint_range(0.0, 2.0) = 1.1;
uniform float contrast : hint_range(0.5, 1.5) = 1.05;
uniform float vignette : hint_range(0.0, 1.0) = 0.25;
group_uniforms;

// ---------------------------------------------------------------------
//  Шум
// ---------------------------------------------------------------------
float h21(vec2 p) {
	vec3 p3 = fract(vec3(p.x, p.y, p.x) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = h21(i);
	float b = h21(i + vec2(1.0, 0.0));
	float c = h21(i + vec2(0.0, 1.0));
	float d = h21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// ~0..0.875, середнє ~0.4375
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		a *= 0.5;
	}
	return v;
}

float lum_at(vec2 uv) {
	return dot(textureLod(screen_tex, uv, flow_lod).rgb, vec3(0.299, 0.587, 0.114));
}

// Щетина: витягнутий шум уздовж напрямку мазка (t) -> 0..1
float bristle(vec2 world, vec2 t, vec2 n) {
	vec2 q = vec2(dot(world, t), dot(world, n));
	float b1 = vnoise(vec2(q.x / bristle_length, q.y / bristle_width));
	float b2 = vnoise(vec2(q.x / (bristle_length * 0.5), q.y / (bristle_width * 0.4)) + vec2(5.3, 1.7));
	return b1 * 0.65 + b2 * 0.35;
}

// Переплетіння полотна 0..1 (1 = нитка, 0 = щілина)
float weave(vec2 p, float size) {
	vec2 g = p / size;
	vec2 f = fract(g);
	float over = mod(floor(g.x) + floor(g.y), 2.0);
	float th = sin(f.x * PI);
	if (over > 0.5) {
		th = sin(f.y * PI);
	}
	return th;
}

void fragment() {
	vec2 px = vec2(1.0) / viewport_size;
	vec2 screen_px = SCREEN_UV * viewport_size;
	vec2 world = (screen_px - cam_origin) / cam_zoom;

	vec3 original = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;

	// ---------- 1. Wobble ----------
	vec2 wob = (vec2(fbm(world * wobble_freq), fbm(world * wobble_freq + vec2(31.7, 17.3))) - vec2(0.4375)) * 2.0 * wobble_amount;
	vec2 suv = SCREEN_UV + wob * px;

	// ---------- 2. Flow field ----------
	vec3 Ji = vec3(0.0);
	float st = flow_spread;
	for (int iy = -1; iy <= 1; iy++) {
		for (int ix = -1; ix <= 1; ix++) {
			vec2 c = suv + vec2(float(ix), float(iy)) * st * px;
			float gx = lum_at(c + vec2(st, 0.0) * px) - lum_at(c - vec2(st, 0.0) * px);
			float gy = lum_at(c + vec2(0.0, st) * px) - lum_at(c - vec2(0.0, st) * px);
			Ji += vec3(gx * gx, gy * gy, gx * gy);
		}
	}
	Ji /= 9.0;
	float gmag = sqrt(Ji.x + Ji.y);

	float na = fbm(world * flow_noise_scale) * TAU * 1.5;
	vec2 ng = vec2(cos(na), sin(na));
	vec3 J = Ji + flow_noise * vec3(ng.x * ng.x, ng.y * ng.y, ng.x * ng.y);

	float ang = 0.5 * atan(2.0 * J.z, J.x - J.y + 0.00000001) + PI * 0.5;
	vec2 t = vec2(cos(ang), sin(ang));
	vec2 n = vec2(-t.y, t.x);

	// ---------- 3. Анізотропний Kuwahara (8 секторів) ----------
	vec3 sm[8];
	vec3 sq[8];
	float sw[8];
	vec3 c0 = textureLod(screen_tex, suv, 0.0).rgb;
	for (int i = 0; i < 8; i++) {
		sm[i] = c0;
		sq[i] = c0 * c0;
		sw[i] = 1.0;
	}

	float r = float(radius);
	float inv2s2 = 1.0 / (2.0 * (r * 0.5) * (r * 0.5));
	for (int v = -radius; v <= radius; v++) {
		for (int u = -radius; u <= radius; u++) {
			float d2 = float(u * u + v * v);
			if (d2 > r * r || d2 < 0.5) {
				continue;
			}
			vec2 off = (t * float(u) * elongation + n * float(v)) * px;
			vec3 c = textureLod(screen_tex, suv + off, 0.0).rgb;
			float w = exp(-d2 * inv2s2);
			float a = atan(float(v), float(u));
			int k = int(floor((a + PI) / (TAU / 8.0)));
			k = clamp(k, 0, 7);
			sm[k] += c * w;
			sq[k] += c * c * w;
			sw[k] += w;
		}
	}

	vec3 acc = vec3(0.0);
	float wacc = 0.0;
	for (int k = 0; k < 8; k++) {
		vec3 m = sm[k] / sw[k];
		vec3 vr = max(sq[k] / sw[k] - m * m, vec3(0.0));
		float s2 = (vr.r + vr.g + vr.b) / 3.0;
		float al = 1.0 / (1.0 + pow(s2 * 1000.0 + 0.000001, sharpness * 0.5));
		acc += m * al;
		wacc += al;
	}
	vec3 col = acc / max(wacc, 0.000001);

	// ---------- 4. Пігмент ----------
	float b = bristle(world, t, n);
	col *= 1.0 + (b - 0.5) * paint_variation * 2.0;
	vec2 jq = vec2(dot(world, t), dot(world, n)) / (bristle_length * 2.0);
	vec3 cj = vec3(fbm(jq), fbm(jq + vec2(7.7, 3.1)), fbm(jq + vec2(13.3, 21.9))) - vec3(0.4375);
	col += cj * color_jitter * 2.0;
	col *= 1.0 - edge_darkening * smoothstep(0.03, 0.25, gmag);

	// ---------- 5. Імпасто ----------
	float hC = bristle(world, t, n);
	float hX = bristle(world + vec2(1.0, 0.0), t, n);
	float hY = bristle(world + vec2(0.0, 1.0), t, n);
	vec3 nrm = normalize(vec3(-(hX - hC) * impasto_depth, -(hY - hC) * impasto_depth, 1.0));
	vec3 Ln = normalize(light_dir);
	float shade = dot(nrm, Ln) - Ln.z;
	col *= 1.0 + shade * impasto_strength;
	vec3 H = normalize(Ln + vec3(0.0, 0.0, 1.0));
	float sp = max(pow(max(dot(nrm, H), 0.0), shininess) - pow(H.z, shininess), 0.0);
	col += light_color * sp * spec_strength;

	// ---------- 6. Полотно і грейдинг ----------
	float wv = weave(world, canvas_size);
	float grain = h21(floor(world)) - 0.5;
	col *= 1.0 - canvas_strength * (1.0 - wv) + grain * canvas_strength * 0.3;

	float l = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(l), col, saturation);
	col = (col - vec3(0.5)) * contrast + vec3(0.5);

	float vd = distance(SCREEN_UV, vec2(0.5)) * 1.4142;
	col *= 1.0 - vignette * smoothstep(0.45, 1.0, vd);

	col = clamp(col, vec3(0.0), vec3(1.0));
	COLOR = vec4(mix(original, col, strength), 1.0);
}
