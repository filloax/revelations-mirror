import os
import shutil
import sys
from tqdm import tqdm
import fnmatch 
import re
from collections import defaultdict

# Define filter rules
filter_rules = [
    "build",
    "*.zip",
    "*.csv",
    "*.psd",
    "*.pyc",
    "*.prproj", # the ragtime beatmap example, before anyone asks (I had a hammer and it looked like a nail ok)
    "**/testrooms/*.lua",
    ".git",
    ".git/**",
    ".gitignore",
    ".luacheckrc",
    ".vscode",
    ".vscode/**",
    ".luarc.json",
    "monster_manual_MEGA.pdf",
    "SplashPrime_Mirror_Album_700x.jpg",
    "basementrenovator/stbs/**",
    "basementrenovator/testrooms/*.lua",
    "basementrenovator/testrooms/*.stb",
    "docs/**",
    "scripts/tools/**",
    "requirements.txt",
]

fdir = os.path.dirname(__file__)
root_dir = os.path.abspath(os.path.join(fdir, os.path.pardir, os.path.pardir))
dist_dir = os.path.join(root_dir, "build", "release")

with open(os.path.join(root_dir, ".gitignore"), "r") as f:
    for line in f.readlines():
        filter_rules.append(line.replace("\n", ""))
filter_rules = set(filter_rules)

def sync_folders(src = root_dir, dest = dist_dir, verbose = False):
    # Create destination folder if it doesn't exist
    if os.path.exists(dest):
        shutil.rmtree(dest)

    # Walk through the source folder
    to_copy = []
    
    __check_recurse(to_copy, src)
    
    # shutil.copytree(src, dest, ignore=__get_ignore)
    
    by_extension = defaultdict(lambda: 0)

    for src_file in tqdm(to_copy, desc="Copy matching files..."):
        rel_file = os.path.relpath(src_file, src)
        dest_file = os.path.join(dest, rel_file)
        
        # Create directories in the destination path
        if not os.path.exists(os.path.dirname(dest_file)):
            os.makedirs(os.path.dirname(dest_file))

        shutil.copy2(src_file, dest_file)
        
        if verbose:
            tqdm.write(src_file)
            
        by_extension[os.path.splitext(src_file)[1]] += 1
           
    # stats
    print("Release stats:")
    by_extension = [(ext, count) for ext, count in by_extension.items()]
    for ext, count in sorted(by_extension, key=lambda x: x[1], reverse=True):
        print(f"\t{ext} files: {count}")
    
def __check_recurse(out: list, src: str):
    for name in os.listdir(src):
        abs_path = os.path.abspath(os.path.join(src, name))
        rel_path = os.path.relpath(abs_path)
        
        if __should_exclude(rel_path):
            continue
        
        __check_path(rel_path)
        
        if os.path.isfile(abs_path):
            out.append(abs_path)
        elif os.path.isdir(abs_path):
            __check_recurse(out, abs_path)
        else:
            print(f"[WARN] Neither file or dir: {abs_path}", file=sys.stderr)
    
# def __get_ignore(src, names):
#     return [fn for fn in names if __should_exclude(os.path.join(src, fn))]

# Function to check if a file should be excluded
def __should_exclude(file_path):
    return __matches_any_pattern(file_path, filter_rules)

def __matches_any_pattern(file_path, patterns):
    file_path = os.path.relpath(file_path, root_dir)
    file_path = file_path.replace(os.sep, '/')
    # print(file_path)
    for pattern in patterns:
        # print("\t", pattern, fnmatch.fnmatch(file_path, pattern))
        if fnmatch.fnmatch(file_path, pattern):
            return True
    return False

whitelisted_non_ch12 = [
    "resources/gfx/backdrop/revel3",
    "resources/gfx/backdrop/revel3/hubroom",
    "resources/gfx/backdrop/revel3/hubroom/*",
]

def __check_path(file_path: str):
    file_path = file_path.lower()
    if (
        ("chapter" in file_path and not ("chapter1" in file_path or "chapter2" in file_path))
        or (re.search(r'revel\d', file_path) and not ("revel1" in file_path or "revel2" in file_path))
    ) and not __matches_any_pattern(file_path, whitelisted_non_ch12):
        print(f"[WARN] Non-whitelisted non-chapter-1/2 file included at {file_path}! Double check!", file=sys.stderr)

# Example usage
if __name__ == '__main__':
    sync_folders(verbose=False)
    print("Done creating workshop release folder")