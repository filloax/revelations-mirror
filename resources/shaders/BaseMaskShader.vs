// Base version of the shader used for all TombMask frag shaders
// to be completed with various cases generated with the appropriate
// in-mod tool (long story) that use constants (yes)

attribute vec3 Position;
attribute vec4 Color;
attribute vec2 TexCoord;
attribute vec4 RenderData;
attribute float Scale;

attribute float Active;
attribute float Contrast;
attribute float Lightness;
attribute float Saturation;
attribute float R;
attribute float G;
attribute float B;
attribute vec4 nTlBr;

varying vec4 Color0;
varying vec2 TexCoord0;
varying vec4 RenderDataOut;
varying float ScaleOut;

varying float ActiveOut;
varying float SelectedMaskOut;
varying float ContrastOut;
varying float LightnessOut;
varying float SaturationOut;

varying float ROut;
varying float GOut;
varying float BOut;

varying vec2 nTl;
varying vec2 nBr;

varying vec3 RGBOut;

uniform mat4 Transform;
void main(void)
{
  vec3 RGB = vec3(R, G, B);

  RenderDataOut = RenderData;
  ScaleOut = Scale;
  Color0 = Color;
  TexCoord0 = TexCoord;
  ActiveOut = Active;
  if (Active > 0.) {
    float afloor = floor(Active);
    float afrag = Active - afloor;
    SelectedMaskOut = afloor;
    if (afrag > 0.99)
      ActiveOut = 1.;
    else
      ActiveOut = afrag;
  } else {
    SelectedMaskOut = 0.;
    ActiveOut = 0.;
  }
  ContrastOut = Contrast;
  LightnessOut = Lightness;
  SaturationOut = Saturation;

  RGBOut = RGB;

  nBr = vec2(nBrX, nBrY);
  nTl = vec2(nTlX, nTlY);

  gl_Position = Transform * vec4(Position.xyz, 1.0);
}
