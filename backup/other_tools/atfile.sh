#!/bin/bash
while read li; do
cat $1 | sed -e 's/^/'$li'\./'
done < $2
