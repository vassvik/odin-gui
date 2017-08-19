#version 330 core

uniform float iGlobalTime;
uniform vec3 resolution;

uniform vec4 in_color;

out vec4 FragColor;

void main() {
	FragColor = in_color;
}
