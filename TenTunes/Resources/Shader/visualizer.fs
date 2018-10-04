#version 150

out vec4 fragColour;

//#ifdef GL_ES
//precision mediump float;
//#endif

//#extension GL_OES_standard_derivatives : enable

const int MAX_FREQ_COUNT = 10;

uniform int resonanceCount;

// Resonance (fft)
uniform float resonance[MAX_FREQ_COUNT];
// Strength of distortion
uniform float resonanceDistortion[MAX_FREQ_COUNT];
// Speed of distortion mutation
uniform float resonanceDistortionSpeed[MAX_FREQ_COUNT];
// Distortion field size
uniform float resonanceDistortionShiftSizes[MAX_FREQ_COUNT];

// Inner color of points
uniform float resonanceColors[MAX_FREQ_COUNT * 3];
// Outer color of points
uniform float resonanceColorsSoon[MAX_FREQ_COUNT * 3];

// Real time
uniform float time;
// Resolution to make picture independent of it
uniform vec2 resolution;

// Min size of points
uniform float minDist;
// Falloff of points - similar to brightness but more prone to extremeties
uniform float decay;
// How sharp points are
uniform float sharpness;
// How large the distortion is
uniform float scale;
// How large points are
uniform float brightness;

uniform float spaceDistortion;

float dist(vec2 a, vec2 b) {
    return ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

float influence(vec2 point, vec2 pos, float strength) {
    float dist = max(minDist + strength / 100, minDist / 2 + dist(pos, point.xy));
    return pow(strength / dist * brightness, sharpness + strength / 10);
}

void main( void ) {
    vec2 pos = gl_FragCoord.xy / vec2(resolution.x, resolution.y);
    
    vec2 center = vec2((pos.x - 0.5) * scale, (pos.y - 0.5) * scale);
    float pTime = time * 0.1;

    // Position-shift based on time
    pos = mix(pos, vec2(sin(pTime * 1.24122) + 0.5, cos(pTime * 1.24122) + 0.5),
              (sin(pTime * 1.2234 + center.x * center.y * 10) + 1) / 10 * spaceDistortion);

    // And same but pow
    pos = mix(pos, vec2(sin(pTime * 1.3183) + 0.5, cos(pTime * 1.82117) + 0.5),
              (sin(pTime * 2.234 + pow(2, center.x * center.y * 10)) + 1) / 10 * spaceDistortion);

    center = vec2((pos.x - 0.5) * scale, (pos.y - 0.5) * scale);

    // Time-Shift depending on x/y coord for some cool patterns
    for (int i = 0; i < resonanceCount; i++) {
        float freqRatio = float(i) / float(resonanceCount);
        float shiftSize = resonanceDistortionShiftSizes[i];
        pTime += sin(  center.x * sin(pTime * (0.0754 + resonanceDistortionSpeed[i] * 0.0154125467) + freqRatio * 6) / shiftSize
                     + center.y * cos(pTime * (0.0834 + resonanceDistortionSpeed[i] * 0.0146145673) + freqRatio * 6) / shiftSize)
        * resonanceDistortion[i];
    }

    // Lines floating along top to bottom
    float webShiftY = pow((sin(pTime * 0.113238) + 1) * (sin(pTime * 0.132034) + 1) / 4, 2) * spaceDistortion;
    pos.x += mod(pos.y * (10 + sin(pTime * 0.1831) * 2) + pTime * 0.123182, 1) < 0.5 ? webShiftY : -webShiftY;

    vec4 color = vec4(0, 0, 0, 1);

    float totalOmega = decay;
    float prevOmega;
    for (int i = 0; i < resonanceCount; i++) {
        vec2 point = vec2(sin(pTime * (float(i) * 0.74819 + 1.0 + mod(float(i), 0.049131) * 2) + float(i)) * 0.4 + 0.5,
                          sin(pTime * 1.5 * (float(i) * 0.79823 + 1.0 + mod(float(i), 0.068231) * 2) + float(i)) * 0.4 + 0.5);
        float inf = influence(point, pos, resonance[i]);
        
        vec3 pointColor = mix(vec3(resonanceColors[i * 3], resonanceColors[i * 3 + 1], resonanceColors[i * 3 + 2]),
                              vec3(resonanceColorsSoon[i * 3], resonanceColorsSoon[i * 3 + 1], resonanceColorsSoon[i * 3 + 2]), clamp(dist(point, pos) * 2, 0, 1));

        // Same as accumulating totalOmega and in a second cycle dividing inf by it
        prevOmega = totalOmega;
        totalOmega += inf;
        
        color.rgb += pointColor * inf;
        // color.a = min(color.a + resonance[i] / 10, 1);
    }
    
    color.rgb /= totalOmega;
    
    fragColour = color;
}
