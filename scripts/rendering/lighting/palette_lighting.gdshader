shader_type canvas_item;

// ADR-026 lighting pass (TLF-083): a full-screen rect on CanvasLayer 1, above the world and under
// every UI layer. Each pixel is snapped to its TLF-CH01-32 index, then moved k steps down its own
// material ramp, k = clamp(ambient - lift, 0, 3), with lift = the strongest light covering the
// pixel. `shift_table[index * 4 + k]` is built by LightingPass.shift_table() (GDScript, tested); the
// light rules mirror LightingPass.lift_at(). Output is always a palette colour.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 palette[32];
uniform int shift_table[128];
uniform int ambient_steps = 2;
uniform vec2 view_size = vec2(960.0, 540.0);
uniform int light_count = 0;
uniform int light_kind[9];      // 0 ellipse, 1 quad
uniform vec4 light_a[9];        // ellipse: centre xy, radius xy; quad: p0 xy, p1 xy
uniform vec4 light_b[9];        // quad: p2 xy, p3 xy
uniform int light_lift_in[9];
uniform int light_lift_out[9];
uniform float light_inner[9];
uniform int light_mask[9];      // bit i: index i may be lifted; 0 = every index

float edge(vec2 a, vec2 b, vec2 p) {
	return (b.x - a.x) * (p.y - a.y) - (b.y - a.y) * (p.x - a.x);
}

bool in_quad(vec2 p, vec4 a, vec4 b) {
	float c0 = edge(a.xy, a.zw, p);
	float c1 = edge(a.zw, b.xy, p);
	float c2 = edge(b.xy, b.zw, p);
	float c3 = edge(b.zw, a.xy, p);
	return (c0 >= 0.0 && c1 >= 0.0 && c2 >= 0.0 && c3 >= 0.0)
		|| (c0 <= 0.0 && c1 <= 0.0 && c2 <= 0.0 && c3 <= 0.0);
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	int index = 0;
	float best = 1e9;
	for (int i = 0; i < 32; i++) {
		vec3 d = c - palette[i];
		float dd = dot(d, d);
		if (dd < best) {
			best = dd;
			index = i;
		}
	}
	vec2 p = floor(SCREEN_UV * view_size) + vec2(0.5);
	int lift = 0;
	for (int l = 0; l < 9; l++) {
		if (l >= light_count) {
			break;
		}
		int mask = light_mask[l];
		if (mask != 0 && ((mask >> index) & 1) == 0) {
			continue;
		}
		int v = 0;
		if (light_kind[l] == 0) {
			float d = length((p - light_a[l].xy) / light_a[l].zw);
			v = d < light_inner[l] ? light_lift_in[l] : (d < 1.0 ? light_lift_out[l] : 0);
		} else if (in_quad(p, light_a[l], light_b[l])) {
			v = light_lift_in[l];
		}
		lift = max(lift, v);
	}
	int k = clamp(ambient_steps - lift, 0, 3);
	COLOR = vec4(palette[shift_table[index * 4 + k]], 1.0);
}
