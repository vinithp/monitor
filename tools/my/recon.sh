#!/bin/bash


IP(){
ip=$(host $domain | grep 'has address' | cut -d " " -f 4)
ips=$(echo $ip | wc -w)
}

ASN(){
a=1
while [ $a -le $ips ]
do 
asn=${asn}$(whois -h whois.cymru.com " -v $( echo $ip | cut -d " " -f $a )" | grep -m2 . | tail -n1 | cut -d " " -f 1),
((a++))
done
asn=$( ( echo $asn | xargs -d , -n1 | sort -u | xargs ) | sed 's/\ /\,/g' )
}

#-------------passive-----------------#
P_SUBDOMAIN(){
#-------------AMASS-------------------#
amass enum -config ~/.config/amass/jk/config.ini -passive -asn $asn -d $domain -nocolor | tee -a $path/passive/allsubdomain
echo "P_amass completed" | tee -a $path/passive/status

#------------subfinder----------------#
subfinder -d $domain -silent | tee -a $path/passive/allsubdomain
echo "P_subfinder completed" | tee -a $path/passive/status

#------------assetfinder--------------# 
assetfinder -subs-only $domain | tee -a $path/passive/allsubdomain
echo "P_assetfinder completed" | tee -a $path/passive/status

#------------github-subdomains--------#
~/tools/github-search/github-subdomains.py -d $domain | tee -a $path/passive/allsubdomain
echo "P_github-subdomains completed" | tee -a $path/passive/status

#------------shosubgo-----------------#
#go run ~/tools/shodubgo/main.go -d $domain -s aEkJGyRcckezV07ExZqpkDWb5uf7OOKw | tee -a $path/passive/allsubdomain
#echo "P_shodubgo completed" | tee -a $path/passive/status

#------------bufferover---------------#
curl http://tls.bufferover.run/dns?q=$domain | jq '.Results' | awk -F',' '(NF>1) {print $3}' | sed 's/"//g;s/*\.//g' | sort -u | tee -a $path/passive/allsubdomain
echo "P_bufferover completed" | tee -a $path/passive/status

#--------------sorting----------------#
sed -i 's/^*\.//; s/\/$//' $path/passive/allsubdomain
~/tools/my/./rmwww.sh $path/passive/allsubdomain
sort -u $path/passive/allsubdomain -o $path/passive/allsubdomain
sed -i -n "/\/$domain\|\.$domain\|^ *$domain/p" $path/passive/allsubdomain
echo "P_sorting completed" | tee -a $path/passive/status

#-------calling amass once again------#
cat $path/passive/allsubdomain | xargs -I {} amass enum -config ~/.config/amass/jk/config.ini -passive -asn $asn -d {} -nocolor | tee -a $path/passive/amassagainsubdomain
echo "P_amassagain completed" | tee -a $path/passive/status

sort -u $path/passive/amassagainsubdomain -o $path/passive/amassagainsubdomain
sed -i -n "/\/$domain\|\.$domain\|^ *$domain/p" $path/passive/amassagainsubdomain

~/tools/my/./cm.sh $path/passive/allsubdomain $path/passive/amassagainsubdomain | tee -a $path/passive/allsubdomain
cp $path/passive/allsubdomain $path/allsubdomain
~/tools/my/./rmwww.sh $path/allsubdomain
sed -i '/^[[:space:]]*$/d' $path/passive/allsubdomain
sed -i '/^[[:space:]]*$/d' $path/allsubdomain
echo "P_processing_amassagain completed" | tee -a $path/passive/status

#------------massdns--httprobe-----------------#
<<<<<<< HEAD
cat $path/passive/allsubdomain | httprobe | sed 's/http.*:\/\///' | sort -u | tee -a $path/upsubdomains
sed -i '/^[[:space:]]*$/d' $path/upsubdomains
=======
cat $path/passive/allsubdomain | httprobe | sort -u | tee -a $path/passive/upsubdomains
~/tools/my/./rmhttp.sh $path/passive/upsubdomains
sed -i '/^[[:space:]]*$/d' $path/passive/upsubdomains
cat $path/passive/upsubdomains | tee -a $path/upsubdomains
>>>>>>> kl
echo "P_httprobe completed" | tee -a $path/passive/status
}

