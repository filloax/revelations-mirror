import os
import shutil

script_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), os.path.pardir)
mods_dir = os.path.abspath(os.path.join(script_dir, os.path.pardir, os.path.pardir))
hub2_scripts_dir = os.path.join(mods_dir, "hub-room-2.0", "scripts")

exclude_files = [
]

os.remove(os.path.join(script_dir, "hubroom2.lua"))

for rootpath, dirs, files in os.walk(os.path.join(script_dir, "hubroom2")):
    for file in files:
        if file not in exclude_files:
            os.remove(os.path.join(rootpath, file))

# copy

shutil.copyfile(os.path.join(hub2_scripts_dir, "hubroom2.lua"), os.path.join(script_dir, "hubroom2.lua"))
for rootpath, dirs, files in os.walk(os.path.join(hub2_scripts_dir, "hubroom2")):
    rel_path = os.path.relpath(rootpath, hub2_scripts_dir)
    for file in files:
        if file not in exclude_files:
            shutil.copyfile(os.path.join(rootpath, file), os.path.join(script_dir, rel_path, file))
