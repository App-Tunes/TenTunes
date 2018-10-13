#version 150

in vec4 position;

out vec2 texCoord;

void main (void)
{
    gl_Position = position;
    texCoord = (position.xy + 1) / 2;
}