#--------------------active--------------------#
A_SUBDOMAIN(){
#-----------------sub-bruteforce---------------#
altdns -i $path/target -w ~/tools/my/words/my/subdomain/my1000.txt -o $path/active/altbrutelist
massdns -r ~/tools/massdns/lists/resolvers.txt -q -t A -o S $path/active/altbrutelist | tee -a $path/active/cname | awk -F' ' '{print $1}' | tee -a $path/active/brutdomain 
~/tools/my/./cm.sh $path/allsubdomain $path/active/brutdomain | tee -a $path/allsubdomain | tee -a $path/active/allsubdomain
<<<<<<< HEAD
=======
echo "A_sub-bruteforce completed" | tee -a $path/passive/status
>>>>>>> kl

#------------altdns-------------------#
altdns -i $path/allsubdomain -w $path/wordlist/tarwordlist -o $path/active/altdomain
massdns -r ~/tools/massdns/lists/resolvers.txt -q -t A -o S $path/active/altdomain | tee -a $path/active/cname | awk -F' ' '{print $1}' | tee -a $path/active/brutdomain 
~/tools/my/./cm.sh $path/allsubdomain $path/active/brutdomain | tee -a $path/allsubdomain | tee -a $path/active/allsubdomain
<<<<<<< HEAD
=======
echo "A_altdns completed" | tee -a $path/passive/status
>>>>>>> kl

sed -i 's/^*\.//; s/\/$//' $path/active/allsubdomain
~/tools/my/./rmwww.sh $path/active/allsubdomain

<<<<<<< HEAD
#-------calling amass once again------#
~/tools/my/./cm.sh $path/passive/allsubdomain $path/active/allsubdomain | xargs -I {} amass enum -config ~/.config/amass/jk/config.ini -passive -asn $asn -d {} -nocolor | tee -a $path/active/amassagainsubdomain
~/tools/my/./cm.sh $path/passive/allsubdomain $path/active/allsubdomain | xargs -I {} amass enum -brute -config ~/.config/amass/jk/config.ini -asn $asn -d {} -nocolor | tee -a $path/active/amassagainsubdomain
=======
#-------amass------#
cat $path/active/allsubdomain | xargs -I {} amass enum -config ~/.config/amass/jk/config.ini -passive -asn $asn -d {} -nocolor | tee -a $path/active/amassagainsubdomain
cat $path/active/allsubdomain | xargs -I {} amass enum -brute -config ~/.config/amass/jk/config.ini -asn $asn -d {} -nocolor | tee -a $path/active/amassagainsubdomain
echo "A_amass completed" | tee -a $path/passive/status
>>>>>>> kl

sort -u $path/active/amassagainsubdomain -o $path/active/amassagainsubdomain
~/tools/my/./cm.sh $path/allsubdomain $path/active/amassagainsubdomain | tee -a $path/allsubdomain | tee -a $path/active/allsubdomain
sed -i -n "/\/$domain\|\.$domain\|^ *$domain/p" $path/active/allsubdomain
sed -i '/^[[:space:]]*$/d' $path/active/allsubdomain
sed -i '/^[[:space:]]*$/d' $path/allsubdomain
~/tools/my/./rmwww.sh $path/active/allsubdomain

#------------httprobe----------------#
<<<<<<< HEAD
cat $path/active/allsubdomain | httprobe | sed 's/http.*:\/\//' | sort -u | tee -a $path/upsubdomains
sed -i '/^[[:space:]]*$/d' $path/upsubdomains
=======
cat $path/active/allsubdomain | httprobe | sort -u | tee -a $path/active/upsubdomains
~/tools/my/./rmhttp.sh $path/active/upsubdomains
sed -i '/^[[:space:]]*$/d' $path/active/upsubdomains
cat $path/active/upsubdomains | tee -a $path/upsubdomains
echo "A_httprobe completed" | tee -a $path/active/status

#----------spider-------------------#
gospider -S $path/active/upsubdomains -c 10 -d 3 | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | grep -a $domain | tee -a $path/active/spideroutput
sort -u $path/active/spideroutput -o $path/active/spideroutput
echo "active spider completed" | tee -a $path/active/status

#-----------sitemap------------------#
while read i; do echo $i | ~/tools/my/./link.sh domain-path | grep -a $domain ; done < <(cat $path/active/upsubdomains | sed 's/$/\/sitemap.xml/' | ~/tools/my/./jstool.js -curl) | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | sort -u | tee -a $path/active/sitemapurl
echo "active sitemap completed" | tee -a $path/active/status

#------------robot------------------#
while read i; do echo $i | ~/tools/my/./link.sh domain-path | grep -a $domain ; done < <(cat $path/active/upsubdomains | sed 's/$/\/robots.txt/' | ~/tools/my/./jstool.js -curl) | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | sort -u | tee -a $path/active/roboturl
echo "active roboturl completed" | tee -a $path/active/status

#----------wordlist-----------------#
cat $path/active/allsubdomain $path/active/sitemapurl $path/active/roboturl $path/active/spideroutput | sed 's/'$domain.*'//; s/https*:\/\/\**//g; s/\./\n/g; s/[^[:alnum:]\_\-]/\n/g'  | sort -u | tee -a $path/active/subwordlist | tee -a $path/wordlist/tarwordlist
cat $path/active/allsubdomain $path/active/sitemapurl $path/active/roboturl $path/active/spideroutput | sed 's/https*:\/\/.*'$domain'//g; s/\//\n/g; s/\?.*//g; s/\+//g; s/[^[:alnum:]\_\-]/\n/g' | grep -av '\.' | sort -u | tee -a $path/active/dirwordlist | tee -a $path/wordlist/tarwordlist
cat $path/active/allsubdomain $path/active/sitemapurl $path/active/roboturl $path/active/spideroutput | sed 's/https*:\/\/.*'$domain'//g; s/\?.*//; s/[^[:alnum:]\.\_\-]/\n/g' | awk -F'/' '{print $NF}' | grep -a '.\+\.' | sort -u | tee -a $path/active/filewordlist_temp 
cat $path/active/allsubdomain $path/active/sitemapurl $path/active/roboturl $path/active/spideroutput | grep -oa '\?.*' | grep -Eao "\?[a-zA-Z0-9]*[^\=]+|\&[a-zA-Z0-9]*[^\=]+" | sed 's/\+//g; s/[^[:alnum:]\?\&\_\-]/\n/g' | sort -u | tee -a $path/active/parameterwordlist | tee -a $path/wordlist/tarwordlist
~/tools/my/./cm.sh $path/allsubdomain $path/active/filewordlist_temp | tee -a $path/passive/filewordlist 
rm $path/active/filewordlist_temp
echo "active wordlists completed" | tee -a $path/active/status

cat $path/active/upsubdomains | ~/tools/my/./jstool.js -curl | tok | sort -u | tee -a $path/wordlist/A_tarallwords
echo "passive tarallwords completed" | tee -a $path/active/status

~/tools/my/./cm.sh ~/tools/my/files/filterwords $path/wordlist/A_tarallwords | tee -a $path/wordlist/A_tarwordlist | tee -a $path/wordlist/A_subwordlist

>>>>>>> kl
}

