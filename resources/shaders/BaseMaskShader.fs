// Unused, saved separately for ease of storing. The one used is in the xml.
//Basis for shader that gets automatically generated

varying float Time;
varying vec4 Color0;
varying vec2 TexCoord0;
varying vec4 RenderDataOut;
varying float ScaleOut;

varying float ActiveOut;
varying float SelectedMaskOut;
varying float ContrastOut;
varying float LightnessOut;
varying float SaturationOut;

varying vec3 RGBOut;

varying vec2 nBr;
varying vec2 nTl;

uniform sampler2D Texture0;

float distToLine(vec2 p1, vec2 p2, vec2 p)
{
  vec2 lineDir = p2 - p1;
  vec2 perpDir = vec2(lineDir.y, -lineDir.x);
  vec2 dirToPt1 = p1 - p;
  return abs(dot(normalize(perpDir), dirToPt1));
}

float plotLine(vec2 st, vec2 p1, vec2 p2, float e, float f, vec2 orBr, vec2 orTl)
{
    vec2 c = (nBr+nTl)/2.; //center
    vec2 orc = (orBr+orTl)/2.; // original center
    float scale = (nBr.x - c.x)/(orBr.x - orc.x);
    vec2 translate = c - orc;

    vec2 transP1 = c + (p1 - c + translate) * scale;
    vec2 transP2 = c + (p2 - c + translate) * scale;
    return pow( smoothstep( (e + f) * scale, e * scale,  distToLine(transP1, transP2, st)), 1.5);
}

//turn into equalized normalized coordinates, meaning the x axis stays the same,
//but the y axis is 1 where the x axis would be (in other words, as if the screen was square)
//circle center is already saved this way
vec2 equalizeNormVec(vec2 v)
{
  return vec2(v.x, v.y / RenderDataOut.x * RenderDataOut.y);
}

float plotCircle(vec2 st, vec2 cnt, float r, float f, vec2 orBr, vec2 orTl)
{
  vec2 stx = equalizeNormVec(st);

  vec2 c = (nBr+nTl)/2.; //center of screen
  vec2 orc = (orBr+orTl)/2.; // original center of screen, not to be confused with Shrek's species
  float scale = (nBr.x - c.x)/(orBr.x - orc.x);
  vec2 translate = equalizeNormVec(c - orc);
  vec2 eqc = equalizeNormVec(c);

  vec2 transCnt = eqc + (cnt - eqc + translate) * scale;
  return pow( smoothstep( (r + f) * scale, r * scale,  distance(transCnt, stx)), 1.5);
}


//Line Masks

//LINES

//Circle masks

//CIRCLES

//Original room boundaries

//ROOMBOUNDS
const vec3 FullW = vec3(1.0);
const vec3 Grey = FullW * 0.5;
const vec3 W = vec3(0.2125, 0.7154, 0.0721); //Used for sRGB

const vec2 EdgeOffset = vec2(0.08);
const vec2 EdgeFeather = vec2(0.04);

void main()
{
  int selec = int(SelectedMaskOut);
  if (ActiveOut > 0.0 && selec > 0) {
    vec3 Color = texture2D(Texture0, TexCoord0.xy).rgb;

    vec2 st = gl_FragCoord.xy/RenderDataOut.xy;

    float avgRGB = dot(Color, W);

    float mask = 0.0;

//MASKMODS

    mask = min(1.0, mask);

    if (mask > 0.) {
      vec2 eo = EdgeOffset * ScaleOut;
      vec2 ef = EdgeFeather * ScaleOut;
      vec2 edge1 = smoothstep(nTl - eo - ef, nTl - eo, st);
      vec2 edge2 = vec2(1.) - smoothstep(nBr + eo, nBr + eo + ef, st);

      mask *= edge1.x * edge1.y * edge2.x * edge2.y;
    }

    mask *= ActiveOut;

    if (mask > 0.) {
      // Global Tint
      Color = mix(Color, Color * RGBOut, mask);

      //Saturation, from OpenGL Chapter 16
      vec3 intensity = vec3(avgRGB);
      Color = mix(intensity, Color, SaturationOut*mask+1.0);

      //Lightness
      Color = mix(Color, FullW, LightnessOut*mask);

      //Contrast
      Color = mix(Color, Grey, -ContrastOut*mask);
    }
    gl_FragColor.rgb = Color;
    gl_FragColor.a = 1.0;
  } else {
    gl_FragColor = texture2D(Texture0, TexCoord0.xy);
  }
}
