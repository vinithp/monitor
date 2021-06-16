#!/bin/bash
set -e

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
~/tools/recon/./github-subdomains.py -d $domain | tee -a $path/passive/allsubdomain
echo "P_github-subdomains completed" | tee -a $path/status

#------------shosubgo-----------------#
#go run ~/tools/shodubgo/main.go -d $domain -s aEkJGyRcckezV07ExZqpkDWb5uf7OOKw | tee -a $path/passive/allsubdomain
#echo "P_shodubgo completed" | tee -a $path/passive/status

#------------bufferover---------------#
curl http://tls.bufferover.run/dns?q=$domain | jq '.Results' | awk -F',' '(NF>1) {print $3}' | sed 's/"//g;s/*\.//g' | sort -u | tee -a $path/passive/allsubdomain
echo "P_bufferover completed" | tee -a $path/status

#--------------sorting----------------#
sed -i 's/^\*\.//; s/\/$//' $path/passive/allsubdomain
~/tools/my/recon/./rmwww.sh $path/passive/allsubdomain
sort -u $path/passive/allsubdomain -o $path/passive/allsubdomain
sed -i -n "/\/$domain\|\.$domain\|^ *$domain/p" $path/passive/allsubdomain
echo "P_sorting completed" | tee -a $path/status

#--------calling amass once again------#
cat $path/passive/allsubdomain | xargs -I {} amass enum -config ~/.config/amass/jk/config.ini -passive -asn $asn -d {} -nocolor | tee -a $path/passive/amassagainsubdomain
echo "P_amassagain completed" | tee -a $path/status

sort -u $path/passive/amassagainsubdomain -o $path/passive/amassagainsubdomain
sed -i -n "/\/$domain\|\.$domain\|^ *$domain/p" $path/passive/amassagainsubdomain

~/tools/my/recon/./cm.sh $path/passive/allsubdomain $path/passive/amassagainsubdomain | tee -a $path/passive/allsubdomain
~/tools/my/recon/./rmwww.sh $path/allsubdomain
sed -i '/^[[:space:]]*$/d; s/\.$//' $path/passive/allsubdomain
cp $path/passive/allsubdomain $path/allsubdomain
echo "P_processing_amassagain completed" | tee -a $path/status

#------------massdns--httprobe-----------------#
cat $path/passive/allsubdomain | httprobe | sort -u | tee -a $path/passive/upsubdomains
~/tools/my/recon/./rmhttp.sh $path/passive/upsubdomains
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
altdns -i $path/allsubdomain -w $path/passive/subwordlist -o $path/active/altlist
cat $path/active/altlist | grep -xavf $path/active/altbrutelist | tee -a $path/active/altbrutelist
altdns -i $path/allsubdomain -w ~/tools/my/my_word/subdomain/my300.txt -o $path/active/altlist
cat $path/active/altlist | grep -xavf $path/active/altbrutelist | tee -a $path/active/altbrutelist

echo "A_altdns completed" | tee -a $path/status

#-----------massdns--------------------------#
massdns -r ~/tools/massdns/lists/resolvers.txt -q -t A -o S $path/active/altbrutelist | tee -a $path/active/cname | awk -F' ' '{print $1}' | tee -a $path/active/brutdomain | sed 's/\.$//; s/^*\.//; s/\/$//' | grep -xavf $path/allsubdomain | tee -a $path/active/allsubdomain 
echo "A_massdns completed" | tee -a $path/status

sed -i -n "/\/$domain\|\.$domain\|^ *$domain/p" $path/active/allsubdomain
sed -i '/^[[:space:]]*$/d' $path/active/allsubdomain
cat $path/active/allsubdomain | tee -a $path/allsubdomain
~/tools/my/recon/./rmwww.sh $path/active/allsubdomain

#------------httprobe----------------#
cat $path/active/allsubdomain | httprobe | sort -u | tee -a $path/active/upsubdomains
~/tools/my/recon/./rmhttp.sh $path/active/upsubdomains
cat $path/active/upsubdomains | tee -a $path/upsubdomains
echo "A_httprobe completed" | tee -a $path/status

#-------amass------#
cat $path/active/upsubdomains | xargs -I {} amass enum -config ~/.config/amass/jk/config.ini -passive -asn $asn -d {} -nocolor | sed 's/\.$//' | tee -a $path/active/amassagainsubdomain
cat $path/active/upsubdomains | xargs -I {} amass enum -brute -config ~/.config/amass/jk/config.ini -asn $asn -d {} -nocolor | sed 's/\.$//' | tee -a $path/active/amassagainsubdomain
echo "A_amass completed" | tee -a $path/status

