// Only used for the weird mask constant creation tool
// I had to use back for Tomb since there are no 
// arbitrary masks

attribute vec3 Position;
attribute vec4 Color;
attribute vec2 TexCoord;
attribute vec4 RenderData;
attribute float Scale;

attribute float Active;
attribute float x;
attribute float y;
attribute float Radius;
attribute float Feather;

varying vec4 Color0;
varying vec2 TexCoord0;
varying vec4 RenderDataOut;
varying float ScaleOut;

varying float ActiveOut;
varying vec2 C;
varying float RadiusOut;
varying float FeatherOut;

uniform mat4 Transform;
void main(void)
{
  RenderDataOut = RenderData;
  ScaleOut = Scale;
  Color0 = Color;
  TexCoord0 = TexCoord;
  ActiveOut = Active;
  C = vec2(x,y);
  RadiusOut = Radius;
  FeatherOut = Feather;

  gl_Position = Transform * vec4(Position.xyz, 1.0);
}
