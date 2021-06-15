#!/bin/bash
set -o errexit
set -o nounset

print_usage() {
    printf "%s\n\n%s\n" 'This is passive/active recon tool' ' options: '
    printf "\t%s %s % -13s %s\n" -d = "domain name" '(example.com)'
    printf "\t%s %s % -13s %s\n\n" -r = "features" '(ip|asn|passive|active|all|single)'
    printf " %s\n" 'NOTE   : USE -d FLAG BEFORE -R  '
    printf " %s\n" 'example: ./recon.sh -d google.com -r all'
}
[ $# -gt 0 ] || print_usage
#=================================================================================

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
echo "P_amass completed" | tee -a $path/status

#------------subfinder----------------#
subfinder -d $domain -silent | tee -a $path/passive/allsubdomain
echo "P_subfinder completed" | tee -a $path/status

#------------assetfinder--------------# 
assetfinder -subs-only $domain | tee -a $path/passive/allsubdomain
echo "P_assetfinder completed" | tee -a $path/status

#------------github-subdomains--------#
~/tools/github-search/github-subdomains.py -d $domain | tee -a $path/passive/allsubdomain
echo "P_github-subdomains completed" | tee -a $path/status

#------------shosubgo-----------------#
#go run ~/tools/shodubgo/main.go -d $domain -s aEkJGyRcckezV07ExZqpkDWb5uf7OOKw | tee -a $path/passive/allsubdomain
#echo "P_shodubgo completed" | tee -a $path/passive/status

#------------bufferover---------------#
curl http://tls.bufferover.run/dns?q=$domain | jq '.Results' | awk -F',' '(NF>1) {print $3}' | sed 's/"//g;s/*\.//g' | sort -u | tee -a $path/passive/allsubdomain
echo "P_bufferover completed" | tee -a $path/status

#--------------sorting----------------#
sed -i 's/^\*\.//; s/\/$//' $path/passive/allsubdomain
~/tools/my/./rmwww.sh $path/passive/allsubdomain
sort -u $path/passive/allsubdomain -o $path/passive/allsubdomain
sed -i -n "/\/$domain\|\.$domain\|^ *$domain/p" $path/passive/allsubdomain
echo "P_sorting completed" | tee -a $path/status

#--------calling amass once again------#
cat $path/passive/allsubdomain | xargs -I {} amass enum -config ~/.config/amass/jk/config.ini -passive -asn $asn -d {} -nocolor | tee -a $path/passive/amassagainsubdomain
echo "P_amassagain completed" | tee -a $path/status

sort -u $path/passive/amassagainsubdomain -o $path/passive/amassagainsubdomain
sed -i -n "/\/$domain\|\.$domain\|^ *$domain/p" $path/passive/amassagainsubdomain

~/tools/my/./cm.sh $path/passive/allsubdomain $path/passive/amassagainsubdomain | tee -a $path/passive/allsubdomain
~/tools/my/./rmwww.sh $path/allsubdomain
sed -i '/^[[:space:]]*$/d; s/\.$//' $path/passive/allsubdomain
cp $path/passive/allsubdomain $path/allsubdomain
echo "P_processing_amassagain completed" | tee -a $path/status

#------------massdns--httprobe-----------------#
cat $path/passive/allsubdomain | httprobe | sort -u | tee -a $path/passive/upsubdomains
~/tools/my/./rmhttp.sh $path/passive/upsubdomains
sed -i '/^[[:space:]]*$/d' $path/passive/upsubdomains
cat $path/passive/upsubdomains | tee -a $path/upsubdomains
echo "P_httprobe completed" | tee -a $path/status
}

