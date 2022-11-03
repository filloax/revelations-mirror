// Only used for the weird mask constant creation tool
// I had to use back for Tomb since there are no 
// arbitrary masks

varying float Time;
varying vec4 Color0;
varying vec2 TexCoord0;
varying vec4 RenderDataOut;
varying float ScaleOut;

varying float ActiveOut;
varying vec2 C;
varying float RadiusOut;
varying float FeatherOut;

uniform sampler2D Texture0;

float plot(vec2 stx, vec2 c)
{
    return pow( smoothstep( RadiusOut + FeatherOut, RadiusOut,  distance(c, stx)), 2);
}

const vec3 W = vec3(1.0);

void main()
{
  if (ActiveOut > 0.0) {
    vec3 Color = texture2D(Texture0, TexCoord0.xy).rgb;

    vec2 stx = gl_FragCoord.xy/vec2(RenderDataOut.x);

    Color += W * plot(stx, C);

    gl_FragColor.rgb = Color;
    gl_FragColor.a = 1.0;
  } else {
    gl_FragColor = texture2D(Texture0, TexCoord0.xy);
  }
}
