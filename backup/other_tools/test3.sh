#!/bin/bash
while read i;do
     (host $i | grep 'has address' | cut -d " " -f 4) | sed 's/ /\n/g' | sed 's/^/'$i" "'/' | xargs printf "%-35s %-15s\n" | awk 'NF>1'
     sleep 2
done<$1
