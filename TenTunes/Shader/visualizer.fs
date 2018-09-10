#version 150

out vec4 fragColour;

//#ifdef GL_ES
//precision mediump float;
//#endif

//#extension GL_OES_standard_derivatives : enable

const int MAX_FREQ_COUNT = 10;

const float decay = 1;
const float minDist = 0.007;

uniform int freqCount;

uniform float frequencies[MAX_FREQ_COUNT];
uniform float frequencyDistortionShiftSizes[MAX_FREQ_COUNT];
uniform float frequencyColors[MAX_FREQ_COUNT * 3];
uniform float frequencyColorsSoon[MAX_FREQ_COUNT * 3];

uniform float time;
uniform vec2 resolution;

float dist(vec2 a, vec2 b) {
    return ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

float influence(vec2 point, vec2 pos, float strength) {
    float dist = max(minDist + strength / 100, dist(pos, point.xy));
    return pow(strength / dist, 3 + strength / 10);
}

void main( void ) {
    vec2 pos = gl_FragCoord.xy / vec2(resolution.x, resolution.y);
    
    float centerX = (pos.x - 0.5) * 1000;
    float centerY = (pos.y - 0.5) * 1000;

    float pTime = time * 0.1;
    // Time-shift depending on x/y coord for some cool patterns
    for (int i = 0; i < freqCount; i++) {
        float freqRatio = float(i) / float(freqCount);
        float shiftSize = frequencyDistortionShiftSizes[i];
        pTime += sin(  centerX * sin(time * (0.0754 + freqRatio * 0.0154125467) + freqRatio * 6) / shiftSize
                     + centerY * cos(time * (0.0834 + freqRatio * 0.0146145673) + freqRatio * 6) / shiftSize)
        * (0.00802) * (pow(1.35, frequencies[i]) - 1);
    }
//    pTime += sin(centerX * sin(time * 0.0754) / 32.0 + centerY * cos(time * 0.0834) / 32.0) * 0.07 * lows;
//    pTime += sin(centerX * cos(time * 0.1) / 8.0 + centerY * sin(time * 0.11) / 8.0) * 0.01 * mids;
//    pTime += sin(centerX * sin(time * 0.212) / 2.0 + centerY * sin(time * 0.257) / 2.0) * 0.013 * highs;

    vec4 color = vec4(0, 0, 0, 0);

    float totalOmega = decay;
    float prevOmega;
    for (int i = 0; i < freqCount; i++) {
        vec2 point = vec2((sin(pTime * (float(i) * 1.04819 + 1.0) + float(i)) + 1.0) / 2.0,
                          (sin(pTime * 1.5 * (float(i) * 1.09823 + 1.0) + float(i)) + 1.0) / 2.0);
        float inf = influence(point, pos, frequencies[i]);
        
        vec3 pointColor = mix(vec3(frequencyColors[i * 3], frequencyColors[i * 3 + 1], frequencyColors[i * 3 + 2]),
                              vec3(frequencyColorsSoon[i * 3], frequencyColorsSoon[i * 3 + 1], frequencyColorsSoon[i * 3 + 2]), clamp(dist(point, pos) * 2, 0, 1));

        // Same as accumulating totalOmega and in a second cycle dividing inf by it
        prevOmega = totalOmega;
        totalOmega += inf;
        
        color.rgb = (color.rgb * (prevOmega + decay) + pointColor * inf) / (totalOmega + decay);
        color.a = min(color.a + frequencies[i] / 100, 1);
    }
    
    fragColour = color;
}
