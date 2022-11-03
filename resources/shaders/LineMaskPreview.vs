// Only used for the weird mask constant creation tool
// I had to use back for Tomb since there are no 
// arbitrary masks

attribute vec3 Position;
attribute vec4 Color;
attribute vec2 TexCoord;
attribute vec4 RenderData;
attribute float Scale;

attribute float Active;
attribute float x1;
attribute float y1;
attribute float x2;
attribute float y2;
attribute float Expansion;
attribute float Feather;

varying vec4 Color0;
varying vec2 TexCoord0;
varying vec4 RenderDataOut;
varying float ScaleOut;

varying float ActiveOut;
varying vec2 P1;
varying vec2 P2;
varying float ExpansionOut;
varying float FeatherOut;

uniform mat4 Transform;
void main(void)
{
  RenderDataOut = RenderData;
  ScaleOut = Scale;
  Color0 = Color;
  TexCoord0 = TexCoord;
  ActiveOut = Active;
  P1 = vec2(x1,y1);
  P2 = vec2(x2,y2);
  ExpansionOut = Expansion;
  FeatherOut = Feather;

  gl_Position = Transform * vec4(Position.xyz, 1.0);
}
