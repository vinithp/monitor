dig +nocmd +nostats -f $1 | grep CNAME | awk -F' ' '{print $1" "$5}' | tee sdtoc$2 | awk -F' ' '{print "https://"$1}' | hakcheckurl | grep -v 999 | sed -u -e 's/https:\/\///' | xargs -n 2 sh -c 'sed -e "s/$2/$2 $1/" sdtoc'$2' | grep $2 | xargs printf "%-50s %-5s %-s\n"' argv0 | tee sdtos$2

