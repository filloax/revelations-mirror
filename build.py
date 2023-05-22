"""
Generate required files (generate entity lua file, merge shaders)
"""
import os, subprocess
import sys
import re
import pip

def import_or_install(package):
    try:
        __import__(package)
        return True
    except ImportError:
        inp = input(f"Missing package <{package}>, do you want to install it? [Y/n] ").strip().lower()
        if inp == '' or inp == 'y':
            pip.main(['install', package])
            __import__(package)
            return True
        else:
            return False

def chmoddir():
    # Change working dir to script path (mod folder)
    abspath = os.path.abspath(__file__)
    dname = os.path.dirname(abspath)
    os.chdir(dname)

def subprocessliveoutput(process):
    for c in iter(lambda: process.stdout.read(1), b""):
        sys.stdout.buffer.write(c)

def mergeshaders():
    chmoddir()
    merge_shaders_path = os.path.abspath("./resources/shaders/merge_shaders.py")
    if (import_or_install("lxml")):
        print("=== Merging shaders...")
        # easier to make subprocess than make a module for relative imports
        p = subprocess.Popen(["python", merge_shaders_path],
            bufsize=2048, 
            shell=True,
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, 
            close_fds=True,
        )
        subprocessliveoutput(p)
        print("=== Merged shaders")
    else:
        print("Skip merge shaders, no lxml...")

def entities2lua(mods_folder_abs):
    if mods_folder_abs:
        pass
    else:
        print("Not running stageapi ent2lua entities, mods folder not found")
        return   

    stageapi_dir = list(filter(lambda path: re.search("stageapi", path), os.listdir(mods_folder_abs)))[0]
    if stageapi_dir:
        pass
    else:
        print("Not running stageapi ent2lua entities, stageapi folder not found")
        return   

    stageapi_path = os.path.join(mods_folder_abs, stageapi_dir)
    ent2lua_path = os.path.join(stageapi_path, "basementrenovator/scripts/entities2lua.py")

    print("=== Running entities2lua.py")
    p = subprocess.Popen(["python", ent2lua_path,
                "content/entities2.xml",
            ],
        bufsize=2048, 
        shell=True,
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, 
        close_fds=True,
    )
    p.stdin.write(b"\n\r")
    p.stdin.flush()
    subprocessliveoutput(p)
    print()
    print("=== Ran entities2lua.py")

    chmoddir()
    os.remove("lua/revelcommon/entities2.lua")
    os.rename(
        "content/entities2.lua",
        "lua/revelcommon/entities2.lua",
    )
    print("Moved entities2.lua from content to lua/revelcommon")

def makelibrary():
    chmoddir()
    make_library_doc_path = os.path.abspath("./lua/revelcommon/library/generate_library_list.py")
    print("=== Making library doc...")
    # easier to make subprocess than make a module for relative imports
    p = subprocess.Popen(["python", make_library_doc_path, "-s"],
        bufsize=2048, 
        shell=True,
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, 
        close_fds=True,
    )
    p.stdin.write(b"\n\r")
    p.stdin.flush()
    subprocessliveoutput(p)
    print("=== Generated library doc")


def main():
    chmoddir()
    
    steam_folder = [
        "C:/Program Files (x86)/Steam/steamapps/common/",
        "/mnt/c/Program Files (x86)/Steam/steamapps/common/",
        "~/.steam/steam/SteamApps/common",
    ]
    mods_folder = "The Binding of Isaac Rebirth/mods"
    mods_folder_abs = None

    for steam_path_option in steam_folder:
        if os.path.exists(os.path.join(steam_path_option, mods_folder)):
            mods_folder_abs = os.path.join(steam_path_option, mods_folder)
            break

    if not mods_folder_abs:
        print("Mod folder not found!")
    else:
        print("Mod folder at", mods_folder_abs)

    mergeshaders()
    entities2lua(mods_folder_abs)
    makelibrary()
    
if __name__ == "__main__":
    main()