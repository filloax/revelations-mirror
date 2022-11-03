// Only used for the weird mask constant creation tool
// I had to use back for Tomb since there are no 
// arbitrary masks

varying float Time;
varying vec4 Color0;
varying vec2 TexCoord0;
varying vec4 RenderDataOut;
varying float ScaleOut;

varying float ActiveOut;
varying vec2 P1;
varying vec2 P2;
varying float ExpansionOut;
varying float FeatherOut;

uniform sampler2D Texture0;

float distToLine(vec2 p1, vec2 p2, vec2 p)
{
  vec2 lineDir = p2 - p1;
  vec2 perpDir = vec2(lineDir.y, -lineDir.x);
  vec2 dirToPt1 = p1 - p;
  return abs(dot(normalize(perpDir), dirToPt1));
}

float plot(vec2 st, vec2 p1, vec2 p2)
{
    return pow( smoothstep( ExpansionOut + FeatherOut, ExpansionOut,  distToLine(p1, p2, st)), 2);
}

const vec3 W = vec3(1.0);

void main()
{
  if (ActiveOut > 0.0) {
    vec3 Color = texture2D(Texture0, TexCoord0.xy).rgb;

    vec2 st = gl_FragCoord.xy/RenderDataOut.xy;

    Color += W * plot(st, P1, P2);

    gl_FragColor.rgb = Color;
    gl_FragColor.a = 1.0;
  } else {
    gl_FragColor = texture2D(Texture0, TexCoord0.xy);
  }
}
