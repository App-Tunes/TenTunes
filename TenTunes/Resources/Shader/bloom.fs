#version 150

uniform sampler2D image;
uniform sampler2D bloom;

out vec4 fragColour;

uniform vec2 resolution;

uniform int vertical;

uniform float retainer;
uniform float adder;

uniform vec2 dirVec;

void main(void)
{
    fragColour = texture(bloom, texCoord) * retainer * 0.2270270270;
    
    for(float i = -1.0; i < 2.0; i += 2.0)
    {
        vec2 activeDirVec = i * dirVec;
        
        fragColour.rgb += texture(bloom, clamp(texCoord + 1.0 * activeDirVec, 0.0, 1.0)).rgb * 0.3162162162 * retainer;
        fragColour.rgb += texture(bloom, clamp(texCoord + 2.0 * activeDirVec, 0.0, 1.0)).rgb * 0.0702702703 * retainer;

        if (adder > 0) {
            fragColour.rgb += texture(image, clamp(texCoord + 1.0 * activeDirVec, 0.0, 1.0)).rgb * 0.3162162162 * adder;
            fragColour.rgb += texture(image, clamp(texCoord + 2.0 * activeDirVec, 0.0, 1.0)).rgb * 0.0702702703 * adder;
        }
    }
    
    fragColour = clamp(fragColour, 0, 1);
}
