#version 150

uniform sampler2D image;
uniform vec2 resolution;

out vec4 fragColour;

void main(void)
{
    fragColour = texture(image, gl_FragCoord.xy / resolution);
}
