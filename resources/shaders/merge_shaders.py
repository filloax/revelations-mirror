import xml.etree.ElementTree as ET
from os.path import exists

"""
Merge shaders from the shader files into shaders.xml, 
only uses those that can be found in the xml so new ones 
first need to have their entry, including parameters, defined 
there with blank code
"""

def escape_cdata(text):
    # escape character data
    try:
        if not text.startswith("<![CDATA[") and not text.endswith("]]>"):
            if "&" in text:
                text = text.replace("&", "&amp;")
            if "<" in text:
                text = text.replace("<", "&lt;")
            if ">" in text:
                text = text.replace(">", "&gt;")
        return text
    except (TypeError, AttributeError):
        ET._raise_serialization_error(text)

ET._escape_cdata = escape_cdata


shader_file_path = '../../content/shaders.xml'

tree = ET.parse(shader_file_path)
root = tree.getroot()

shaders = root.findall('shader')

for shader in shaders:
    name = shader.attrib['name']
    if exists(f'{name}.fs') and exists(f'{name}.vs'):
        with open(f'{name}.vs') as vert_file:
            shader.find('vertex').text = f"<![CDATA[{vert_file.read()}]]>"
        with open(f'{name}.fs') as frag_file:
            shader.find('fragment').text = f"<![CDATA[{frag_file.read()}]]>"
        print(f"Updated shader '{name}'")
    elif (exists(f'{name}.fs') and not exists(f'{name}.vs')
          or not exists(f'{name}.fs') and exists(f'{name}.vs')):
        print("Warning: you have only the fragment or "
            + f"only the vertex shader file for shader '{name}'")

tree.write(shader_file_path, encoding = 'UTF-8')
print("Successfully written shaders.xml")
