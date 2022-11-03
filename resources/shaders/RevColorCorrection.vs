attribute vec3 Position;
attribute vec4 Color;
attribute vec2 TexCoord;
attribute vec4 RenderData;
attribute float Scale;

attribute float ActiveIn;
attribute vec3 RGB;
attribute vec4 ShadRGB_Wgt;
attribute vec4 MidRGB_Wgt;
attribute vec4 HighRGB_Wgt;
attribute vec4 ContrLightSat_Legacy;
attribute vec4 ColBoostSelection; //In order: (all from 0 to 1, on standard hsv scale) range start, range end, feather, minimum saturation
attribute vec4 ColBoostRGBSat;  //In order: RGB mults, saturation
attribute vec3 Levels;

varying vec4 Color0;
varying vec2 TexCoord0;
varying vec4 RenderDataOut;
varying float ScaleOut;

varying float ActiveOut;

varying vec3 ShadRGBOut;
varying vec3 MidRGBOut;
varying vec3 HighRGBOut;
varying float ShadW;
varying float MidW;
varying float HighW;
varying vec3 RGBOut;

varying float ContrastOut;
varying float LightnessOut;
varying float SaturationOut;
varying float UseLegacyCL;

varying float LevelsMin;
varying float LevelsMax;
varying float Gamma;

varying float ColBoostSelStart;
varying float ColBoostSelEndShifted;
varying float ColBoostSelFeather;
varying float ColBoostSelSatStart;

varying vec3 ColBoostRGB;
varying float ColBoostSat;

uniform mat4 Transform;
void main(void)
{
    RenderDataOut = RenderData;
    ScaleOut = Scale;
    Color0 = Color;
    TexCoord0 = TexCoord;
    ActiveOut = ActiveIn;

    ShadRGBOut = ShadRGB_Wgt.rgb;
    MidRGBOut = MidRGB_Wgt.rgb;
    HighRGBOut = HighRGB_Wgt.rgb;
    ShadW = ShadRGB_Wgt.w;
    MidW = MidRGB_Wgt.w;
    HighW = HighRGB_Wgt.w;
    RGBOut = RGB;

    ContrastOut = ContrLightSat_Legacy.x;
    LightnessOut = ContrLightSat_Legacy.y;
    SaturationOut = ContrLightSat_Legacy.z;
    UseLegacyCL = ContrLightSat_Legacy.w;

    LevelsMin = Levels.x;
    LevelsMax = Levels.y;
    Gamma = Levels.z;

    ColBoostSelStart = ColBoostSelection.x;
    ColBoostSelFeather = ColBoostSelection.z;
    ColBoostSelEndShifted = ColBoostSelection.y;
    ColBoostSelEndShifted += -ColBoostSelStart + ColBoostSelFeather; //shift hue so the start of the range is at 0
    if (ColBoostSelEndShifted < 0.) ColBoostSelEndShifted += 1.;

    ColBoostSelSatStart = ColBoostSelection.w;

    ColBoostRGB = ColBoostRGBSat.rgb;
    ColBoostSat = ColBoostRGBSat.a;


    gl_Position = Transform * vec4(Position.xyz, 1.0);
}
