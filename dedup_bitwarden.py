# from: https://www.reddit.com/r/Bitwarden/comments/aon967/bitwarden_duplicate_entries_remover/
# and: https://pastebin.com/7HVQF9TF
#!/usr/bin/python3

# dedup.py
# Removes duplicates from Bitwarden export .csv
# 2019-02-09 5erif

import sys
import hashlib
from urllib.parse import urlparse

# Field ordinals in Bitwarden CSV
FOLDER   = 0
FAVORITE = 1
TYPE     = 2
NAME     = 3
NOTES    = 4
FIELDS   = 5
URI      = 6
USERNAME = 7
PASSWORD = 8
TOTP     = 9

def main(argv):

    if len(argv) < 1:
        print('Missing input file path')
        sys.exit(1)
        
    in_file_path  = argv[0]
    out_file_path = in_file_path[0:(len(in_file_path)-4)]+'_out.csv'
    rem_file_path = in_file_path[0:(len(in_file_path)-4)]+'_rem.csv'
    completed_lines_hash = set()
    line_number   = -1
    write_count   = 0
    cache         = ''
    
    out_file = open(out_file_path, 'w', encoding = 'utf8')
    rem_file = open(rem_file_path, 'w', encoding = 'utf8')
    for line in open(in_file_path, 'r', encoding = 'utf8'):
        line_number += 1
        fields = line.split(',')
        if len(fields) < 10:
            # Add previous line if short
            line = cache.strip('\n') + line
            cache = line
            fields = line.split(',')
            if len(fields) > 9:
                print(f'Recovered with line {line_number}:\n{line}')
                cache = ''
            else:
                print(f'Missing fields in line {line_number}:\n{line}')
                rem_file.write(line)
                continue
        else:
            cache = ''
        if line_number != 0:
            domain = urlparse(fields[URI]).netloc
            if len(domain) > 0:
                fields[URI] = domain
        token = fields[URI] + fields[USERNAME] + fields[PASSWORD]
        hashValue = hashlib.md5(token.rstrip().encode('utf-8')).hexdigest()
        if hashValue not in completed_lines_hash:
            out_file.write(line)
            completed_lines_hash.add(hashValue)
            write_count += 1
        else: 
            rem_file.write(line)
            # Uncomment for verbose mode
            # print(f'Skipping duplicate on line {line_number}:\n{line}')
    out_file.close()
    rem_file.close()
    
    dup_count = line_number - write_count
    print(f'\nOutput file: {out_file_path}\n{write_count} unique entries saved')
    print(f'\n{dup_count} duplicates saved to {rem_file_path}')

if __name__ == "__main__":
   main(sys.argv[1:])