URLS(){
#------------gau--------------------#
<<<<<<< HEAD
cat $path/$1/allsubdomain | gau -subs | ~/tools/my/./jstool.js -urldc | tee -a $path/$1/gaurl 
echo "gau completed" | tee -a $path/$1/status

#----------waybackurls--------------#
cat $path/$1/allsubdomain | waybackurls | ~/tools/my/./jstool.js -urldc | tee -a $path/$1/gaurl
echo "waybackurls completed" | tee -a $path/$1/status
sed -i 's/:80//;s/:443//' $path/$1/gaurl
echo "sed remove :80 :443 completed" | tee -a $path/$1/status
sort -u $path/$1/gaurl -o $path/$1/gaurl
echo "sort gaurl completed" | tee -a $path/$1/status
~/tools/my/./link.sh domain $path/$1/gaurl | sort -u | grep $domain | tee -a $path/$1/gaurldomain
~/tools/my/./cm.sh $path/$1/allsubdomain $path/$1/gaurldomain | sed 's/https*:\/\///' | tee -a $path/$1/allsubdomain

#----------spider-------------------#
cat $path/$1/allsubdomain | sed 's/^/https:\/\//' | tee $path/$1/spiderinput
gospider -S $path/$2/spiderinput -c 10 -d 5 | tee $path/$1/spideroutput
sort -u $path/$1/spideroutput -o $path/$1/spideroutput
#when u enable this add this($path/$1/spideroutput)  to wordlist 
echo "spider completed" | tee -a $path/$1/status

#-----------commoncrawl-------------#
while read -r lines; do
curl -sL http://index.commoncrawl.org | grep 'href="/CC'  |  awk -F'"' '{print $2}' | xargs -n1 -I{} curl -sL http://index.commoncrawl.org{}-index?url=$lines/* |  awk -F'"url": "' '{print $2}' | cut -d'"' -f1 | sort -u | tee -a $path/$1/commoncrawl1
#~/tools/commoncrawl/./cc.py -d $lines | tee -a $path/$1/commoncrawl2
done < $path/$1/allsubdomain
echo "commoncrawl completed" | tee -a $path/$1/status

#-----------sitemap------------------#
while read i; do echo $i | ~/tools/my/./link.sh domain-path | grep $domain ; done < <(cat $path/$1/allsubdomain | sed 's/^/http:\/\//; s/$/\/sitemap.xml/' | ~/tools/my/./jstool.js -curl) | sort -u | tee -a $path/$1/sitemapurl
echo "sitemap completed" | tee -a $path/$1/status

#------------robot------------------#
while read i; do echo $i | ~/tools/my/./link.sh domain-path | grep $domain ; done < <(cat $path/$1/allsubdomain | sed 's/^/http:\/\//; s/$/\/robots.txt/' | ~/tools/my/./jstool.js -curl) | sort -u | tee -a $path/$1/roboturl
echo "roboturl completed" | tee -a $path/$1/status
}