sort -u $path/active/amassagainsubdomain -o $path/active/amassagainsubdomain
~/tools/my/recon/./cm.sh $path/allsubdomain $path/active/amassagainsubdomain | tee -a $path/active/allsubdomain
cat $path/active/amassagainsubdomain | httprobe | sort -u | tee -a $path/active/upsubdomains

}

P_URLS(){
#------------gau--------------------#
cat $path/target | gau -subs | ~/tools/my/recon/./pygrep.py urldc | ~/tools/my/recon/./pygrep.py htmldc | grep -a $domain | tee -a $path/passive/gaurl 
echo "gau completed" | tee -a $path/status

#----------waybackurls--------------#
cat $path/target | waybackurls | ~/tools/my/recon/./pygrep.py urldc | ~/tools/my/recon/./pygrep.py htmldc | grep -a $domain | tee -a $path/passive/gaurl
echo "waybackurls completed" | tee -a $path/status
sed -i 's/:80//;s/:443//' $path/passive/gaurl
echo "sed remove :80 :443 completed" | tee -a $path/status
sort -u $path/passive/gaurl -o $path/passive/gaurl
echo "sort gaurl completed" | tee -a $path/status
~/tools/my/recon/./link.sh domain $path/passive/gaurl | sort -u | grep -a $domain | tee -a $path/passive/gaurldomain
#~/tools/my/recon/./cm.sh $path/passive/allsubdomain $path/passive/gaurldomain | sed 's/https*:\/\///' | tee -a $path/passive/allsubdomain

#-----------commoncrawl-------------#
curl -sL http://index.commoncrawl.org | grep -a 'href="/CC' | awk -F'"' '{print $2}' | xargs -n1 -I{} curl -sL http://index.commoncrawl.org{}-index?url=*.$domain/* |  awk -F'"url": "' '{print $2}' | cut -d'"' -f1 | ~/tools/my/recon/./pygrep.py urldc | ~/tools/my/recon/./pygrep.py htmldc | grep -a $domain | sort -u | tee -a $path/passive/commoncrawl1
sort -u $path/passive/commoncrawl1 -o $path/passive/commoncrawl1
echo "commoncrawl completed" | tee -a $path/status
}
SPIDER(){
#----------spider-------------------#
#cat $path/passive/allsubdomain | sed 's/^/https:\/\//' | tee -a $path/passive/spiderinput
gospider -S $path/$1/upsubdomains -c 10 -d 3 | ~/tools/my/recon/./pygrep.py urldc | ~/tools/my/recon/./pygrep.py htmldc | sed 's/\[.*\] \- //' | tee -a $path/$1/spideralloutput | grep -a $domain | tee -a $path/$1/spideroutput
sort -u $path/$1/spideroutput -o $path/$1/spideroutput
echo "$1_spider completed" | tee -a $path/status
}

A_URLS(){
#-----------sitemap------------------#
while read i; do echo $i | ~/tools/my/recon/./link.sh domain-path | tee -a $path/$1/sitemapurl;  done < <( cat $path/$1/upsubdomains | sed 's/$/\/sitemap.xml/' | ~/tools/my/recon/./jstool.js -curl ) 
echo "$1_sitemap completed" | tee -a $path/status

#------------robot------------------#
while read i; do echo $i | ~/tools/my/recon/./link.sh domain-path | tee -a $path/$1/roboturl; done < <( cat $path/$1/upsubdomains | sed 's/$/\/robots.txt/' | ~/tools/my/recon/./jstool.js -curl ) 
echo "$1_roboturl completed" | tee -a $path/status

cat $path/$1/sitemapurl | grep -a $domain | ~/tools/my/recon/./pygrep.py urldc | ~/tools/my/recon/./pygrep.py htmldc | sort -u -o $path/$1/sitemapurl 
cat $path/$1/roboturl | grep -a $domain | ~/tools/my/recon/./pygrep.py urldc | ~/tools/my/recon/./pygrep.py htmldc | sort -u -o $path/$1/roboturl 
}