#--------------------active--------------------#
A_SUBDOMAIN(){
#------------altdns-sub-bruteforce-------------#
altdns -i $path/target -w ~/tools/my/my_word/subdomain/my1000.txt -o $path/active/altlist
cat $path/active/altlist | grep -xavf $path/active/altbrutelist | tee -a $path/active/altbrutelist
altdns -i $path/target -w $path/wordlist/tarwordlist -o $path/active/altlist
cat $path/active/altlist | grep -xavf $path/active/altbrutelist | tee -a $path/active/altbrutelist
altdns -i $path/allsubdomain -w $path/$1/subwordlist -o $path/active/altlist
cat $path/active/altlist | grep -xavf $path/active/altbrutelist | tee -a $path/active/altbrutelist
altdns -i $path/allsubdomain -w ~/tools/my/my_word/subdomain/my1000.txt -o $path/active/altlist
cat $path/active/altlist | grep -xavf $path/active/altbrutelist | tee -a $path/active/altbrutelist

echo "A_altdns completed" | tee -a $path/status

#-----------massdns--------------------------#
massdns -r ~/tools/massdns/lists/resolvers.txt -q -t A -o S $path/active/altbrutelist | tee -a $path/active/cname | awk -F' ' '{print $1}' | tee -a $path/active/brutdomain | sed 's/\.$//; s/^*\.//; s/\/$//' | grep -xavf $path/allsubdomain | tee -a $path/active/allsubdomain 
echo "A_massdns completed" | tee -a $path/status

~/tools/my/./rmwww.sh $path/active/allsubdomain

#-------amass------#
cat $path/active/allsubdomain | xargs -I {} amass enum -config ~/.config/amass/jk/config.ini -passive -asn $asn -d {} -nocolor | sed 's/\.$//' | tee -a $path/active/amassagainsubdomain
cat $path/active/allsubdomain | xargs -I {} amass enum -brute -config ~/.config/amass/jk/config.ini -asn $asn -d {} -nocolor | sed 's/\.$//' | tee -a $path/active/amassagainsubdomain
echo "A_amass completed" | tee -a $path/status

sort -u $path/active/amassagainsubdomain -o $path/active/amassagainsubdomain
~/tools/my/./cm.sh $path/allsubdomain $path/active/amassagainsubdomain | tee -a $path/active/allsubdomain
sed -i -n "/\/$domain\|\.$domain\|^ *$domain/p" $path/active/allsubdomain
sed -i '/^[[:space:]]*$/d' $path/active/allsubdomain
cat $path/active/allsubdomain | tee -a $path/allsubdomain
~/tools/my/./rmwww.sh $path/active/allsubdomain

#------------httprobe----------------#
cat $path/active/allsubdomain | httprobe | sort -u | tee -a $path/active/upsubdomains
~/tools/my/./rmhttp.sh $path/active/upsubdomains
cat $path/active/upsubdomains | tee -a $path/upsubdomains
echo "A_httprobe completed" | tee -a $path/status
}

P_URLS(){
#------------gau--------------------#
cat $path/target | gau -subs | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | grep -a $domain | tee -a $path/passive/gaurl 
echo "gau completed" | tee -a $path/status

#----------waybackurls--------------#
cat $path/target | waybackurls | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | grep -a $domain | tee -a $path/passive/gaurl
echo "waybackurls completed" | tee -a $path/status
sed -i 's/:80//;s/:443//' $path/passive/gaurl
echo "sed remove :80 :443 completed" | tee -a $path/status
sort -u $path/passive/gaurl -o $path/passive/gaurl
echo "sort gaurl completed" | tee -a $path/status
~/tools/my/./link.sh domain $path/passive/gaurl | sort -u | grep -a $domain | tee -a $path/passive/gaurldomain
#~/tools/my/./cm.sh $path/passive/allsubdomain $path/passive/gaurldomain | sed 's/https*:\/\///' | tee -a $path/passive/allsubdomain

#-----------commoncrawl-------------#
curl -sL http://index.commoncrawl.org | grep -a 'href="/CC' | awk -F'"' '{print $2}' | xargs -n1 -I{} curl -sL http://index.commoncrawl.org{}-index?url=*.$domain/* |  awk -F'"url": "' '{print $2}' | cut -d'"' -f1 | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | grep -a $domain | sort -u | tee -a $path/passive/commoncrawl1
sort -u $path/passive/commoncrawl1 -o $path/passive/commoncrawl1
echo "commoncrawl completed" | tee -a $path/status
}

SPIDER(){
#----------spider-------------------#
#cat $path/passive/allsubdomain | sed 's/^/https:\/\//' | tee -a $path/passive/spiderinput
gospider -S $path/$1/upsubdomains -c 10 -d 3 | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | sed 's/\[.*\] \- //' | tee -a $path/$1/spideralloutput | grep -a $domain | tee -a $path/$1/spideroutput
sort -u $path/$1/spideroutput -o $path/$1/spideroutput
echo "$1_spider completed" | tee -a $path/status
}

