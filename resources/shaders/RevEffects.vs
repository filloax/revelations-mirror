attribute vec3 Position;
attribute vec4 Color;
attribute vec2 TexCoord;
attribute vec4 RenderData;
attribute float Scale;

attribute float ActiveIn;
attribute vec3 TypeVariantDebug;
attribute vec3 RGB;
attribute vec3 ContrLightSat;
attribute vec4 nTlBr;

varying vec4 Color0;
varying vec2 TexCoord0;
varying vec4 RenderDataOut;
varying float ScaleOut;

varying float Active;
varying float Type; //type 1: tomb masks
varying float Variant; //for type 1: selected mask
varying float Debug; //shadersOn in lua
varying float Contrast;
varying float Lightness;
varying float Saturation;

varying vec2 nTl;
varying vec2 nBr;

varying vec3 RGBOut;

uniform mat4 Transform;
void main(void)
{
    RenderDataOut = RenderData;
    ScaleOut = Scale;
    Color0 = Color;
    TexCoord0 = TexCoord;
    Active = ActiveIn;
    Type = TypeVariantDebug.x;
    Variant = TypeVariantDebug.y;
    Debug = TypeVariantDebug.z;
    Contrast = ContrLightSat.x;
    Lightness = ContrLightSat.y;
    Saturation = ContrLightSat.z;

    RGBOut = RGB;

    nTl = nTlBr.xy;
    nBr = nTlBr.zw;

    gl_Position = Transform * vec4(Position.xyz, 1.0);
}
