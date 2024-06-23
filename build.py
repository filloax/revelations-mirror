"""
Generate required files (generate entity lua file, merge shaders)
"""
import os, subprocess
import shutil
import sys
import re
import pkg_resources

def try_install(package):
    if package in {pkg.key for pkg in pkg_resources.working_set} is not None:
        return True
    else:
        inp = input(f"Missing package <{package}>, do you want to install it? [Y/n] ").strip().lower()
        if inp == '' or inp == 'y':
            subprocess.check_call([sys.executable, "-m", "pip", "install", package], stdout=sys.stdout, stderr=sys.stderr)
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
    if (try_install("lxml")):
        print("=== Merging shaders...")
        # easier to make subprocess than make a module for relative imports
        subprocess.check_call(["python", merge_shaders_path],
            bufsize=2048, 
            shell=True,
            # stdin=subprocess.PIPE, stdout=subprocess.PIPE, 
            close_fds=True,
        )
        # subprocessliveoutput(p)
        print("=== Merged shaders")
    else:
        print("Skip merge shaders, no lxml...")

def __run(args: list):
    print(f"> {' '.join(args)}")
    p = subprocess.Popen(args,
        bufsize=2048, 
        shell=True,
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, 
        close_fds=True,
    )
    p.stdin.write(b"\n\r")
    p.stdin.flush()
    subprocessliveoutput(p)
    p.wait()
    if p.returncode != 0:
        raise Exception("Process errored!", p.returncode)


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
    __run(["python", ent2lua_path,
        "content/entities2.xml",
    ])
    print()
    print("=== Ran entities2lua.py")

    chmoddir()
    os.remove("scripts/revelations/common/entities2.lua")
    os.rename(
        "content/entities2.lua",
        "scripts/revelations/common/entities2.lua",
    )
    print("Moved entities2.lua from content to scripts/revelations/common")

def makelibrary():
    with open("./scripts/tools/docs/requirements.txt", 'r') as f:
        reqs = [line.split("#")[0].strip() for line in f.readlines() if line.strip() != '']
    installed = all(try_install(req) for req in reqs)
    
    if installed:
        chmoddir()
        make_library_doc_path = os.path.abspath("./scripts/tools/docs/build_rev_library_docs.py")
        print("=== Making library doc...")
        # easier to make subprocess than make a module for relative imports
        __run([
            "python", make_library_doc_path,
            "scripts/revelations/common/library",
            "--exclude", "scripts/revelations/common/library/deprecated/*",
            "--globals-file", "scripts/tools/docs/globals.lua",
            "--table", "REVEL",
        ])
        print("=== Generated doc source, building docs...")

        chmoddir()
        os.chdir("docs")
        
        __run([
            "mkdocs", "build"
        ])
     
        print("=== Generated library doc")
    else:
        print("Skip build library, no requirements installed...")
        
def create_release():
    chmoddir()
    create_release_path = os.path.abspath("./scripts/tools/create_release.py")
    print("=== Creating workshop release files...")
    # easier to make subprocess than make a module for relative imports
    subprocess.check_call(["python", create_release_path],
        bufsize=2048, 
        shell=True,
        # stdin=subprocess.PIPE, stdout=subprocess.PIPE, 
        close_fds=True,
    )
    # subprocessliveoutput(p)
    print("=== Created workshop release files")

def main():
    chmoddir()
    
    print("Running with", sys.executable)
    
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
    
    create_release()
    
if __name__ == "__main__":
    main()