#version 150

out vec4 fragColour;

//#ifdef GL_ES
//precision mediump float;
//#endif

//#extension GL_OES_standard_derivatives : enable

const int MAX_FREQ_COUNT = 12;
const int MAX_POINT_COUNT = 12;

const float decay = 0.0000000001;

uniform int freqCount;
uniform int pointCount;

uniform float frequencies[MAX_FREQ_COUNT];
uniform float frequencyColors[MAX_FREQ_COUNT * 3];

uniform float time;
uniform vec2 resolution;

float dist(vec2 a, vec2 b) {
    return ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

float influence(vec2 point, float freq) {
    float dist = max(0.04, dist(gl_FragCoord.xy, point.xy) / (resolution.x * resolution.y));
    return pow(freq / abs(dist), 5);
}

void main( void ) {
    int points_per_freq = pointCount / freqCount;
    
    float pTime = time * 0.1;
    float fTime = time * 4.0;

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
        float inf = influence(point, frequencies[i / points_per_freq]);
        
        totalOmega += inf;
        individualOmega[i] = inf;
    }

    vec3 color = vec3(0, 0, 0);
    
    totalOmega = 1.0 / totalOmega;
    for (int i = 0; i < pointCount; i++) {
        vec3 pointColor = vec3(frequencyColors[i / points_per_freq * 3], frequencyColors[i / points_per_freq * 3 + 1], frequencyColors[i / points_per_freq * 3 + 2]);
        color += pointColor * (individualOmega[i] * totalOmega);
    }
    
    fragColour = vec4(color, 1);
}