WORDLIST(){
cat $path/$1/allsubdomain $path/$1/gaurl $path/$1/sitemapurl $path/$1/roboturl $path/$1/commoncrawl1 $path/$1/spideroutput | sed 's/'$domain.*'//g' | sed 's/https*:\/\/\**//g' | sed 's/\./\n/g'  | sort -u | tee -a $path/$1/subwordlist | tee -a $path/wordlist/tarwordlist
cat $path/$1/allsubdomain $path/$1/gaurl $path/$1/sitemapurl $path/$1/roboturl $path/$1/commoncrawl1 $path/$1/spideroutput | sed 's/https*:\/\/.*'$domain'//g; s/\//\n/g; s/\?.*//g' | grep -v '\.' | sort -u | tee -a $path/$1/dirwordlist | tee -a $path/wordlist/tarwordlist
cat $path/$1/allsubdomain $path/$1/gaurl $path/$1/sitemapurl $path/$1/roboturl $path/$1/commoncrawl1 $path/$1/spideroutput | sed 's/https*:\/\/.*'$domain'//g; s/\?.*//' | awk -F'/' '{print $NF}' | grep '.\+\.' | sort -u | tee -a $path/$1/filewordlist 
cat $path/$1/allsubdomain $path/$1/gaurl $path/$1/sitemapurl $path/$1/roboturl $path/$1/commoncrawl1 $path/$1/spideroutput | grep -o '\?.*' | grep -Eo "\?[a-zA-Z0-9]*[^\=]+|\&[a-zA-Z0-9]*[^\=]+" | sort -u | tee -a $path/$1/parameterwordlist | tee -a $path/wordlist/tarwordlist
echo "wordlists completed" | tee -a $path/$1/status


cat $path/upsubdomains | sed 's/^/http:\/\//' | ~/tools/my/./jstool.js -curl | tok | sort -u | tee -a $path/wordlist/tarallwords
echo "tarallwords completed" | tee -a $path/$1/status
=======
cat $path/target | gau -subs | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | grep -a $domain | tee -a $path/passive/gaurl 
echo "passive gau completed" | tee -a $path/passive/status

#----------waybackurls--------------#
cat $path/target | waybackurls | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | grep -a $domain | tee -a $path/passive/gaurl
echo "passive waybackurls completed" | tee -a $path/passive/status
sed -i 's/:80//;s/:443//' $path/passive/gaurl
echo "passive sed remove :80 :443 completed" | tee -a $path/passive/status
sort -u $path/passive/gaurl -o $path/passive/gaurl
echo "passive sort gaurl completed" | tee -a $path/passive/status
~/tools/my/./link.sh domain $path/passive/gaurl | sort -u | grep -a $domain | tee -a $path/passive/gaurldomain
#~/tools/my/./cm.sh $path/passive/allsubdomain $path/passive/gaurldomain | sed 's/https*:\/\///' | tee -a $path/passive/allsubdomain

#----------spider-------------------#
#cat $path/passive/allsubdomain | sed 's/^/https:\/\//' | tee -a $path/passive/spiderinput
gospider -S $path/passive/upsubdomains -c 10 -d 3 | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | grep -a $domain | tee -a $path/passive/spideroutput
sort -u $path/passive/spideroutput -o $path/passive/spideroutput
echo "passive spider completed" | tee -a $path/passive/status

#-----------commoncrawl-------------#
curl -sL http://index.commoncrawl.org | grep -a 'href="/CC' | awk -F'"' '{print $2}' | xargs -n1 -I{} curl -sL http://index.commoncrawl.org{}-index?url=*.$domain/* |  awk -F'"url": "' '{print $2}' | cut -d'"' -f1 | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | grep -a $domain | sort -u | tee -a $path/passive/commoncrawl1
sort -u $path/passive/commoncrawl1 -o $path/passive/commoncrawl1
echo "passive commoncrawl completed" | tee -a $path/passive/status

#-----------sitemap------------------#
while read i; do echo $i | ~/tools/my/./link.sh domain-path | grep -a $domain ; done < <(cat $path/passive/upsubdomains | sed 's/$/\/sitemap.xml/' | ~/tools/my/./jstool.js -curl) | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | sort -u | tee -a $path/passive/sitemapurl
echo "passive sitemap completed" | tee -a $path/passive/status

#------------robot------------------#
while read i; do echo $i | ~/tools/my/./link.sh domain-path | grep -a $domain ; done < <(cat $path/passive/upsubdomains | sed 's/$/\/robots.txt/' | ~/tools/my/./jstool.js -curl) | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | sort -u | tee -a $path/passive/roboturl
echo "passive roboturl completed" | tee -a $path/passive/status
}

