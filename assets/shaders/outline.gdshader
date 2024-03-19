shader_type spatial;
//render_mode unshaded;
//
//uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_nearest;
//uniform sampler2D normal_texture : source_color, hint_normal_roughness_texture, filter_nearest;
//uniform sampler2D depth_texture : source_color, hint_depth_texture, filter_nearest;
//
void vertex() {
	//POSITION = vec4(VERTEX, 1.0);
}
//
void fragment() {
	//vec3 original = texture(screen_texture, SCREEN_UV).rgb;
	//vec3 normal = texture(normal_texture, SCREEN_UV).rgb * 2.0 - 1.0;
	//ALBEDO = normal;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
