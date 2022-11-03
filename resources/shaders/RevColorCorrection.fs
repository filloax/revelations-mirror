#version 120

// 120 requires openGL 2.1, since base Isaac
// Rebirth requires 2.0 and Repentance probably
// more dare I say this should work for mostly everyone
#define USE_ARRAYS 1

#define DEBUG_BEFORE_AFTER 2
#define DEBUG_GRAYSCALE 3
#define DEBUG_SHADOWS 4
#define DEBUG_MIDTONES 5
#define DEBUG_HIGHLIGHTS 6
#define DEBUG_CHECK_ARRAYS 7
#define DEBUG_COL_BOOST_CHECK 8

varying float Time;
varying vec4 Color0;
varying vec2 TexCoord0;
varying vec4 RenderDataOut;
varying float ScaleOut;

varying float ActiveOut;

varying float ContrastOut;
varying float LightnessOut;
varying float SaturationOut;
varying float UseLegacyCL;

varying float LevelsMin;
varying float LevelsMax;
varying float Gamma;

varying vec3 RGBOut;
varying vec3 ShadRGBOut;
varying vec3 MidRGBOut;
varying vec3 HighRGBOut;
varying float ShadW;
varying float MidW;
varying float HighW;

varying float ColBoostSelStart;
varying float ColBoostSelEndShifted;
varying float ColBoostSelFeather;
varying float ColBoostSelSatStart;

varying vec3 ColBoostRGB;
varying float ColBoostSat;

uniform sampler2D Texture0;

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

#ifdef USE_ARRAYS
  float getColBoost(vec3 c) {
    vec3 hsv = rgb2hsv(c);
    float hues = hsv.x -ColBoostSelStart + ColBoostSelFeather; // shift hue so the start of the range is at 0
    if (hues < 0.) hues += 1.;

    float colBoost = smoothstep(0., ColBoostSelFeather, hues) *
                    (1. - smoothstep(ColBoostSelEndShifted, ColBoostSelEndShifted + ColBoostSelFeather, hues));

    if (ColBoostSelSatStart < 1.)
    {
      colBoost *= smoothstep(max(0., ColBoostSelSatStart - ColBoostSelFeather), ColBoostSelSatStart, hsv.y);
    }
    return clamp(colBoost, 0.0, 1.0);
  }

  const float[] blurMults = float[](0.1964825501511404, 0.2969069646728344, 0.09447039785044732, 0.010381362401148057);
  const vec2[] blurOffsets = vec2[](vec2(0.0), vec2(1.411764705882353), vec2(2.5941176470588234), vec2(3.876470588235294));

  float _blurColBoost(vec2 texc, vec2 dir) {
    float colBoost = 0.0, sgn = -1.;
    vec2 samplec;
    int index, i;
    for (i = 0; i < 8; i++) {
      index = i / 2;
      sgn = -sgn;
      samplec = (texc + blurOffsets[index] / RenderDataOut.zw * dir * sgn);
      colBoost += getColBoost(texture2D(Texture0, samplec).rgb) * blurMults[index];
    }
    return colBoost;
  }

  float blurColBoost(vec3 c, vec2 texc, vec2 dir) {
    float colBoost = 0.0, sgn = -1.;
    vec2 samplec;
    int index, i;
    for (i = 0; i < 8; i++) {
      index = i / 2;
      sgn = -sgn;
      samplec = (texc + blurOffsets[index] / RenderDataOut.zw * dir * sgn);
      colBoost += _blurColBoost(samplec, dir.yx);
    }
    return colBoost;
  }
#else
  float getColBoost(vec3 c) {
    return 0.;
  }
  float blurColBoost(vec3 c, vec2 coord, vec2 dir) {
    return 0.;
  }
#endif

vec3 gammaCorrect(vec3 color, float gamma){
    return pow(color, vec3(1.0/gamma));
}

vec3 inputRange(vec3 color, float minInput, float maxInput){
    return min(max(color - vec3(minInput), vec3(0.0)) / (vec3(maxInput) - vec3(minInput)), vec3(1.0));
}

