#version 330 core

in vec2 pos;

uniform float iGlobalTime;

uniform vec2 resolution;
uniform vec2 size;
uniform vec2 anchor;
uniform bool inside;

uniform vec4 in_color;

out vec4 FragColor;

void main() {
	FragColor = in_color;
	if (inside) FragColor.xyz = 1.0 - FragColor.xyz;
}
