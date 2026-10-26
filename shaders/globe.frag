#version 460 core

#include <flutter/runtime_effect.glsl>

// iOpen globe: real continent shapes (from the NASA day texture) drawn in the
// app icon's style — aqua land covered in giraffe spots on a navy ocean —
// with a glossy clear coat, rim glow and warm city lights on the night side.
// Zooming in (uRealism) blends the land towards real satellite colours.

uniform vec2 uSize;
uniform vec2 uCenter;    // sphere centre in pixels
uniform float uRadius;   // sphere radius in pixels
uniform float uLat;      // latitude facing the viewer, radians
uniform float uLng;      // longitude facing the viewer, radians
uniform float uRealism;  // 0 = brand style, 1 = mostly satellite colours
uniform sampler2D uDay;
uniform sampler2D uNight;

out vec4 fragColor;

const float PI = 3.14159265;
const float DEG = 57.29578;
const vec3 SUN = vec3(-0.6, 0.45, 0.66);
const vec3 RIM = vec3(0.6, 0.92, 0.9);
const float SPOT_SPACING = 2.4;  // degrees between giraffe spots

vec2 toUv(vec2 latLng) {
  return vec2(fract((latLng.y + 180.0) / 360.0), (90.0 - latLng.x) / 180.0);
}

float landAt(vec2 uv) {
  vec3 c = texture(uDay, uv).rgb;
  return 1.0 - smoothstep(0.08, 0.2, c.b - max(c.r, c.g));
}

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Giraffe spots: one jittered, rotated ellipse per cell on a lat/lng grid.
// Returns the spot coverage and, through [centre], the spot's lat/lng.
float giraffeSpots(float latDeg, float lngDeg, float pxPerDeg, out vec2 centre) {
  float best = 0.0;
  centre = vec2(latDeg, lngDeg);
  float row0 = floor(latDeg / SPOT_SPACING + 0.5);
  for (int dr = -1; dr <= 1; dr++) {
    float row = row0 + float(dr);
    float latC = row * SPOT_SPACING;
    float lngStep = SPOT_SPACING / max(cos(latC / DEG), 0.1);
    float col0 = floor(lngDeg / lngStep + 0.5);
    for (int dc = -1; dc <= 1; dc++) {
      vec2 id = vec2(row, col0 + float(dc));
      vec2 c = vec2(
        latC + (hash(id) - 0.5) * 0.5 * SPOT_SPACING,
        id.y * lngStep + (hash(id + 7.3) - 0.5) * 0.5 * lngStep
      );
      float dLng = mod(lngDeg - c.y + 180.0, 360.0) - 180.0;
      vec2 o = vec2(dLng * cos(latDeg / DEG), latDeg - c.x);
      float ang = hash(id + 19.1) * PI;
      vec2 r = vec2(cos(ang) * o.x + sin(ang) * o.y, -sin(ang) * o.x + cos(ang) * o.y);
      float a = SPOT_SPACING * (0.26 + 0.12 * hash(id + 3.7));
      float b = a * 0.58;
      float e = length(r / vec2(a, b));
      float aa = 1.0 / max(pxPerDeg * b, 1.0);
      float m = 1.0 - smoothstep(1.0 - aa, 1.0 + aa, e);
      if (m > best) {
        best = m;
        centre = c;
      }
    }
  }
  return best;
}

void main() {
  vec2 p = (FlutterFragCoord().xy - uCenter) / uRadius;
  float d = length(p);
  float edge = 1.5 / uRadius;

  // Outer glow.
  if (d > 1.0) {
    float glow = exp(-(d - 1.0) * 10.0) * 0.65;
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
  vec2 uv = toUv(vec2(latDeg, lngDeg));

  vec3 sun = normalize(SUN);
  float light = dot(n, sun);
  float lit = smoothstep(-0.2, 0.35, light);
  float shade = 0.32 + 0.8 * max(light, 0.0);

  // Navy ocean, like the "Anytime" screen.
  vec3 color = mix(vec3(0.06, 0.12, 0.18), vec3(0.12, 0.24, 0.31), shade);

  // Aqua land, like the app icon, blending to real colours when zoomed in.
  vec3 day = texture(uDay, uv).rgb;
  float land = landAt(uv);
  vec3 aqua = mix(vec3(0.49, 0.77, 0.75), day * 1.15, uRealism * 0.85);
  color = mix(color, aqua * shade, land);

  // Giraffe spots on land.
  float pxPerDeg = uRadius / DEG * max(z, 0.25);
  vec2 spotCentre;
  float spot = giraffeSpots(latDeg, lngDeg, pxPerDeg, spotCentre);
  float spotLand = landAt(toUv(spotCentre));
  vec3 spotColor = vec3(0.2, 0.42, 0.42) * shade;
  color = mix(color, spotColor, spot * spotLand * land * (1.0 - uRealism * 0.8));

  // Night side: dim, with warm city lights in the spots.
  float city = dot(texture(uNight, toUv(spotCentre)).rgb, vec3(0.3, 0.5, 0.2));
  vec3 cities = vec3(1.0, 0.8, 0.5) * smoothstep(0.25, 0.6, city) * spot * 1.2;
  color = mix(color * 0.35 + cities, color, lit);

  // Clear-coat gloss: highlight, broad sheen and a glass glare.
  vec3 halfVec = normalize(sun + vec3(0.0, 0.0, 1.0));
  float nh = max(dot(n, halfVec), 0.0);
  color += vec3(1.0) * (pow(nh, 120.0) * 0.3 + pow(nh, 10.0) * 0.1);
  float glare = 1.0 - smoothstep(0.0, 0.55, length(p - vec2(-0.38, -0.42)));
  color += vec3(0.85, 0.97, 1.0) * glare * glare * 0.14;

  // Rim light.
  float fresnel = pow(1.0 - z, 2.2);
  color = mix(color, RIM, fresnel * 0.6);

  float alpha = smoothstep(1.0, 1.0 - edge, d);
  fragColor = vec4(color * alpha, alpha);
}