vec3 finalLevels(vec3 color, float minInput, float gamma, float maxInput){
    return gammaCorrect(inputRange(color, minInput, maxInput), gamma);
}

const vec3 FullW = vec3(1.);
const vec3 FullGrey = vec3(.5);
const vec3 W = vec3(0.2125, 0.7154, 0.0721); // Used for sRGB
const vec3 Grey = W*0.5;
const vec2 ZeroOne = vec2(0.,1.); // used for optimization

void main()
{
    if (ActiveOut < 0.0001) { //immediately exit if shaders off
        gl_FragColor = texture2D(Texture0, TexCoord0.xy);
    } else {
        vec4 FColor = texture2D(Texture0, TexCoord0);

        int iactive = int(floor(ActiveOut));
        if (iactive > 0 && !(iactive == DEBUG_BEFORE_AFTER && gl_FragCoord.x < RenderDataOut.x/2.)) {
            vec3 Color = FColor.rgb;

            Color = finalLevels(Color, LevelsMin, Gamma+1.0, LevelsMax+1.0);

            float colBoost = 0.;
            if (ColBoostSelSatStart < 1.)
            {
                colBoost = blurColBoost(Color, TexCoord0, vec2(1.,0.));
            }

            float avgRGB = dot(Color, W);

            Color = mix(vec3(avgRGB), Color, SaturationOut + colBoost * ColBoostSat + 1.0); //Saturation, from OpenGL Chapter 16

            vec3 lightnessEnd = (UseLegacyCL > 0.1) ? W : FullW;
            vec3 contrastEnd = (UseLegacyCL > 0.1) ? Grey : FullGrey;

            Color = mix(Color, lightnessEnd, LightnessOut); // Lightness
            Color = mix(Color, contrastEnd, -ContrastOut); // Contrast

            float shadMult = min(1., 1.6 * exp(-ShadW * avgRGB * avgRGB ) );
            Color *= mix(FullW, ShadRGBOut, shadMult); //Shadows Tint

            float highMult = min(1., 2.4 * exp(-HighW * (avgRGB - 1.0) * (avgRGB - 1.0) ) );
            Color *= mix(FullW, HighRGBOut, highMult); //Highlights Tint

            float midMult = min(1., 1.8*exp(-MidW * (avgRGB - 0.5) * (avgRGB - 0.5) ) );
            Color *= mix(FullW, MidRGBOut, midMult); //Midtones Tint

            Color *= RGBOut; // Global Tint

            Color = mix(Color, Color * ColBoostRGB, colBoost);

            if (iactive < 3)
                gl_FragColor = Color.rgbr * ZeroOne.yyyx + ZeroOne.xxxy; // optimization as found in https://www.khronos.org/opengl/wiki/GLSL_Optimizations#Assignment_with_MAD
            else if (iactive == DEBUG_COL_BOOST_CHECK) // Color boost check
                gl_FragColor = vec4(vec3(colBoost), 1.);
            else if (iactive == DEBUG_CHECK_ARRAYS) // array support check
                #ifdef USE_ARRAYS
                    gl_FragColor = Color.rgbr * ZeroOne.xyxx + ZeroOne.xxxy;
                #else
                    gl_FragColor = Color.rgbr * ZeroOne.yxxx + ZeroOne.xxxy;
                #endif
            else if (iactive == DEBUG_HIGHLIGHTS) // highlights
                gl_FragColor = vec4(vec3(highMult), 1.);
            else if (iactive == DEBUG_MIDTONES) // MIDTONES
                gl_FragColor = vec4(vec3(midMult), 1.);
            else if (iactive == DEBUG_SHADOWS) // Shadows
                gl_FragColor = vec4(vec3(shadMult), 1.);
            else if (iactive == DEBUG_GRAYSCALE) // greyscale
                gl_FragColor = vec4(vec3(avgRGB), 1.);
        }
        else {
            gl_FragColor = FColor;
        }
    }
}
