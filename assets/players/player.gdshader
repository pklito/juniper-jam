shader_type canvas_item;

uniform vec2 _mouse_pos;
instance uniform bool _hovered;
uniform vec3 _hover_color : source_color = vec3(1.);

uniform float _hover_speed : hint_range(0.,10.) = 4.;
uniform float _hover_strength : hint_range(0.,1.) = 0.5;
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	float amount = _hover_strength * (sin(_hover_speed * TIME) + 1.)/2.;
	amount = mix(0., amount, float(_hovered));
	COLOR.rgb += amount * _hover_color;
	//COLOR.rgb = mix(COLOR.rgb, _hover_color, _hover_strength * (sin(_hover_speed * TIME) + 1.)/2. );
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
