#version 150

in vec2 texCoord;

out vec4 fragColour;

uniform sampler2D image;
uniform sampler2D bloom;

uniform vec2 resolution;

uniform int vertical;

uniform float retainer;
uniform float adder;

uniform vec2 dirVec;

void main(void)
{
    fragColour = vec4(texture(bloom, texCoord).rgb * retainer * 0.2270270270, 1);
    
    for (float i = -1.0; i < 2.0; i += 2.0)
    {
        vec2 activeDirVec = i * dirVec;
        
        fragColour.rgb += texture(bloom, texCoord + 1.0 * activeDirVec).rgb * 0.3162162162 * retainer;
        fragColour.rgb += texture(bloom, texCoord + 2.0 * activeDirVec).rgb * 0.0702702703 * retainer;

        if (adder > 0) {
            fragColour.rgb += texture(image, texCoord + 1.0 * activeDirVec).rgb * 0.3162162162 * adder;
            fragColour.rgb += texture(image, texCoord + 2.0 * activeDirVec).rgb * 0.0702702703 * adder;
        }
    }
    
    fragColour = clamp(fragColour, 0, 1);
}
