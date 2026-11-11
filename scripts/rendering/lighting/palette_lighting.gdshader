shader_type canvas_item;

// ADR-026 lighting pass (TLF-083): a full-screen rect on CanvasLayer 1, above the world and under
// every UI layer. Each pixel is snapped to its TLF-CH01-32 index, then moved k steps down its own
// material ramp, k = clamp(ambient - lift, 0, 3), with lift = the strongest light covering the
// pixel. `shift_table[index * 4 + k]` is built by LightingPass.shift_table() (GDScript, tested); the
// light rules mirror LightingPass.lift_at(). Output is always a palette colour.
// ADR-027 (TLF-084): floor receivers (bit mask, indices 00-05) also take the room's floor fill
// (fill_mode 0 ADD: lift = max(Elias zone, room lights + fill); 1 CLEAR: lift = max(lights, fill)
// except inside `fill_clear` x the outer radius of a room pool that lifts them) and the shade term
// (extra ramp steps) from the room's baked shade map plus Elias's contact ellipse. Shade never
// touches a pixel an information region restores (the region's lift is >= the fill).
// k = clamp(A - lift + shade, 0, 3): mirrors LightingPass.output_index().

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
uniform int room_light_count = 0;  // slots below this are room lights (they clear the fill); the Elias zone follows
uniform int receivers = 63;        // bit i: index i takes the fill and shade
uniform int fill_lift = 0;
uniform int fill_mode = 0;         // 0 ADD, 1 CLEAR (RoomLighting.FillMode)
uniform float fill_clear = 1.5;
uniform int shade_on = 0;
uniform sampler2D shade_map : filter_nearest;
uniform vec4 shade_rect = vec4(0.0, 0.0, 1.0, 1.0);  // screen xy of texel (0,0); screen px per texel
uniform ivec2 shade_size = ivec2(0);
uniform vec4 actor_shade = vec4(-9999.0, -9999.0, 1.0, 1.0);  // Elias contact: screen centre, radius

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
	int room_lift = 0;
	bool info = false;
	bool clear = false;
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
			clear = clear || (l < room_light_count && d < fill_clear);
		} else if (in_quad(p, light_a[l], light_b[l])) {
			v = light_lift_in[l];
			info = info || mask != 0;
		}
		lift = max(lift, v);
		if (l < room_light_count) {
			room_lift = max(room_lift, v);
		}
	}
	int shade = 0;
	bool receiver = ((receivers >> index) & 1) == 1;
	if (receiver && fill_lift > 0) {
		if (fill_mode == 0) {
			lift = max(lift, room_lift + fill_lift);
		} else if (!clear) {
			lift = max(lift, fill_lift);
		}
	}
	if (receiver && !info) {
		if (shade_on == 1) {
			ivec2 t = ivec2(floor((p - shade_rect.xy) / shade_rect.zw));
			if (t.x >= 0 && t.y >= 0 && t.x < shade_size.x && t.y < shade_size.y) {
				shade = int(round(texelFetch(shade_map, t, 0).r * 255.0));
			}
			if (length((p - actor_shade.xy) / actor_shade.zw) < 1.0) {
				shade = max(shade, 1);
			}
		}
	}
	int k = clamp(ambient_steps - lift + shade, 0, 3);
	COLOR = vec4(palette[shift_table[index * 4 + k]], 1.0);
}
