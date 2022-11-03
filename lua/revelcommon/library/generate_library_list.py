from io import FileIO
import os
import re

OUT_NAME = 'library.md'
EARLY_DIR_NAME = "early"

this_dir = os.path.dirname(os.path.realpath(__file__))

common_dir = this_dir
if os.path.split(this_dir)[1] == 'library':
    common_dir = os.path.abspath(os.path.join(this_dir, os.pardir)) #output in dir above library

base_dir = os.path.abspath(os.path.join(common_dir, os.pardir))

files = os.listdir(this_dir)
files = list(filter(lambda s: s.endswith('.lua'), files))

early_dir = os.path.join(this_dir, EARLY_DIR_NAME)
early_files = os.listdir(early_dir)

lists = {}

def check(name : str, f : FileIO):
    ignoreNext = False
    for line in f:
        if line.strip() == '-- DEPRECATED':
            ignoreNext = True
        elif ignoreNext:
            ignoreNext = False
        elif not re.search('^\s*--.*$', line):
            match = re.search('^\s*(?<!local\s)function\s*([\w\.\(\),\s]*)(?!--)', line)
            if match:
                func_name = match.group(1).strip()
                lists[name].append(func_name)
                print(func_name)

for file in early_files:
    name = file.split('.')[0]
    lists[name] = []

    print(f'\n\n\n{name.upper()}\n\n\n')

    with open(os.path.join(early_dir, file), "r") as f:
        check(name, f)

for file in files:
    name = file.split('.')[0]
    lists[name] = []

    print(f'\n\n\n{name.upper()}\n\n\n')

    with open(os.path.join(this_dir, file), "r") as f:
        check(name, f)

with open(os.path.join(common_dir, OUT_NAME), 'w') as outf:
    for name in lists:
        print(f'**{name.upper()}**:', file=outf)
        for func_name in lists[name]:
            print(func_name, file=outf)
        print('', file=outf)