A_URLS(){
#-----------sitemap------------------#
while read i; do echo $i | ~/tools/my/./link.sh domain-path | grep -a $domain ; done < <(cat $path/$1/upsubdomains | sed 's/$/\/sitemap.xml/' | ~/tools/my/./jstool.js -curl) | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | sort -u | tee -a $path/$1/sitemapurl
echo "$1_sitemap completed" | tee -a $path/status

#------------robot------------------#
while read i; do echo $i | ~/tools/my/./link.sh domain-path | grep -a $domain ; done < <(cat $path/$1/upsubdomains | sed 's/$/\/robots.txt/' | ~/tools/my/./jstool.js -curl) | ~/tools/my/./pygrep.py urldc | ~/tools/my/./pygrep.py htmldc | sort -u | tee -a $path/$1/roboturl
echo "$1_roboturl completed" | tee -a $path/status
}


WORDLIST(){
$2 | sed 's/'$domain.*'//; s/https*:\/\/\**//g; s/\./\n/g; s/[^[:alnum:]\_\-]/\n/g'  | sort -u | tee -a $path/$1/subwordlist | tee -a $path/wordlist/tarwordlist
$2 | sed 's/https*:\/\/.*'$domain'//g; s/\//\n/g; s/\?.*//g; s/\+//g; s/[^[:alnum:]\_\.\-]/\n/g' | grep -Eav '\.|[^a-zA-Z0-9]+' | sort -u | tee -a $path/$1/dirwordlist | tee -a $path/wordlist/tarwordlist
$2 | sed 's/https*:\/\/.*'$domain'//g; s/\?.*//; s/[^[:alnum:]\.\_\-]/\n/g' | awk -F'/' '{print $NF}' | grep -a '.\+\.' | grep -Eva '\.[a-zA-Z0-9\_\-]{7,}$' | grep -Eva "\.com|\.net|\.org" | grep -Eva "\.$" | grep -Eva "\.[0-9]+$" | sort -u | tee -a $path/$1/filewordlist_temp 
$2 | grep -oa '\?.*' | grep -Eao "\?[a-zA-Z0-9]*[^\=]+|\&[a-zA-Z0-9]*[^\=]+" | sed 's/\+//g; s/[^[:alnum:]\?\&\_\-]/\n/g' | sort -u | tee -a $path/$1/parameterwordlist
~/tools/my/./cm.sh $path/allsubdomain $path/$1/filewordlist_temp | tee -a $path/$1/filewordlist 
rm $path/$1/filewordlist_temp
echo "$1_wordlists completed" | tee -a $path/status

cat $path/$1/upsubdomains | ~/tools/my/./jstool.js -curl | tok | sort -u | grep -xavf ~/tools/my/files/filterwords | grep -xavf $path/wordlist/tarwordlist | sed '/^[[:space:]]*$/d' | tee -a $path/wordlist/tarallwords
sort -u $path/wordlist/tarwordlist -o $path/wordlist/tarwordlist 
echo "$1_tarallwords completed" | tee -a $path/status

}

