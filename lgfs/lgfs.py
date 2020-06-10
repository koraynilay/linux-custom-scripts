#!/bin/python
import os
import json
config = os.getenv("HOME")+'/.config/lgfs.json'
with open(config, 'r') as file:
    grs = json.load(file)["grs"]
cwd = os.getcwd();
#print(grs[0]["name"])
for i in grs:
    if i["location"] == cwd:
        print(i["entries"])
        os.system("ls -lahd "+i["entries"])
