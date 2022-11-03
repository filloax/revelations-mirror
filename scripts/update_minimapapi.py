import os
import shutil

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
