#version 150

uniform sampler2D image;

in vec2 texCoord;

out vec4 fragColour;

void main(void)
{
    fragColour = texture(image, texCoord);
}
