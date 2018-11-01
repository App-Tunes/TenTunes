#version 150

const int MAX_FREQ_COUNT = 10;

out vec4 fragColour;

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

float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
                 43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);
    
    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(a, b, u.x) +
    (c - a)* u.y * (1.0 - u.x) +
    (d - b) * u.x * u.y;
}

float fbm ( in vec2 _st, int octaves) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5),
                    -sin(0.5), cos(0.50));
    for (int i = 0; i < octaves; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

float fbm ( in vec2 _st) {
    return fbm(_st, 5);
}

float dist(vec2 a, vec2 b) {
    return ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

float dist(vec3 a, vec3 b) {
    return ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y) + (a.z - b.z) * (a.z - b.z));
}

float distPoint(int i, float pTime, vec2 pos) {
    vec2 point = vec2(sin(pTime * (float(i) * 0.74819 + 1.0 + mod(float(i), 0.049131) * 2) + float(i)) * 0.4 + 0.5,
                      sin(pTime * 1.5 * (float(i) * 0.79823 + 1.0 + mod(float(i), 0.068231) * 2) + float(i)) * 0.4 + 0.5);
    return dist(pos, point.xy);
}

//float distFBM(int i, float pTime, vec2 pos) {
//    return 0.1 / pow(fbm(vec2(fbm(pos + vec2(float(i) * 100)) * 5 + pTime, pTime * 2 + float(i) * 100)), 2);
//}
//
//float distAtan(int i, float pTime, vec2 pos) {
//    vec2 p = ( sin(vec2(fbm(pos.xy + pTime * .23 + float(i) * 0.0128, 3) * 2, fbm(pos.yx - pTime * .23 + float(i) * 0.0128, 3) * 2) * 3) - 0.5) * 10.;
//    vec3 c = vec3(0.);
//    float a = atan(p.x * time,p.y + time * 0.623);
//    float r = length(p);
//    float cc = 1.0 + sin(r * 3) + a * .5 - time * 0.3;
//    for (int i=1; i<=3; i++)
//        cc = abs(sin(float(i)*1.*cc));
//    return cc;
//}

void main( void ) {
    vec2 pos = gl_FragCoord.xy / vec2(resolution.x, resolution.y);
    
    vec2 center = vec2((pos.x - 0.5) * scale, (pos.y - 0.5) * scale);
    float pTime = time * 0.1;

    // Position-shift based on time
    pos = mix(pos, vec2(sin(pTime * 1.24122) + 0.5, cos(pTime * 1.24122) + 0.5),
              (sin(pTime * 1.2234 + center.x * center.y * 10) + 1) * spaceDistortion);

    // And same but pow
    pos = mix(pos, vec2(sin(pTime * 1.3183) + 0.5, cos(pTime * 1.82117) + 0.5),
              (sin(pTime * 2.234 + pow(2, center.x * center.y * 10)) + 1) * spaceDistortion);

    center = vec2((pos.x - 0.5) * scale, (pos.y - 0.5) * scale);
    
    // Time-Shift depending on x/y coord for some cool patterns
    for (int i = 0; i < resonanceCount; i++) {
        float freqRatio = float(i) / float(resonanceCount);
        float shiftSize = resonanceDistortionShiftSizes[i];
        // Use both since both distortion effects are interesting
        float distTime = pTime * 0.15 + time * 0.1 * 0.85;
        pTime += sin(  center.x * sin(distTime * (0.377231 + resonanceDistortionSpeed[i] * 0.07719872) + freqRatio * 6) / shiftSize
                     + center.y * cos(distTime * (0.41731 + resonanceDistortionSpeed[i] * 0.0731231) + freqRatio * 6) / shiftSize)
        * resonanceDistortion[i];
        
//        // Spiral-Shift depending on time
//        vec2 p = center * (10.0 + 80.0 * resonanceDistortionShiftSizes[i]);
//        float a = atan(p.x, p.y);
//        float r = length(p);
//        float cc = abs(sin(r + a *.5 - pTime * 2.));
//        pTime += cc * resonanceDistortion[i] * 3.0;
    }
    
    // Lines floating along top to bottom
//    float webShiftY = pow((sin(pTime * 0.113238) + 1) * (sin(pTime * 0.132034) + 1) / 4, 3) * pow(spaceDistortion, 2);
//    pos.x += mod(pos.y * (10 + sin(pTime * 0.1831) * 2) + pTime * 0.123182, 1) < 0.5 ? webShiftY : -webShiftY;

    vec4 color = vec4(0, 0, 0, 1);

    float totalOmega = decay;
    float prevOmega;
    for (int i = 0; i < resonanceCount; i++) {
        float rawDist = distPoint(i, pTime, pos);
        
        vec3 pointColor = mix(vec3(resonanceColors[i * 3], resonanceColors[i * 3 + 1], resonanceColors[i * 3 + 2]),
                              vec3(resonanceColorsSoon[i * 3], resonanceColorsSoon[i * 3 + 1], resonanceColorsSoon[i * 3 + 2]),
                              clamp(rawDist * 15 / (resonance[i] + 1), 0, 1.3))
        - (1 / ((brightness * 70 + resonance[i] * 30) * rawDist + 1) - 0.1) * (1 - brightness);

        float inf = pow(resonance[i] / max(minDist + resonance[i] / 50, minDist / 2 + rawDist)
                        * (brightness + 0.1), sharpness + resonance[i] / 10);
        
        // Same as accumulating totalOmega and in a second cycle dividing inf by it
        prevOmega = totalOmega;
        totalOmega += inf;
        
        color.rgb += pointColor * inf;
        // color.a = min(color.a + resonance[i] / 10, 1);
    }
    
    color.rgb /= totalOmega;
    
    fragColour = clamp(color, 0, 1);
}
