#!/bin/bash

#while read i
#do 
#cat $1 | grep -Ea ^$i 
#there=$?
#if [ $there == 0 ]
#then
#sed -i 's/www\.'$i'//' $1
#fi

#done < <(cat $1 | grep -Ea ^www |sed 's/^www\.//')

cat $1 | grep -Ea ^www | sed 's/^www\.//' | xargs -I{} grep -a {} $1 | sed 's/^/www\./' | xargs -I{} sed -i '/{}/d' $1 
