#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

// iOpen globe: a clear glass sphere whose continents (real shapes from the
// NASA day texture) wear giraffe skin — warm patches on a cream network.
// The far side's continents show faintly through the glass, under a glossy
// clear coat and rim glow.
// Zooming in (uRealism) blends the land towards real satellite colours.
// uFlat unrolls the sphere into a flat map: in between, the map curves like
// a sphere of growing curvature, so it visibly wraps into the globe.

uniform vec2 uSize;
uniform vec2 uCenter;    // sphere centre in pixels
uniform float uRadius;   // sphere radius in pixels
uniform float uLat;      // latitude facing the viewer, radians
uniform float uLng;      // longitude facing the viewer, radians
uniform float uRealism;  // 0 = brand style, 1 = mostly satellite colours
uniform float uFlat;     // 0 = globe, 1 = flat full-screen map (onboarding)
uniform sampler2D uDay;
uniform sampler2D uNight;

out vec4 fragColor;

const float PI = 3.14159265;
const float DEG = 57.29578;
const vec3 SUN = vec3(-0.6, 0.45, 0.66);
const vec3 RIM = vec3(0.6, 0.92, 0.9);
const float PATCH_SCALE = 6.0;   // giraffe patches across the globe

vec2 toUv(vec2 latLng) {
  return vec2(fract((latLng.y + 180.0) / 360.0), (90.0 - latLng.x) / 180.0);
}

float landAt(vec2 uv) {
  vec3 c = texture(uDay, uv).rgb;
  // The texture's oceans are dark navy, only a little bluer than land.
  return 1.0 - smoothstep(0.035, 0.09, c.b - max(c.r, c.g));
}

vec3 hash3(vec3 p) {
  p = vec3(
    dot(p, vec3(127.1, 311.7, 74.7)),
    dot(p, vec3(269.5, 183.3, 246.1)),
    dot(p, vec3(113.5, 271.9, 124.6))
  );
  return fract(sin(p) * 43758.5453);
}

// Reticulated giraffe pattern: 3D Voronoi cells on the sphere. Returns the
// distance to the nearest cell border (in cell units) and, through [seed], a
// value that varies per patch.
float giraffeBorder(vec3 q, out float seed) {
  vec3 cell = floor(q);
  vec3 f = fract(q);
  vec3 nearest = vec3(0.0);
  vec3 nearestCell = vec3(0.0);
  float best = 8.0;
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        vec3 g = vec3(float(i), float(j), float(k));
        vec3 o = g + 0.15 + 0.7 * hash3(cell + g) - f;
        float d = dot(o, o);
        if (d < best) {
          best = d;
          nearest = o;
          nearestCell = g;
        }
      }
    }
  }
  seed = hash3(cell + nearestCell).x;
  float border = 8.0;
  for (int k = -2; k <= 2; k++) {
    for (int j = -2; j <= 2; j++) {
      for (int i = -2; i <= 2; i++) {
        vec3 g = nearestCell + vec3(float(i), float(j), float(k));
        vec3 o = g + 0.15 + 0.7 * hash3(cell + g) - f;
        vec3 diff = o - nearest;
        if (dot(diff, diff) > 0.0001) {
          border = min(border, dot(0.5 * (nearest + o), normalize(diff)));
        }
      }
    }
  }
  return border;
}

// Giraffe skin at a point on the sphere: warm patches, a little deeper in
// the middle, separated by a cream network.
vec3 giraffeSkin(float lat, float lng, float z) {
  vec3 world = vec3(cos(lat) * sin(lng), sin(lat), cos(lat) * cos(lng));
  float seed;
  float border = giraffeBorder(world * PATCH_SCALE, seed);
  float pxPerCell = uRadius / PATCH_SCALE * max(z, 0.2);
  float lineHalf = 0.06 + 0.6 / pxPerCell;
  float aa = 1.0 / pxPerCell;
  float patchMask = smoothstep(lineHalf - aa, lineHalf + aa, border);
  vec3 patchColor = mix(vec3(0.84, 0.6, 0.36), vec3(0.74, 0.48, 0.27), seed);
  patchColor *= mix(1.0, 0.86, smoothstep(0.1, 0.45, border));
  vec3 lineColor = vec3(0.98, 0.93, 0.82);
  return mix(lineColor, patchColor, patchMask);
}