WORDLIST(){
cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput | sed 's/'$domain.*'//; s/https*:\/\/\**//g; s/\./\n/g; s/[^[:alnum:]\_\-]/\n/g'  | sort -u | tee -a $path/passive/subwordlist | tee -a $path/wordlist/tarwordlist
cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput | sed 's/https*:\/\/.*'$domain'//g; s/\//\n/g; s/\?.*//g; s/\+//g; s/[^[:alnum:]\_\-]/\n/g' | grep -av '\.' | sort -u | tee -a $path/passive/dirwordlist | tee -a $path/wordlist/tarwordlist
cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput | sed 's/https*:\/\/.*'$domain'//g; s/\?.*//; s/[^[:alnum:]\.\_\-]/\n/g' | awk -F'/' '{print $NF}' | grep -a '.\+\.' | sort -u | tee -a $path/passive/filewordlist_temp 
cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput | grep -oa '\?.*' | grep -Eao "\?[a-zA-Z0-9]*[^\=]+|\&[a-zA-Z0-9]*[^\=]+" | sed 's/\+//g; s/[^[:alnum:]\?\&\_\-]/\n/g' | sort -u | tee -a $path/passive/parameterwordlist | tee -a $path/wordlist/tarwordlist

~/tools/my/./cm.sh $path/allsubdomain $path/passive/filewordlist_temp | tee -a $path/passive/filewordlist 
rm $path/passive/filewordlist_temp
echo "passive wordlists completed" | tee -a $path/passive/status


cat $path/upsubdomains | ~/tools/my/./jstool.js -curl | tok | sort -u | tee -a $path/wordlist/tarallwords
echo "passive tarallwords completed" | tee -a $path/passive/status
>>>>>>> kl
~/tools/my/./cm.sh ~/tools/my/files/filterwords $path/wordlist/tarallwords | tee -a $path/wordlist/tarwordlist | tee -a $path/wordlist/subwordlist
cat ~/tools/my/words/my/subdomain/my1000.txt >> $path/wordlist/tarwordlist
sort -u $path/wordlist/tarwordlist -o $path/wordlist/tarwordlist 
}

