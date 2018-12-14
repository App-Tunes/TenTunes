#version 150

in vec2 texCoord;

out vec4 fragColour;

uniform sampler2D source;
uniform sampler2D subtract;

void main(void)
{
    fragColour = max(texture(source, texCoord) - texture(subtract, texCoord), 0);
}
