#version 150

uniform vec2 p;
in vec4 position;

void main (void)
{
    gl_Position = vec4(p, 0.0, 0.0) + position;
}