// Front of the glass at (lat, lng) with view-space normal n, premultiplied.
vec4 surface(vec3 n, float lat, float lng, vec2 p, float curve) {
  float z = n.z;
  float latDeg = lat * DEG;
  float lngDeg = mod(lng * DEG + 180.0, 360.0) - 180.0;
  vec2 uv = toUv(vec2(latDeg, lngDeg));

  vec3 sun = normalize(SUN);
  float light = mix(0.55, dot(n, sun), curve);
  float shade = 0.55 + 0.6 * max(light, 0.0);

  // Land: giraffe skin, blending to real colours when zoomed in.
  float land = landAt(uv);
  vec3 skin = giraffeSkin(lat, lng, z);
  vec3 day = texture(uDay, uv).rgb * 1.15;
  vec3 landColor = mix(skin, day, uRealism * 0.85) * shade;

  // Night side: dimmer land with warm city lights.
  float lit = smoothstep(-0.2, 0.35, light);
  float city = dot(texture(uNight, uv).rgb, vec3(0.3, 0.5, 0.2));
  vec3 cities = vec3(1.0, 0.85, 0.55) * smoothstep(0.3, 0.65, city);
  landColor = mix(landColor * 0.45 + cities, landColor, lit);

  // Sea: tinted clear glass, more solid when zoomed in.
  float seaAlpha = mix(0.16, 0.85, uRealism);
  vec3 seaColor = mix(vec3(0.16, 0.42, 0.46), vec3(0.08, 0.2, 0.27), uRealism);
  vec4 color = mix(vec4(seaColor * seaAlpha, seaAlpha), vec4(landColor, 1.0),
      land);

  // Clear-coat gloss: highlight, broad sheen and a glass glare.
  vec3 halfVec = normalize(sun + vec3(0.0, 0.0, 1.0));
  float nh = max(dot(n, halfVec), 0.0);
  float spec = (pow(nh, 120.0) * 0.32 + pow(nh, 10.0) * 0.05) * curve;
  float glare = 1.0 - smoothstep(0.0, 0.55, length(p - vec2(-0.38, -0.42)));
  spec += glare * glare * 0.08 * curve;
  color += vec4(vec3(spec), spec);

  // Rim light: glass edges catch the light.
  float fresnel = pow(1.0 - z, 2.2) * curve;
  color = mix(color, vec4(RIM, 1.0), fresnel * 0.55);
  return color;
}

// The far side's continents seen through the glass (mirrored, dimmer).
vec4 backSide(vec3 n) {
  vec3 b = vec3(n.x, n.y, -n.z);
  float sinLat0 = sin(uLat);
  float cosLat0 = cos(uLat);
  float lat = asin(clamp(b.z * sinLat0 + b.y * cosLat0, -1.0, 1.0));
  float lng = uLng + atan(b.x, b.z * cosLat0 - b.y * sinLat0);
  float lngDeg = mod(lng * DEG + 180.0, 360.0) - 180.0;
  float land = landAt(toUv(vec2(lat * DEG, lngDeg)));
  float a = land * 0.3 * (1.0 - uRealism);
  return vec4(vec3(0.62, 0.5, 0.36) * a, a);
}

void main() {
  vec2 p = (FlutterFragCoord().xy - uCenter) / uRadius;
  float edge = 1.5 / uRadius;

  if (uFlat > 0.0005) {
    // Map of curvature c: c = 0 is a flat equirectangular map, c = 1 the
    // front of the globe.
    float c = max(1.0 - uFlat, 0.001);
    float sy = -p.y * c;
    float cy = sqrt(max(1.0 - sy * sy, 0.0));
    float sx = p.x * c / max(cy, 0.0001);
    float m = max(abs(sy), abs(sx));
    if (m > 1.0) {
      float glow = exp(-(m - 1.0) * 10.0) * 0.65 * c;
      fragColor = vec4(RIM * glow, glow);
      return;
    }
    float cx = sqrt(max(1.0 - sx * sx, 0.0));
    // asin(s) / c, with a series near flat where dividing loses precision.
    float latL = (c < 0.05 ? -p.y * (1.0 + sy * sy / 6.0) : asin(sy) / c) +
        (1.0 - c) * uLat;
    float lngL = c < 0.05
        ? p.x / max(cy, 0.0001) * (1.0 + sx * sx / 6.0)
        : asin(sx) / c;
    // Past a pole the vector simply wraps over it, as on a real sphere.
    vec3 v = vec3(cos(latL) * sin(lngL), sin(latL), cos(latL) * cos(lngL));
    float lat0 = uLat * c;
    float lat = asin(clamp(v.z * sin(lat0) + v.y * cos(lat0), -1.0, 1.0));
    float lng = uLng + atan(v.x, v.z * cos(lat0) - v.y * sin(lat0));
    vec3 n = vec3(sx * cy, sy, cy * cx);
    float alpha = smoothstep(1.0, 1.0 - edge, m);
    fragColor = surface(n, lat, lng, p, c) * alpha;
    return;
  }

  float d = length(p);

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

  vec4 front = surface(n, lat, lng, p, 1.0);
  vec4 color = front + backSide(n) * (1.0 - front.a);
  float alpha = smoothstep(1.0, 1.0 - edge, d);
  fragColor = color * alpha;
}
