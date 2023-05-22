from ast import arg
import xml.etree.ElementTree as ET
import os
import argparse
import sys

parser = argparse.ArgumentParser(description='List entities2.xml used id ranges in the mod, and optionally get random one')

entitiesfile = os.path.join(os.path.dirname(__file__), "entities2.xml")

def main(args):
    root = ET.parse(entitiesfile).getroot()
    entities = root.findall('entity')
    ids = list(map(lambda entity: int(entity.attrib['id']), entities))

    ids.sort()
    idranges = []
    crange = []
    for id in ids:
        if len(crange) == 0 or crange[-1] + 1 == id:
            crange.append(id)
        elif not (len(crange) != 0 and crange[-1] == id):
            idranges.append(crange)
            crange = []
    if len(crange) != 0:
        idranges.append(crange)

    idranges.sort(key=lambda x: x[0])
    idrangesstr = list(map(lambda range: f"{range[0]} - {range[-1]}", idranges))
    print("Used id ranges:")
    for s in idrangesstr:
        print(f"\t{s}")

    effect_variants = list(map(lambda entity: int(entity.attrib['variant']), filter(lambda entity: int(entity.attrib['id']) == 1000, entities)))
    evar_ranges = []
    evar_crange = []
    for var in effect_variants:
        if len(evar_crange) == 0 or evar_crange[-1] + 1 == var:
            evar_crange.append(var)
        elif not (len(evar_crange) != 0 and evar_crange[-1] == var):
            evar_ranges.append(evar_crange)
            evar_crange = []
    if len(evar_crange) != 0:
        evar_ranges.append(evar_crange)

    evar_ranges.sort(key=lambda x: x[0])
    evar_ranges_str = list(map(lambda range: f"{range[0]} - {range[-1]}" if len(range) > 1 else range[0], evar_ranges))
    print("Used effect variant ranges:")
    for s in evar_ranges_str:
        print(f"\t{s}")




if __name__ == "__main__":
    main(parser.parse_args())