WORDLIST(){
$2 | sed 's/'$domain.*'//; s/https*:\/\/\**//g; s/\./\n/g; s/[^[:alnum:]\_\-]/\n/g'  | sort -u | tee -a $path/$1/subwordlist | tee -a $path/wordlist/tarwordlist
$2 | sed 's/https*:\/\/.*'$domain'//g; s/\//\n/g; s/\?.*//g; s/\+//g; s/[^[:alnum:]\_\.\-]/\n/g' | grep -Eav '\.|[^a-zA-Z0-9]+' | sort -u | tee -a $path/$1/dirwordlist | tee -a $path/wordlist/tarwordlist
$2 | sed 's/https*:\/\/.*'$domain'//g; s/\?.*//; s/[^[:alnum:]\.\_\-]/\n/g' | awk -F'/' '{print $NF}' | grep -a '.\+\.' | grep -Eva '\.[a-zA-Z0-9\_\-]{7,}$' | grep -Eva "\.com|\.net|\.org" | grep -Eva "\.$" | grep -Eva "\.[0-9]+$" | sort -u | tee -a $path/$1/filewordlist_temp 
$2 | grep -oa '\?.*' | grep -Eao "\?[a-zA-Z0-9]*[^\=]+|\&[a-zA-Z0-9]*[^\=]+" | sed 's/\+//g; s/[^[:alnum:]\?\&\_\-]/\n/g' | sort -u | tee -a $path/$1/parameterwordlist
~/tools/my/recon/./cm.sh $path/allsubdomain $path/$1/filewordlist_temp | tee -a $path/$1/filewordlist 
rm $path/$1/filewordlist_temp
echo "$1_wordlists completed" | tee -a $path/status

cat $path/$1/upsubdomains | ~/tools/my/recon/./jstool.js -curl | tok | sort -u | grep -xavf ~/tools/my/files/filterwords | grep -xavf $path/wordlist/tarwordlist | sed '/^[[:space:]]*$/d' | tee -a $path/wordlist/tarallwords
sort -u $path/wordlist/tarwordlist -o $path/wordlist/tarwordlist 
echo "$1_tarallwords completed" | tee -a $path/status

}

#------------scanning ip---------------#
IPSCAN(){
cat $path/allsubdomain | sed 's/https*:\/\///' | xargs -I {} ~/tools/my/recon/./recon.sh ip {} | tee $path/subips

while read -r lines; do
line=$(echo $lines | awk '{print $2}')
printf '%-30s %-15s %-15s %-15s\n' $(echo $lines && whois -h whois.arin.net $line | grep -m2 'CIDR\|Organization' | awk '{passive="";print $2}') | tee -a $path/ipcidr
done < $path/subips
rm $path/subips
}

#========================finishing================================#
FINISH(){
    mkdir $path/finished_$domain
    cp -t $path/finished_$domain/ $path/allsubdomain $path/upsubdomains $path/passive/commoncrawl1 $path/passive/dirwordlist $path/passive/filewordlist $path/passive/gaurl $path/passive/parameterwordlist $path/passive/roboturl $path/passive/sitemapurl $path/passive/spideroutput $path/passive/subwordlist $path/active/cname $path/wordlist/tarwordlist $path/status

   cat $path/active/dirwordlist >> $path/finished_$domain/dirwordlist
   cat $path/active/filewordlist >> $path/finished_$domain/filewordlist
   cat $path/active/parameterwordlist  >> $path/finished_$domain/parameterwordlist
   cat $path/active/roboturl >> $path/finished_$domain/roboturl
   cat $path/active/sitemapurl >> $path/finished_$domain/sitemapurl
   cat $path/active/spideroutput >> $path/finished_$domain/spideroutput
   cat $path/active/subwordlist  >> $path/finished_$domain/subwordlist
   echo "finished" | tee -a $path/status | tee -a $path/finished_$domain/status
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

#========================================================================================

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
            set +e
    	    mkdir ~/bug/$domain
	    path=~/bug/$domain
    	    mkdir $path/passive
	    mkdir $path/wordlist
            set -e
	    echo $domain | tee -a $path/passive/allsubdomain | tee $path/target
	    IP
	    ASN
	    P_SUBDOMAIN
	    P_URLS
            SPIDER passive
    	    A_URLS passive
    	    WORDLIST passive "cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput"
            FINISH ;;
        active)
            set +e
            mkdir ~/bug/$domain
            path=~/bug/$domain
            mkdir $path/active
            mkdir $path/wordlist
            set -e
            echo $domain | tee $path/target
            IP
            ASN
            A_SUBDOMAIN
            SPIDER active
            A_URLS active
            WORDLIST active "cat $path/active/allsubdomain $path/active/sitemapurl $path/active/roboturl $path/active/spideroutput"
            FINISH ;;
        all)
            set +e
            mkdir ~/bug/$domain
            path=~/bug/$domain
            mkdir $path/active
            mkdir $path/passive
            mkdir $path/wordlist
            set -e
            echo $domain | tee -a $path/passive/allsubdomain | tee $path/target
            IP
            ASN
            P_SUBDOMAIN
            P_URLS
            SPIDER passive
            A_URLS passive
            WORDLIST passive "cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput"
            A_SUBDOMAIN
            SPIDER active
            A_URLS active
            WORDLIST active "cat $path/active/allsubdomain $path/active/sitemapurl $path/active/roboturl $path/active/spideroutput"
            FINISH ;;
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
