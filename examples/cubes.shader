vec3 a_position  : POSITION;
vec4 a_color0    : COLOR0;

#include "common.sh"

void vertex()
{
	gl_Position = mul(u_modelViewProj, vec4(a_position, 1.0) );
	v_color0 = a_color0;
}

vec4 v_color0 : COLOR0    = vec4(1.0, 0.0, 0.0, 1.0);

void fragment()
{
	gl_FragColor = v_color0;   
}
