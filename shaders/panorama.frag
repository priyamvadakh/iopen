#version 460 core

#include <flutter/runtime_effect.glsl>

// Renders a cylindrical panorama with a perspective camera, so the photo can
// be "looked around" like a 360° viewer.

uniform vec2 uSize;
uniform float uYaw;      // camera heading, radians (0 = image centre)
uniform float uPitch;    // camera tilt, radians (positive = up)
uniform float uFov;      // vertical field of view, radians
uniform float uSpanX;    // horizontal angle the image covers, radians
uniform float uHalfTan;  // tan of half the image's vertical angle
uniform vec4 uSky;       // colour above the image
uniform vec4 uGround;    // colour below the image
uniform sampler2D uImage;

out vec4 fragColor;

void main() {
  vec2 ndc = (FlutterFragCoord().xy / uSize) * 2.0 - 1.0;
  float t = tan(uFov * 0.5);
  vec3 dir = normalize(vec3(ndc.x * t * uSize.x / uSize.y, -ndc.y * t, 1.0));

  float cp = cos(uPitch);
  float sp = sin(uPitch);
  dir = vec3(dir.x, dir.y * cp + dir.z * sp, -dir.y * sp + dir.z * cp);
  float cy = cos(uYaw);
  float sy = sin(uYaw);
  dir = vec3(dir.x * cy + dir.z * sy, dir.y, -dir.x * sy + dir.z * cy);

  float lon = atan(dir.x, dir.z);
  float height = dir.y / length(dir.xz);
  float u = lon / uSpanX + 0.5;
  float v = 0.5 - height / (2.0 * uHalfTan);

  vec4 color = texture(uImage, vec2(clamp(u, 0.001, 0.999), clamp(v, 0.001, 0.999)));
  if (v < 0.0) {
    color = mix(color, uSky, smoothstep(0.0, 0.12, -v));
  } else if (v > 1.0) {
    color = mix(color, uGround, smoothstep(0.0, 0.12, v - 1.0));
  }
  fragColor = vec4(color.rgb, 1.0);
}
