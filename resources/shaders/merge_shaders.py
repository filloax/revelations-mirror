import lxml.etree as etree
from os.path import exists
import os

"""
Merge shaders from the shader files into shaders.xml, 
only uses those that can be found in the xml so new ones 
first need to have their entry, including parameters, defined 
there with blank code
"""

def main():
    current_path = os.path.dirname(os.path.abspath(__file__))
    shader_file_path = os.path.join(current_path, '../../content/shaders.xml')

    parser = etree.XMLParser(strip_cdata=False)
    tree = etree.parse(shader_file_path, parser)
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

    with open(shader_file_path, 'w', encoding='UTF-8') as f:
        f.write(etree.tostring(root, pretty_print=True).decode('UTF-8'))
    print("Successfully written shaders.xml")

if __name__ == '__main__':
    main()
