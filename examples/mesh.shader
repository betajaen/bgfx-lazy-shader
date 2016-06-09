vec4 v_color0    : COLOR0    = vec4(1.0, 0.0, 0.0, 1.0);
vec3 v_normal    : NORMAL    = vec3(0.0, 0.0, 1.0);
vec2 v_texcoord0 : TEXCOORD0 = vec2(0.0, 0.0);
vec3 v_pos       : TEXCOORD1 = vec3(0.0, 0.0, 0.0);
vec3 v_view      : TEXCOORD2 = vec3(0.0, 0.0, 0.0);

vec3 a_position  : POSITION;
vec4 a_color0    : COLOR0;
vec2 a_texcoord0 : TEXCOORD0;
vec3 a_normal    : NORMAL;

#include "common.sh"

uniform vec4 u_time;

void vertex()
{
	vec3 pos = a_position;

	float sx = sin(pos.x*32.0+u_time.x*4.0)*0.5+0.5;
	float cy = cos(pos.y*32.0+u_time.x*4.0)*0.5+0.5;
	vec3 displacement = vec3(sx, cy, sx*cy);
	vec3 normal = a_normal.xyz*2.0 - 1.0;

	pos = pos + normal*displacement*vec3(0.06, 0.06, 0.06);

	gl_Position = mul(u_modelViewProj, vec4(pos, 1.0) );
	v_pos = gl_Position.xyz;
	v_view = mul(u_modelView, vec4(pos, 1.0) ).xyz;

	v_normal = mul(u_modelView, vec4(normal, 0.0) ).xyz;

	float len = length(displacement)*0.4+0.6;
	v_color0 = vec4(len, len, len, 1.0);
}


uniform vec4 u_time;

vec2 blinn(vec3 _lightDir, vec3 _normal, vec3 _viewDir)
{
	float ndotl = dot(_normal, _lightDir);
	vec3 reflected = _lightDir - 2.0*ndotl*_normal; // reflect(_lightDir, _normal);
	float rdotv = dot(reflected, _viewDir);
	return vec2(ndotl, rdotv);
}

float fresnel(float _ndotl, float _bias, float _pow)
{
	float facing = (1.0 - _ndotl);
	return max(_bias + (1.0 - _bias) * pow(facing, _pow), 0.0);
}

vec4 lit(float _ndotl, float _rdotv, float _m)
{
	float diff = max(0.0, _ndotl);
	float spec = step(0.0, _ndotl) * max(0.0, _rdotv * _m);
	return vec4(1.0, diff, spec, 1.0);
}

void fragment()
{
	vec3 lightDir = vec3(0.0, 0.0, -1.0);
	vec3 normal = normalize(v_normal);
	vec3 view = normalize(v_view);
	vec2 bln = blinn(lightDir, normal, view);
	vec4 lc = lit(bln.x, bln.y, 1.0);
	float fres = fresnel(bln.x, 0.2, 5.0);

	float index = ( (sin(v_pos.x*3.0+u_time.x)*0.3+0.7)
				+ (  cos(v_pos.y*3.0+u_time.x)*0.4+0.6)
				+ (  cos(v_pos.z*3.0+u_time.x)*0.2+0.8)
				)*M_PI;

	vec3 color = vec3(sin(index*8.0)*0.4 + 0.6
					, sin(index*4.0)*0.4 + 0.6
					, sin(index*2.0)*0.4 + 0.6
					) * v_color0.xyz;

	gl_FragColor.xyz = pow(vec3(0.07, 0.06, 0.08) + color*lc.y + fres*pow(lc.z, 128.0), vec3_splat(1.0/2.2) );
	gl_FragColor.w = 1.0;
}