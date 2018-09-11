#version 150

out vec4 fragColour;

//#ifdef GL_ES
//precision mediump float;
//#endif

//#extension GL_OES_standard_derivatives : enable

const int MAX_FREQ_COUNT = 10;

uniform int resonanceCount;

uniform float resonance[MAX_FREQ_COUNT];
uniform float resonanceDistortionShiftSizes[MAX_FREQ_COUNT];
uniform float resonanceColors[MAX_FREQ_COUNT * 3];
uniform float resonanceColorsSoon[MAX_FREQ_COUNT * 3];

uniform float time;
uniform vec2 resolution;

uniform float minDist;
uniform float decay;

float dist(vec2 a, vec2 b) {
    return ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

float influence(vec2 point, vec2 pos, float strength) {
    float dist = max(minDist + strength / 100, dist(pos, point.xy));
    return pow(strength / dist, 3 + strength / 10);
}

void main( void ) {
    vec2 pos = gl_FragCoord.xy / vec2(resolution.x, resolution.y);
    
    float centerX = (pos.x * resolution.x) - resolution.x / 2;
    float centerY = (pos.y * resolution.y) - resolution.y / 2;
    
    // Position-shift based on time
    float posChange = sin(time * 0.2234 + centerX * centerY / (resolution.x * resolution.y) * 2) / 8 + 0.5;
    pos = mix(pos, vec2(sin(time * 0.024851) / 2 + 0.5,sin(time * 0.034611) / 2 + 0.5), posChange);

    centerX = (pos.x - 0.5) * 1000;
    centerY = (pos.y - 0.5) * 1000;

    float pTime = time * 0.1;
    // Time-shift depending on x/y coord for some cool patterns
    for (int i = 0; i < resonanceCount; i++) {
        float freqRatio = float(i) / float(resonanceCount);
        float shiftSize = resonanceDistortionShiftSizes[i];
        pTime += sin(  centerX * sin(time * (0.0754 + freqRatio * 0.0154125467) + freqRatio * 6) / shiftSize
                     + centerY * cos(time * (0.0834 + freqRatio * 0.0146145673) + freqRatio * 6) / shiftSize)
        * (0.00802) * (pow(1.35, resonance[i]) - 1);
    }

    vec4 color = vec4(0, 0, 0, 0);

    float totalOmega = decay;
    float prevOmega;
    for (int i = 0; i < resonanceCount; i++) {
        vec2 point = vec2((sin(pTime * (float(i) * 1.04819 + 1.0) + float(i)) + 1.0) / 2.0,
                          (sin(pTime * 1.5 * (float(i) * 1.09823 + 1.0) + float(i)) + 1.0) / 2.0);
        float inf = influence(point, pos, resonance[i]);
        
        vec3 pointColor = mix(vec3(resonanceColors[i * 3], resonanceColors[i * 3 + 1], resonanceColors[i * 3 + 2]),
                              vec3(resonanceColorsSoon[i * 3], resonanceColorsSoon[i * 3 + 1], resonanceColorsSoon[i * 3 + 2]), clamp(dist(point, pos) * 2, 0, 1));

        // Same as accumulating totalOmega and in a second cycle dividing inf by it
        prevOmega = totalOmega;
        totalOmega += inf;
        
        color.rgb = (color.rgb * (prevOmega + decay) + pointColor * inf) / (totalOmega + decay);
        color.a = min(color.a + resonance[i] / 10, 1);
    }
    
    fragColour = color;
}
