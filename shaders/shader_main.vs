#version 330 core

uniform vec2 size;
uniform vec2 anchor;
uniform vec2 resolution;

void main() {
	vec2 p = vec2(gl_VertexID >> 1, gl_VertexID & 1); 

	p *= size;             // scale
	p += anchor;           // move into place
	p *= vec2(1.0, -1.0);  // flip y
	p *= 2.0/resolution;   // to NDC, with aspect ratio correction
	p += vec2(-1.0, 1.0);  // move anchor to upper left corner
	
    gl_Position = vec4(p, 0.0, 1.0);
}