import sys, os
import fileinput

replacefile = ""

if len(sys.argv) > 1:
    replacefile = sys.argv[1]

def doReplacements(replaceOpenedFile):
    for replaceString in replaceOpenedFile:
        if not replaceString.strip():
            continue

        toSearch, toReplace = replaceString.rstrip('\n').split("--->", 1)

        print('Replacing "' + toSearch + '" with "' + toReplace + '":')

        files = [os.path.join(dp, f) for dp, dn, filenames in os.walk(".") for f in filenames if os.path.splitext(f) != ".stb"]

        for filename in files:
            if os.path.abspath(filename) == os.path.abspath(sys.argv[0]) or os.path.abspath(filename) == os.path.abspath(replacefile):
                continue

            count = 0
            with fileinput.input(filename, inplace=True) as file:
                for line in file:
                    print(line.replace(toSearch, toReplace), end='')
                    count = count + 1
            print('\t' + str(count) + " replacements done in " + filename)
                
if replacefile != "":
    with open(replacefile) as f:
        doReplacements(f)
else:
    doReplacements(sys.stdin)