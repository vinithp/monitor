#!/bin/bash

set -o errexit
set -o nounset

print_usage() {
    printf "%s\n\n%s\n" 'This is passive/active recon tool' ' options: '
    printf "\t%s %s % -13s %s\n\n" -d = "domain name" '(example.com)'
    printf "\t%s %s % -13s %s\n" -r = "features" '(ip|asn|passive|active|all|single)'
    printf " %s\n" 'NOTE   : USE -d FLAG BEFORE -r '
    printf " %s\n" 'example: ./recon.sh -d google.com -r all'

}

[ $# -gt 0 ] || print_usage
while getopts 'hr:d:' flag; do
  case "${flag}" in
    h) print_usage;exit 1 ;;
    d) case "${OPTARG}" in
        [a-zA-Z0-9_-]*.[a-z]*)
            domain=${OPTARG};;
        *)
            print_usage;exit 1;;
        esac;;
    r) case "${OPTARG}" in
        asn) 
            ip=$domain
            ips=1
            ANS
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
            A_URLS passive
            WORDLIST passive "cat $path/passive/allsubdomain $path/passive/gaurl $path/passive/sitemapurl $path/passive/roboturl $path/passive/commoncrawl1 $path/passive/spideroutput"
            A_SUBDOMAIN
            A_URLS active
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
