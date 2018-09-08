#version 150

out vec4 fragColour;

//#ifdef GL_ES
//precision mediump float;
//#endif

//#extension GL_OES_standard_derivatives : enable

const int MAX_FREQ_COUNT = 10;
const int MAX_POINT_COUNT = 10;

const float decay = 1;

uniform int freqCount;
uniform int pointCount;

uniform float frequencies[MAX_FREQ_COUNT];
uniform float frequencyColors[MAX_FREQ_COUNT * 3];

uniform float time;
uniform vec2 resolution;

float dist(vec2 a, vec2 b) {
    return ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

float influence(vec2 point, vec2 pos, float freq) {
    float dist = max(0.01 + freq / 100, dist(pos, point.xy) / (resolution.x * resolution.y));
    return pow(freq / dist, 3 + freq / 10);
}

void main( void ) {
    int points_per_freq = pointCount / freqCount;
    vec2 pos = gl_FragCoord.xy;
    
    float centerX = pos.x - resolution.x / 2;
    float centerY = pos.y - resolution.y / 2;

    // Position-shift based on time
    float posChange = (sin(time * 0.2234 + centerX * centerY / (resolution.x * resolution.y) * 2) + 1) / 6;
    pos = mod(pos, 6 + sin(time * 0.4123) * 2) * posChange + pos * (1 - posChange);

    centerX = pos.x - resolution.x / 2;
    centerY = pos.y - resolution.y / 2;

    float pTime = time * 0.1;
    // Time-shift depending on x/y coord for some cool patterns
    for (int i = 0; i < pointCount; i++) {
        float freqRatio = (float(i / points_per_freq) / freqCount);
        pTime += sin(  centerX * sin(time * (0.0754 + freqRatio * 0.0154) + freqRatio) / ((1 - freqRatio) * 32)
                     + centerY * cos(time * (0.0834 + freqRatio * 0.0146) + freqRatio) / ((1 - freqRatio) * 32))
        * (0.0021 + (1 - freqRatio) * 0.0033) * frequencies[i / points_per_freq];
    }
//    pTime += sin(centerX * sin(time * 0.0754) / 32.0 + centerY * cos(time * 0.0834) / 32.0) * 0.07 * lows;
//    pTime += sin(centerX * cos(time * 0.1) / 8.0 + centerY * sin(time * 0.11) / 8.0) * 0.01 * mids;
//    pTime += sin(centerX * sin(time * 0.212) / 2.0 + centerY * sin(time * 0.257) / 2.0) * 0.013 * highs;

    
    float points[MAX_POINT_COUNT * 2];
    for (int i = 0; i < pointCount; i++) {
        int freq = i / points_per_freq;
        points[i * 2 + 0] = (sin(pTime * (float(freq) + 1.0) + float(i)) + 1.0) / 2.0 * resolution.x; // X
        points[i * 2 + 1] = (sin(pTime * 1.5 * (float(freq) + 1.0) + float(i)) + 1.0) / 2.0 * resolution.y; // Y
    }

    float totalOmega = decay / resolution.x;
    float individualOmega[MAX_POINT_COUNT];
    for (int i = 0; i < pointCount; i++) {
        vec2 point = vec2(points[i * 2 + 0], points[i * 2 + 1]);
        float inf = influence(point, pos, frequencies[i / points_per_freq]);
        
        totalOmega += inf;
        individualOmega[i] = inf;
    }
    
    vec4 color = vec4(0, 0, 0, 0);

    totalOmega = 1.0 / totalOmega;
    for (int i = 0; i < pointCount; i++) {
        vec3 pointColor = vec3(frequencyColors[i / points_per_freq * 3], frequencyColors[i / points_per_freq * 3 + 1], frequencyColors[i / points_per_freq * 3 + 2]);
        color.rgb += pointColor * (individualOmega[i] * totalOmega);
        color.a = min(color.a + frequencies[i / points_per_freq] / 100, 1);
    }
    
    fragColour = color;
}
