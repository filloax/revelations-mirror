import os
import shutil
import re

script_dir = os.path.dirname(os.path.realpath(__file__))
mods_dir = os.path.abspath(os.path.join(script_dir, os.path.pardir, os.path.pardir))
minimapapi_scripts_dir = os.path.join(mods_dir, "minimapi", "scripts")

exclude_files = [
    'version.lua'
]

os.remove(os.path.join(script_dir, "minimapapi.lua"))

for rootpath, dirs, files in os.walk(os.path.join(script_dir, "minimapapi")):
    for file in files:
        if file not in exclude_files:
            os.remove(os.path.join(rootpath, file))

# copy

shutil.copyfile(os.path.join(minimapapi_scripts_dir, "minimapapi.lua"), os.path.join(script_dir, "minimapapi.lua"))
for rootpath, dirs, files in os.walk(os.path.join(minimapapi_scripts_dir, "minimapapi")):
    rel_path = os.path.relpath(rootpath, minimapapi_scripts_dir)
    for file in files:
        if file not in exclude_files:
            shutil.copyfile(os.path.join(rootpath, file), os.path.join(script_dir, rel_path, file))

# update_version
ver_major = None
ver_minor = None

with open(os.path.join(minimapapi_scripts_dir, "minimapapi/version.lua"), 'r') as f:
    for line in f.readlines():
        match_major = re.search(r'MinimapAPI\.MajorVersion = (\d+)', line)
        if match_major:
            ver_major = int(match_major.group(1))
        match_minor = re.search(r'MinimapAPI\.MinorVersion = (\d+)', line)
        if match_minor:
            ver_minor = int(match_minor.group(1))
        if match_major and match_minor:
            break

with open(os.path.join(script_dir, "minimapapi/version.lua"), 'r') as f:
    with open(os.path.join(script_dir, "minimapapi/version.lua.tmp"), 'w') as fw:
        for line in f.readlines():
            if re.search(r'MinimapAPI\.MajorVersion = (\d+)', line):
                print(f"MinimapAPI.MajorVersion = {ver_major}", file=fw)
            elif re.search(r'MinimapAPI\.MinorVersion = (\d+)', line):
                print(f"MinimapAPI.MinorVersion = {ver_minor}", file=fw)
            else:
                print(line, file=fw)

os.remove(os.path.join(script_dir, "minimapapi/version.lua"))
os.rename(os.path.join(script_dir, "minimapapi/version.lua.tmp"), os.path.join(script_dir, "minimapapi/version.lua"))