#------------scanning ip---------------#
IPSCAN(){
cat $path/allsubdomain | sed 's/https*:\/\///' | xargs -I {} ~/tools/my/./recon.sh ip {} | tee $path/subips

while read -r lines; do
line=$(echo $lines | awk '{print $2}')
printf '%-30s %-15s %-15s %-15s\n' $(echo $lines && whois -h whois.arin.net $line | grep -m2 'CIDR\|Organization' | awk '{passive="";print $2}') | tee -a $path/ipcidr
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
#========================================================================================

#if [[ $1 == '' ]]
#then
#	echo -e "provid action\n(asn,ip,passive,active,all,single)"
#elif [[ $2 ==  '' ]]
#then
#	echo "mention domain"
#else
#	if [ $1 == asn ]
#	then
#		ip=$2
#		ips=1
#		ASN
#		echo $asn
#	elif [ $1 == ip ]
#	then
#		domain=$2
#		IP
#		echo $ip | sed 's/ /\n/g' | sed 's/^/'$domain" "'/' | xargs printf "%-35s %-15s\n" | awk 'NF>1'
#	elif [ $1 == passive ]
#	then
#		domain=$2
#		mkdir ~/bug/$domain
#		path=~/bug/$domain
#		mkdir $path/passive
#		mkdir $path/wordlist
#		echo $domain | tee -a $path/passive/allsubdomain | tee $path/target
#		IP
#		ASN
#		P_SUBDOMAIN
#		P_URLS
#		A_URLS passive
#		WORDLIST passive "cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput"
#
#	elif [ $1 == active ]
#	then 
#		domain=$2
#		mkdir ~/bug/$domain
#		path=~/bug/$domain
#		mkdir $path/active
#		mkdir $path/wordlist
#		echo $domain | tee $path/target
#		IP
#		ASN
#		A_SUBDOMAIN
#		A_URLS active
#		WORDLIST active "cat $path/active/allsubdomain $path/active/sitemapurl $path/active/roboturl $path/active/spideroutput"
#	elif [ $1 == all ]
#	then
#		domain=$2
#		mkdir ~/bug/$domain
#		path=~/bug/$domain
#		mkdir $path/active
#		mkdir $path/passive
#		mkdir $path/wordlist
#		echo $domain | tee -a $path/passive/allsubdomain | tee $path/target
#		IP
#		ASN	
#		P_SUBDOMAIN
#		P_URLS
#		A_URLS passive
#		WORDLIST passive "cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput"
#		A_SUBDOMAIN
#		A_URLS active
#		WORDLIST active "cat $path/active/allsubdomain $path/active/sitemapurl $path/active/roboturl $path/active/spideroutput"
#	elif [ $1 == single ]
#	then
#		domain=$2
#		mkdir ~/bug/$domain
#		path=~/bug/$domain
#		mv $path/passive $path/passive$3
#		mv $path/wordlist $path/wordlist$3
#		mkdir $path/passive
#		mkdir $path/wordlist
#		echo $domain | tee $path/passive/allsubdomain | tee $path/target
#		echo "https://$domain" | tee $path/upsubdomains
#		P_URLS
#		A_URLS passive
#		WORDLIST passive "cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput"
#		
#	fi
#fi
#============================================================================================

while getopts 'hr:d:' flag; do
  case "${flag}" in
    h) print_usage;exit 1 ;;
    d) case "${OPTARG}" in
        [a-zA-Z0-9_-]*.[a-z]* | [0-9.]*)
            domain=${OPTARG};;
        *)
            print_usage;exit 1;;
        esac;;
    r) case "${OPTARG}" in
        asn)
            ip=$domain
            ips=1
            ASN
            echo $asn;;
        ip)
	    IP
	    echo $ip | sed 's/ /\n/g' | sed 's/^/'$domain" "'/' | xargs printf "%-35s %-15s\n" | awk 'NF>1';;
        passive)
    	    mkdir ~/bug/$domain
	    path=~/bug/$domain
    	    mkdir $path/passive
	    mkdir $path/wordlist
	    echo $domain | tee -a $path/passive/allsubdomain | tee $path/target
	    IP
	    ASN
	    P_SUBDOMAIN
	    P_URLS
    	    A_URLS passive
            SPIDER passive
    	    WORDLIST passive "cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput";;
        active)
            mkdir ~/bug/$domain
            path=~/bug/$domain
            mkdir $path/active
            mkdir $path/wordlist
            echo $domain | tee $path/target
            IP
            ASN
            A_SUBDOMAIN
            A_URLS active
            SPIDER active
            WORDLIST active "cat $path/active/allsubdomain $path/active/sitemapurl $path/active/roboturl $path/active/spideroutput";;
        all)
            mkdir ~/bug/$domain
            path=~/bug/$domain
            mkdir $path/active
            mkdir $path/passive
            mkdir $path/wordlist
            echo $domain | tee -a $path/passive/allsubdomain | tee $path/target
            IP
            ASN
            P_SUBDOMAIN
            P_URLS
            SPIDER passive
            A_URLS passive
            WORDLIST passive "cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput"
            A_SUBDOMAIN
            A_URLS active
            SPIDER active
            WORDLIST active "cat $path/active/allsubdomain $path/active/sitemapurl $path/active/roboturl $path/active/spideroutput";;
        single)
            mkdir ~/bug/$domain
            path=~/bug/$domain
            mv $path/passive $path/passive$3
            mv $path/wordlist $path/wordlist$3
            mkdir $path/passive
            mkdir $path/wordlist
            echo $domain | tee $path/passive/allsubdomain | tee $path/target
            echo "https://$domain" | tee $path/upsubdomains
            P_URLS
            A_URLS passive
            WORDLIST passive "cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput";;
        *)  print_usage;exit 1;;
        esac;;
    *) print_usage;exit 1 ;;
  esac
done
