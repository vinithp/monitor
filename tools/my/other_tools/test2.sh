#!/bin/bash

set -o errexit
#set -o nounset
print_usage() {
    printf "%s\n\n%s\n" 'This is passive/active recon tool' ' options: '
    printf "\t%s %s % -13s %s\n" -r = "features" '(ip|asn|passive|active|all|single)'
    printf "\t%s %s % -13s %s\n\n" -d = "domain name" '(example.com)'
    printf " %s\n" 'example: ./recon.sh -r all -d google.com'
}


while getopts 'hd:r:' flag; do
  case "${flag}" in
    h) print_usage;exit 1 ;;
    #d) domain=${OPTARG};echo $domain | grep -E '[a-zA-Z0-9\_\-]+\.+[a-z]{2,}' &>1;;# | grep -E '[a-zA-Z0-9\_\-]+\.+[a-z]+');;
    d) case "${OPTARG}" in
        [a-zA-Z0-9_-]*.[a-z]*)
        domain=${OPTARG};;
        *)
            print_usage;exit 1;;
        esac;;
    r) case "${OPTARG}" in
        all)
            echo $domain;;
    esac;;
    *) print_usage;exit 1;;
esac
done