#------------scanning ip---------------#
IPSCAN(){
cat $path/allsubdomain | sed 's/https*:\/\///' | xargs -I {} ~/tools/my/./recon.sh ip {} | tee $path/subips

while read -r lines; do
line=$(echo $lines | awk '{print $2}')
<<<<<<< HEAD
printf '%-30s %-15s %-15s %-15s\n' $(echo $lines && whois -h whois.arin.net $line | grep -m2 'CIDR\|Organization' | awk '{$1="";print $2}') | tee -a $path/ipcidr
=======
printf '%-30s %-15s %-15s %-15s\n' $(echo $lines && whois -h whois.arin.net $line | grep -m2 'CIDR\|Organization' | awk '{passive="";print $2}') | tee -a $path/ipcidr
>>>>>>> kl
done < $path/subips
rm $path/subips
}
#------------reverse whois-------------#
#https://tools.whoisxmlapi.com/reverse-whois-search




#------------S3BUCKET------------------#
S3BUCKET(){
cat $path/subwords | tee -a common_bucket_prefixes.txt
sort -u common_bucket_prefixes.txt -o common_bucket_prefixes.txt
		lazys3 $(echo $domain | cut -d '.' -f1)
}

if [[ $1 == '' ]]
then
	echo -e "provid action\n(asn,ip,passive,active,all,single)"
elif [[ $2 ==  '' ]]
then
	echo "mention domain"
else
	if [ $1 == asn ]
	then
		ip=$2
		ips=1
		ASN
		echo $asn
	elif [ $1 == ip ]
	then
		domain=$2
		IP
		echo $ip | sed 's/ /\n/g' | sed 's/^/'$domain" "'/' | xargs printf "%-35s %-15s\n" | awk 'NF>1'
	elif [ $1 == passive ]
	then
		domain=$2
		mkdir ~/bug/$domain
		path=~/bug/$domain
		mkdir $path/passive
		mkdir $path/wordlist
<<<<<<< HEAD
		IP
		ASN
		P_SUBDOMAIN
		URLS passive
		WORDLIST passive
=======
		echo $domain | tee -a $path/passive/allsubdomain | tee $path/target
		IP
		ASN
		P_SUBDOMAIN
		URLS
		WORDLIST
>>>>>>> kl
	elif [ $1 == active ]
	then 
		domain=$2
		mkdir ~/bug/$domain
		path=~/bug/$domain
		mkdir $path/active
<<<<<<< HEAD
		echo $domain >> $path/target
		IP
		ASN
		A_SUBDOMAIN
		URL active
		WORDLIST active
=======
		mkdir $path/wordlist
		echo $domain | tee -a $path/active/allsubdomain | tee $path/target
		IP
		ASN
		A_SUBDOMAIN
>>>>>>> kl
	elif [ $1 == all ]
	then
		domain=$2
		mkdir ~/bug/$domain
		path=~/bug/$domain
		mkdir $path/active
		mkdir $path/passive
<<<<<<< HEAD
		echo $domain >> $path/target
		IP
		ASN	
		P_SUBDOMAIN
		URLS passive
		WORDLIST passive
		A_SUBDOMAIN
		URL active
		WORDLIST active
=======
		mkdir $path/wordlist
		echo $domain | tee -a $path/passive/allsubdomain | tee -a $path/active/allsubdomain | tee $path/target
		IP
		ASN	
		P_SUBDOMAIN
		URLS
		WORDLIST
		A_SUBDOMAIN
>>>>>>> kl
	elif [ $1 == single ]
	then
		domain=$2
		mkdir ~/bug/$domain
		path=~/bug/$domain
<<<<<<< HEAD
		mkdir $path/$domain$3
		echo $domain | tee $path/$domain$3/allsubdomain
		echo $domain | tee $path/upsubdomains
		URLS $domain$3
		WORDLIST $domain$3		
=======
		mv $path/passive $path/passive$3
		mv $path/wordlist $path/wordlist$3
		mkdir $path/passive
		mkdir $path/wordlist
		echo $domain | tee $path/passive/allsubdomain | tee $path/target
		echo $domain | tee $path/upsubdomains
		URLS
		WORDLIST		
>>>>>>> kl
	fi
fi