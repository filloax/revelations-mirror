import argparse
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description='Convert anm2 nulls into lua tables')
parser.add_argument('-i', '--input', required=True, help='anm2 file containing the animation')
parser.add_argument('-n', '--nullname', required=True, help='name of the null layer')
parser.add_argument('-a', '--anim', required=False, help='animation name')
parser.add_argument('-o', '--output', help='lua output file name')
parser.add_argument('--no_round', default=False, action='store_true', help='don\'t round interpolated values')

def get_frame_pos(frame):
    x = int(frame.attrib['XPosition'])
    y = int(frame.attrib['YPosition'])
    return (x, y)

def get_frame_scale(frame):
    x = int(frame.attrib['XScale'])
    y = int(frame.attrib['YScale'])
    return (x, y)

def get_frame_visible(frame):
    return frame.attrib['Visible'] == 'true'

def get_frame_alpha(frame):
    return int(frame.attrib['AlphaTint'])

def vec_to_lua(vec):
    return "Vector({}, {})".format(*vec)

def lerp(a, b, t):
    if type(a) is int:
        return round(a * (1-t) + b * t)
    else:
        x = a[0] * (1-t) + b[0] * t
        y = a[1] * (1-t) + b[1] * t
        if not args.no_round:
            x, y = round(x), round(y)
        return (x, y)

args = parser.parse_args()

root = ET.parse(args.input).getroot()
anims = root.find('Animations')
nulls = root.find('Content').find('Nulls')

layer = nulls.find("Null[@Name='{}']".format(args.nullname))
layer_id = layer.attrib['Id']

animList = []
if (args.anim == None):
    animList = anims.findall("Animation")
else:
    animList = [anims.find("Animation[@Name='{}']".format(args.anim))]

out = ""

for anim in animList:
    name = anim.attrib['Name']
    nullanim = anim.find('NullAnimations').find("NullAnimation[@NullId='{}']".format(layer_id))
    if nullanim is None:
        continue

    positions = []
    scales = []
    alpha = []
    visible = []

    frames = nullanim.findall('Frame')
    it = iter(frames)
    try:
        nextf = next(it)
    except StopIteration:
        continue #no null in this anim
    done = False

    while not done:
        try:
            frame, nextf = nextf, next(it)
            dur = int(frame.attrib['Delay'])
            do_lerp = frame.attrib['Interpolated'] == "true"
            this_pos, this_scale = get_frame_pos(frame), get_frame_scale(frame)
            next_pos, next_scale = get_frame_pos(nextf), get_frame_scale(nextf)
            this_alpha = get_frame_alpha(frame)
            next_alpha = get_frame_alpha(frame)
            this_visible = get_frame_visible(frame)
            if do_lerp:
                for i in range(dur):
                    positions.append(lerp(this_pos, next_pos, i / dur))
                    scales.append(lerp(this_scale, next_scale, i / dur))
                    alpha.append(lerp(this_alpha, next_alpha, i / dur))
                    visible.append(this_visible)
            else:
                for i in range(dur):
                    positions.append(this_pos)
                    scales.append(this_scale)
                    alpha.append(this_alpha)
                    visible.append(this_visible)
        except StopIteration:
            done = True
            frame = nextf
            dur = int(frame.attrib['Delay'])
            for i in range(dur):
                positions.append(get_frame_pos(frame))
                scales.append(get_frame_scale(frame))
                alpha.append(get_frame_alpha(frame))
                visible.append(get_frame_visible(frame))

    out += name + " = {\n    Offset = {"
    out += ", ".join([vec_to_lua(pos) for pos in positions])
    out += "},\n    Scale = {"
    out += ", ".join([vec_to_lua(scale) for scale in scales])
    out += "},\n    Alpha = {"
    out += ", ".join([str(a) for a in alpha])
    out += "},\n    Visible = {"
    out += ", ".join([str(v).lower() for v in visible])
    out += "}\n},\n"

print(out)

if args.output:
    f = open(args.output, "w")
    f.write(out + "\n")
    f.close()
    print("Written to {}!".format(args.output))
