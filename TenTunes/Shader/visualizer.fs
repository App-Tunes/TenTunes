#version 150

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 fragColour;

//#ifdef GL_ES
//precision mediump float;
//#endif

//#extension GL_OES_standard_derivatives : enable

const int freq_count = 3;
const int point_count = 12;
const int points_per_freq = point_count / freq_count;
const float decay = 0.000001;

float dist(vec2 a, vec2 b) {
    return ((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float influence(vec2 point, float freq) {
    float dist = dist(gl_FragCoord.xy, point.xy);
    return freq / (dist * dist);
}

void main( void ) {
    float pTime = time * 0.1;
    float fTime = time * 4.0;

    float frequencies[freq_count];
    for (int i = 0; i < freq_count; i++) {
        frequencies[i] = sin(fTime * float(i + 1) + float(i)) + 1.01;
    }

    float points[point_count * 2];
    for (int i = 0; i < point_count; i++) {
        int freq = i / points_per_freq;
        points[i * 2 + 0] = (sin(pTime * (float(freq) + 1.0) + float(i)) + 1.0) / 2.0 * resolution.x; // X
        points[i * 2 + 1] = (sin(pTime * 1.5 * (float(freq) + 1.0) + float(i)) + 1.0) / 2.0 * resolution.y; // Y
    }

    //    float totalOmega = decay / resolution.x;
    float totalOmega = 0.0;
    for (int i = 0; i < point_count; i++) {
        vec2 point = vec2(points[i * 2 + 0], points[i * 2 + 1]);
        totalOmega += influence(point, frequencies[i / points_per_freq]);
    }

    vec4 color = vec4(1, 0, 0, 1);
    
    for (int i = 0; i < point_count; i++) {
        vec2 point = vec2(points[i * 2 + 0], points[i * 2 + 1]);
        vec3 pointColor = hsv2rgb(vec3(float(i / points_per_freq) / float(freq_count), 1.0, 0.5));
        color.rgb += pointColor * (influence(point, frequencies[i / points_per_freq]) / totalOmega);
    }
    
    fragColour = color;
}
