import json
import glob
import argparse

parser = argparse.ArgumentParser()

parser.add_argument("prefix",
        help="The common prefix for all of the hunter.io files you've \
        downloaded. All files matching <prefix>* will be parsed.")

args = parser.parse_args()

filePrefix = args.prefix
print("[*] Parsing all files starting with {}".format(filePrefix))

emails = set()

for name in glob.glob("./{}*".format(filePrefix)):
    print("\t{}".format(name))
    with open(name) as f:
        rawData = f.read()
        jsonData = json.loads(rawData)
        for email in jsonData['data']['emails']:
            emails.add(email['value'])
        #print("[*] Parsed {} emails so far.".format(len(emails)))

with open("hunterio-parsed-emails.txt", "w") as f:
    f.write("\n".join(emails))
