# Script to convert Timing CSVs into lua-readable music cue tables
# (aka time maps, at the time I didn't know the term)
# Example of how to create the CSVs is by placing markers at that timing in Premiere Pro
# and exporting markers to CSV. Yes, it is bad, but it's what I have on hand.

# requires https://github.com/SirAnthony/slpp, use 'pip install git+https://github.com/SirAnthony/slpp.git', might need some edits due to python versions
# requires tinytag, use 'pip install tinytag'

import sys, os
import csv
import codecs
from slpp import slpp
from tinytag import TinyTag
import argparse

# config

# Column containing the set name
in_name_column = 0

#Column containing the cue time
in_time_column = 2

# Project framerate for sub-second time conversion (applies in Premiere, at least)
frames_framerate = 30

# Sample rate for time conversion if frames are not used, could probably be obtained from file
audio_sample_rate = 44100

#set markers with defname as the name are put in
default_set_name = "Default"

# end config

parser = argparse.ArgumentParser(description='Convert .ogg and .csv files to .lua cue files.')

parser.add_argument('-c', '--csv', dest='input_file', type=str,
                    help='input csv file path')
parser.add_argument('-o', '--output', dest='output_file', type=str,
                    help='output file path')
parser.add_argument('-t', '--track', dest='track_file', type=str,
                    help='track file path')
parser.add_argument('-s', '--setname', dest='set_name', type=str,
                    help='cue set name')
parser.add_argument('-fps', '--framerate', dest='fps', type=int,
                    help='video project original framerate used in markers', default=30)
parser.add_argument('--setsep', dest='set_sep', type=str, default=",",
                    help='cue set name separator')
parser.add_argument('--useframes', dest='use_frames', default=False, action='store_true',
                    help='if sequence uses frames for sub-second time instead of audio time')

args = parser.parse_args()

out_path = ""

if args.output_file != None:
    out_path = args.output_file
elif args.input_file != None:
    out_path = args.input_file.replace(".csv", ".lua")
else:
    out_path = args.track_file.replace(".ogg", ".lua")

out_dict = {"Cues": {}}

if os.path.isfile(out_path):
    with open(out_path, "r") as f:
        out_dict = slpp.decode(f.read().replace("tmp_cues = ", "").replace("\nrevel.bork.NonExistantFunctionThatIsCalledToIntentionallyErrorThis() --read the comment after the first pcall in main.lua", ""))
        if out_dict == None:
            out_dict = {"Cues": {}}

if not "Cues" in out_dict:
    out_dict["Cues"] = {}

if args.track_file != None:
    track_tags = TinyTag.get(args.track_file)
    out_dict['Duration'] = int(track_tags.duration * 1000)

if args.input_file != None:
    markerSets = {}

    with codecs.open(args.input_file, 'rU', 'utf-16') as csv_file:
        line_id = 0
        reader = csv.reader(csv_file, delimiter = '\t')

        for row in reader:
            if line_id > 0:
                (hour, min, sec, subsecond) = (int(x) for x in row[in_time_column].split(":"))

                subsecond_rate = None
                if args.use_frames:
                    subsecond_rate = args.fps
                else:
                    subsecond_rate = audio_sample_rate

                ms = sec * 1000 + min * 60 * 1000 + hour * 3600 * 1000 + int(subsecond / subsecond_rate * 1000)

                name = row[in_name_column]
                if args.set_name != None:
                    name = args.set_name
                if name == "" or name is None:
                    name = default_set_name
                for setname in name.split(args.set_sep):
                    if not setname in markerSets:
                        markerSets[setname] = []
                    markerSets[setname].append(ms)

            line_id += 1

        out_dict["Cues"] = markerSets

if not 'Duration' in out_dict:
    print("Track duration not specified yet! To do so, please run the command with the --track argument")

outfile = open(out_path, "w")
lua_text = slpp.encode(out_dict).replace('\t', '  ')
outfile.write("return " + lua_text)
# outfile.write("\nif REVEL.PCALL_WORKAROUND then revel.bork.NonExistantFunctionThatIsCalledToIntentionallyErrorThis() end --read the comment after the first pcall in main.lua")
outfile.close()