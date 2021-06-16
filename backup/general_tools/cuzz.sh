#!/bin/bash

cat ~/tools/my/curltoffuf.txt | tr -d '\\$\n' | tr -s " " | sed -E 's/curl -i -s -k/ffuf/;s/-H \x27Host: /-w -u https:\/\//;s/\x27 +\x27.+/\x27/g;s/\(.*\)//;s/$/ -mc all -fc/' | xclip -selection clipboard

