from PIL import Image
import xml.etree.ElementTree as ET
import os
import re
from datetime import datetime
from math import ceil
from xml.dom import minidom

SPRITESHEET_WIDTH = 9 #in number of images
DEFAULT_SIZE = (64, 48)

FIXED_BINDINGS = {
    'Firecaller (Glacier)': "firecaller.png",
    'Firecaller (Tomb)': "firecaller.png",
    'Cricket (boss)': "catastrophe.png",
    'Guppy (boss)': "catastrophe.png",
    'Tammy (boss)': "catastrophe.png",
    'Moxie (boss)': "catastrophe.png",
    'Flurry Head': "flurry_jr.png",
    'Flurry Body': "flurry_jr.png",
    'Flurry Frozen Body': "flurry_jr.png",
    'Freezer Burn Head': "freezer_burn.png",
    'Stalagmight 2': "stalagmight.png",
    'Stalagmight Spike': "stalagmight.png",
}

SPRITESHEET_NAME = "bestiary.png"
ANM2_NAME = "death enemies.anm2"

def get_matches(bestiary_files, entities, fixed_bindings):
    matches = {}
    matched = []
    for file in bestiary_files:
        formatted_name = re.sub('[\s_]', '', re.sub('\.png$', '', file)).lower().strip()
        for entity in entities:
            e_name = entity.attrib['name']
            formatted_e_name = re.sub('[\s_]', '', e_name).lower().strip()

            if formatted_name == formatted_e_name:
                matched.append(formatted_e_name)
                matches[e_name] = file

    for entity in entities:
        e_name = entity.attrib['name']
        if e_name in fixed_bindings:
            formatted_name = re.sub('[\s_]', '', re.sub('\.png$', '', fixed_bindings[e_name])).lower().strip()
            matched.append(formatted_name)
            matches[e_name] = fixed_bindings[e_name]
    

    for file in bestiary_files:
        formatted_name = re.sub('[\s_]', '', re.sub('\.png$', '', file)).lower().strip()
        if not formatted_name in matched:
            print(f'files: "{file}" not found in xml')

    # for entity in entities:
    #     e_name = entity.attrib['name']
    #     formatted_e_name = re.sub('[\s_]', '', e_name).lower().strip()
    #     if not formatted_e_name in matched:
    #         print(f'entities2.xml: "{e_name}" not found in files')

    for e_name in fixed_bindings:
        if not e_name in matches:
            print(f'Fixed matches: "{e_name}" not found in files')

    return matches

def stitch_spritesheet(bestiary_dir, bestiary_files, out_path):
    positions = {}

    # open images and calculate total widths and heights
    bestiary_paths = [os.path.join(bestiary_dir, f) for f in bestiary_files]
    total_width = 0
    total_height = 0

    images = list(map(Image.open, bestiary_paths))
    for image in images:
        if image.size != DEFAULT_SIZE:
            raise Exception(f"Wrong image size for {image.filename}: {image.size}")

    sprites_width = min(SPRITESHEET_WIDTH, len(images))
    sprites_height = ceil(len(images) / sprites_width)
    (total_width, total_height) = (DEFAULT_SIZE[0] * sprites_width, DEFAULT_SIZE[1] * sprites_height)

    # concat images
    new_im = Image.new('RGBA', (total_width, total_height))
    x_pos = 0
    y_offset = 0
    y_pos = 0
    for image in images:
        x_offset = x_pos * DEFAULT_SIZE[0]
        y_offset = y_pos * DEFAULT_SIZE[1]
        new_im.paste(image, (x_offset, y_offset))

        positions[os.path.basename(image.filename)] = (x_pos, y_pos)

        x_pos = x_pos + 1
        if x_pos >= SPRITESHEET_WIDTH:
            y_pos = y_pos + 1
            x_pos = 0

    # show and save
    new_im.save(out_path)

    return positions

def gen_frame(crop_x, crop_y):
    el = ET.fromstring('<Frame XPosition="0" YPosition="0" XPivot="32" YPivot="24" Width="64" Height="48" XScale="100" YScale="100" Delay="1" Visible="true" RedTint="255" GreenTint="255" BlueTint="255" AlphaTint="255" RedOffset="0" GreenOffset="0" BlueOffset="0" Rotation="0" Interpolated="false"/>')
    el.attrib['XCrop'] = str(crop_x)
    el.attrib['YCrop'] = str(crop_y)
    return el

