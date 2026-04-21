shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float outline_size = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float alpha = tex.a;

	float outline = 0.0;

	for (float x = -1.0; x <= 1.0; x++) {
		for (float y = -1.0; y <= 1.0; y++) {
			if (x == 0.0 && y == 0.0) continue;

			vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE * outline_size;
			float neighbor_alpha = texture(TEXTURE, UV + offset).a;

			if (neighbor_alpha > 0.0) {
				outline = 1.0;
			}
		}
	}

	if (alpha == 0.0 && outline > 0.0 && outline_size > 0.0) {
		COLOR = outline_color;
	} else {
		COLOR = tex;
	}
}