#version 460 core

#include <flutter/runtime_effect.glsl>

// Stylised-real Earth: real continent shapes (from the NASA day texture)
// drawn as a glossy teal sphere with a dot-matrix land layer, clear-coat
// highlights, a cyan rim, and warm city-light dots on the night side.
// Zooming in (uRealism) blends the land towards the real satellite colours.

uniform vec2 uSize;
uniform vec2 uCenter;    // sphere centre in pixels
uniform float uRadius;   // sphere radius in pixels
uniform float uLat;      // latitude facing the viewer, radians
uniform float uLng;      // longitude facing the viewer, radians
uniform float uRealism;  // 0 = stylised, 1 = mostly satellite colours
uniform sampler2D uDay;
uniform sampler2D uNight;

out vec4 fragColor;

const float PI = 3.14159265;
const float DEG = 57.29578;
const vec3 SUN = vec3(-0.6, 0.45, 0.66);
const vec3 RIM = vec3(0.45, 0.9, 0.97);
const float DOT_SPACING = 1.5;  // degrees between land dots

vec2 toUv(float latDeg, float lngDeg) {
  return vec2(fract((lngDeg + 180.0) / 360.0), (90.0 - latDeg) / 180.0);
}

float landAt(vec2 uv) {
  vec3 c = texture(uDay, uv).rgb;
  return 1.0 - smoothstep(0.08, 0.2, c.b - max(c.r, c.g));
}

void main() {
  vec2 p = (FlutterFragCoord().xy - uCenter) / uRadius;
  float d = length(p);
  float edge = 1.5 / uRadius;

  // Outer glow.
  if (d > 1.0) {
    float glow = exp(-(d - 1.0) * 10.0) * 0.7;
    float a = glow * smoothstep(1.0, 1.0 + edge, d);
    fragColor = vec4(RIM * a, a);
    return;
  }

  float z = sqrt(1.0 - d * d);
  vec3 n = vec3(p.x, -p.y, z);

  float sinLat0 = sin(uLat);
  float cosLat0 = cos(uLat);
  float lat = asin(clamp(z * sinLat0 + n.y * cosLat0, -1.0, 1.0));
  float lng = uLng + atan(n.x, z * cosLat0 - n.y * sinLat0);
  float latDeg = lat * DEG;
  float lngDeg = mod(lng * DEG + 180.0, 360.0) - 180.0;
  vec2 uv = toUv(latDeg, lngDeg);

  vec3 sun = normalize(SUN);
  float light = dot(n, sun);
  float lit = smoothstep(-0.2, 0.35, light);
  float shade = 0.3 + 0.8 * max(light, 0.0);

  // Ocean: glossy deep teal.
  vec3 color = mix(vec3(0.03, 0.17, 0.21), vec3(0.08, 0.38, 0.43), shade);

  // Land fill: brand teal mixed with the real colours.
  vec3 day = texture(uDay, uv).rgb;
  float land = landAt(uv);
  vec3 tint = mix(vec3(0.16, 0.5, 0.52), day * 1.15, 0.3 + 0.6 * uRealism);
  color = mix(color, tint * shade, land * (0.55 + 0.4 * uRealism));

  // Dot-matrix land layer, sampled per cell so each dot is uniform.
  float row = floor(latDeg / DOT_SPACING + 0.5);
  float latC = row * DOT_SPACING;
  float lngStep = DOT_SPACING / max(cos(latC / DEG), 0.08);
  float lngC = (floor(lngDeg / lngStep + 0.5)) * lngStep;
  vec2 offset = vec2(latDeg - latC, (lngDeg - lngC) * cos(lat));
  float dist = length(offset);
  float pxPerDeg = uRadius / DEG * max(z, 0.25);
  float r = DOT_SPACING * 0.3;
  float aa = 1.0 / pxPerDeg;
  float dotMask = 1.0 - smoothstep(r - aa, r + aa, dist);
  vec2 cellUv = toUv(latC, lngC);
  float cellLand = landAt(cellUv);
  float dots = dotMask * cellLand * (1.0 - uRealism * 0.85);
  color += vec3(0.62, 0.95, 0.98) * dots * (0.25 + 0.6 * lit);

  // Night side: dim, with warm city-light dots.
  float city = dot(texture(uNight, cellUv).rgb, vec3(0.3, 0.5, 0.2));
  vec3 cities = vec3(1.0, 0.8, 0.5) * smoothstep(0.25, 0.6, city) * dotMask * 1.3;
  color = mix(color * 0.35 + cities, color, lit);

  // Clear-coat gloss: sharp highlight, broad sheen and a glass glare.
  vec3 halfVec = normalize(sun + vec3(0.0, 0.0, 1.0));
  float nh = max(dot(n, halfVec), 0.0);
  color += vec3(1.0) * (pow(nh, 120.0) * 0.3 + pow(nh, 10.0) * 0.1);
  float glare = 1.0 - smoothstep(0.0, 0.55, length(p - vec2(-0.38, -0.42)));
  color += vec3(0.85, 0.97, 1.0) * glare * glare * 0.16;

  // Rim light.
  float fresnel = pow(1.0 - z, 2.2);
  color = mix(color, RIM, fresnel * 0.7);

  float alpha = smoothstep(1.0, 1.0 - edge, d);
  fragColor = vec4(color * alpha, alpha);
}
