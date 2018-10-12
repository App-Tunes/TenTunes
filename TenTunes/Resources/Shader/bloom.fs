#version 150

uniform sampler2D image;

out vec4 fragColour;

uniform vec2 resolution;

void main(void)
{
    vec4 pixel = texture(image, gl_FragCoord.xy / resolution);
    fragColour = pixel;
}
