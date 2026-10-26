#version 460 core

#include <flutter/runtime_effect.glsl>

// Realistic Earth: NASA day texture lit by a sun, city lights on the night
// side, ocean glint, and a soft cyan atmosphere around the rim.

uniform vec2 uSize;
uniform vec2 uCenter;   // sphere centre in pixels
uniform float uRadius;  // sphere radius in pixels
uniform float uLat;     // latitude facing the viewer, radians
uniform float uLng;     // longitude facing the viewer, radians
uniform sampler2D uDay;
uniform sampler2D uNight;

out vec4 fragColor;

const float PI = 3.14159265;
const vec3 SUN = vec3(-0.62, 0.42, 0.66);  // view space, from top left
const vec3 ATMOSPHERE = vec3(0.42, 0.86, 0.95);

void main() {
  vec2 p = (FlutterFragCoord().xy - uCenter) / uRadius;
  float d = length(p);
  float edge = 1.5 / uRadius;

  // Outer atmosphere glow.
  if (d > 1.0) {
    float glow = exp(-(d - 1.0) * 9.0) * 0.75;
    float a = glow * smoothstep(1.0, 1.0 + edge, d);
    fragColor = vec4(ATMOSPHERE * a, a);
    return;
  }

  float z = sqrt(1.0 - d * d);
  vec3 n = vec3(p.x, -p.y, z);

  // Inverse orthographic projection back to latitude / longitude.
  float sinLat0 = sin(uLat);
  float cosLat0 = cos(uLat);
  float lat = asin(clamp(z * sinLat0 + n.y * cosLat0, -1.0, 1.0));
  float lng = uLng + atan(n.x, z * cosLat0 - n.y * sinLat0);
  vec2 uv = vec2(fract((lng + PI) / (2.0 * PI)), (PI / 2.0 - lat) / PI);

  vec3 day = texture(uDay, uv).rgb;
  vec3 night = texture(uNight, uv).rgb;

  // Recolour the texture's navy oceans to a deep teal-blue.
  float ocean = smoothstep(0.08, 0.22, day.b - max(day.r, day.g));
  vec3 sea = mix(vec3(0.02, 0.16, 0.27), vec3(0.05, 0.32, 0.44), z);
  day = mix(day, sea, ocean * 0.9);

  vec3 sun = normalize(SUN);
  float light = dot(n, sun);
  float lit = smoothstep(-0.18, 0.3, light);

  vec3 dayColor = day * (0.28 + 1.05 * max(light, 0.0));
  vec3 halfVec = normalize(sun + vec3(0.0, 0.0, 1.0));
  dayColor += vec3(0.9, 0.95, 1.0) * pow(max(dot(n, halfVec), 0.0), 40.0) * 0.45 * ocean;

  float cityLum = dot(night, vec3(0.3, 0.5, 0.2));
  vec3 cities = vec3(1.0, 0.78, 0.45) * smoothstep(0.22, 0.6, cityLum) * 1.4;
  vec3 nightColor = day * 0.05 + cities;

  vec3 color = mix(nightColor, dayColor, lit);

  // Rim haze.
  float fresnel = pow(1.0 - z, 2.5);
  color = mix(color, ATMOSPHERE, fresnel * 0.65 * (0.4 + 0.6 * lit));

  float alpha = smoothstep(1.0, 1.0 - edge, d);
  fragColor = vec4(color * alpha, alpha);
}
