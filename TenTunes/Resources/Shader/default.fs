#version 150

in vec2 texCoord;

uniform sampler2D image;
uniform float alpha;

out vec4 fragColour;

void main(void)
{
    fragColour = texture(image, texCoord);
    fragColour.a *= alpha;
}