def gen_anm2_def():
    root = ET.Element('AnimatedActor')
    info = ET.SubElement(root, 'Info')
    info.attrib['CreatedBy'] = 'genbestiary.py'
    info.attrib['CreatedOn'] = datetime.now().strftime("%d/%m/%Y %H:%M:%S")
    info.attrib['Version'] = '54'
    info.attrib['Fps'] = '30'

    content = ET.SubElement(root, 'Content')
    spritesheets = ET.SubElement(content, 'Spritesheets')
    spritesheet = ET.SubElement(spritesheets, 'Spritesheet')
    spritesheet.attrib['Path'] = SPRITESHEET_NAME
    spritesheet.attrib['Id'] = '0'
    layers = ET.SubElement(content, 'Layers')
    layer = ET.SubElement(layers, 'Layer')
    layer.attrib['Name'] = "Bestiary"
    layer.attrib['Id'] = '0'
    layer.attrib['SpritesheetId'] = '0'
    nulls = ET.SubElement(content, 'Nulls')
    events = ET.SubElement(content, 'Events')

    anim_name = "bestiary"
    animations = ET.SubElement(root, 'Animations')
    animations.attrib['DefaultAnimation'] = anim_name
    anim = ET.SubElement(animations, 'Animation')
    anim.attrib['Name'] = anim_name
    anim.attrib['FrameNum'] = '1'
    anim.attrib['Loop'] = 'false'

    root_anim = ET.SubElement(anim, 'RootAnimation')
    root_anim.append(ET.fromstring('<Frame XPosition="0" YPosition="0" XScale="100" YScale="100" Delay="1" Visible="true" RedTint="255" GreenTint="255" BlueTint="255" AlphaTint="255" RedOffset="0" GreenOffset="0" BlueOffset="0" Rotation="0" Interpolated="false"/>'))

    layer_anims = ET.SubElement(anim, 'LayerAnimations')
    layer_anim = ET.SubElement(layer_anims, 'LayerAnimation')
    layer_anim.attrib['LayerId'] = '0'
    layer_anim.attrib['Visible'] = "true"

    ET.SubElement(anim, 'NullAnimations')
    ET.SubElement(anim, 'Triggers')

    return root

def gen_bestiary_anm2(matches, positions):
    bestiary_frame_ids = {}

    root = gen_anm2_def()

    layer_anim = root.find('Animations').find('Animation').find('LayerAnimations').find('LayerAnimation')
    frame_num = 0

    for e_name in matches:
        filename = matches[e_name]
        position = positions[filename]
        (x_offset, y_offset) = (position[0] * DEFAULT_SIZE[0], position[1] * DEFAULT_SIZE[1])

        layer_anim.append(gen_frame(x_offset, y_offset))
        bestiary_frame_ids[e_name] = frame_num

        frame_num = frame_num + 1

    return root, bestiary_frame_ids

def update_xml_ids(xml_path, bestiary_frame_ids):
    parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=True))
    root = ET.parse(xml_path, parser=parser).getroot()

    entities = root.findall("entity")

    for entity in entities:
        name = entity.attrib['name']
        if name in bestiary_frame_ids:
            entity.attrib['portrait'] = str(bestiary_frame_ids[name])

    tree = ET.ElementTree(root)
    tree.write(xml_path, encoding='utf-8', xml_declaration=True)

def main():
    this_path = os.path.realpath(__file__)
    base_path = os.path.abspath(os.path.join(this_path, os.pardir, os.pardir, os.pardir))
    content_dir = os.path.join(base_path, "content")
    bestiary_dir = os.path.join(content_dir, "gfx", "bestiary")
    entities_xml = os.path.join(content_dir, "entities2.xml")
    spritesheet_path = os.path.join(content_dir, "gfx", SPRITESHEET_NAME)
    anm2_path = os.path.join(content_dir, "gfx", ANM2_NAME)

    root = ET.parse(entities_xml).getroot()

    entities = root.findall("entity")

    bestiary_files = [f for f in os.listdir(bestiary_dir) if os.path.isfile(os.path.join(bestiary_dir, f))]
    bestiary_files.sort()

    matches = get_matches(bestiary_files, entities, FIXED_BINDINGS)

    positions = stitch_spritesheet(bestiary_dir, bestiary_files, spritesheet_path)

    bestiary_anm2, frame_ids = gen_bestiary_anm2(matches, positions)

    anm2str = minidom.parseString(ET.tostring(bestiary_anm2)).toprettyxml(indent="   ")
    with open(anm2_path, "w") as f:
        f.write(anm2str)

    update_xml_ids(entities_xml, frame_ids)

if __name__ == '__main__':
    main()

