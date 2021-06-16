#!/bin/bash

print_usage(){
    printf "%s\n\n" 'upload/download files/folders form remote'
    printf "%s\n%s\n%s\n%s\n%s\n%s\n" '-h: help''-d: download' '-u: upload' '-H: host (default `root`)' '-i: ip address of remote (default `147.139.44.87`)' '-f: download/uploading files/folders' '-t: download/upload location'
    printf "\n%s" 'useage: ./cloud2local.sh -d -f test.txt -t ~/test.txt'
}

upload(){
    scp -r $from $host@$ip:$to 
}
download(){
    scp -r $host@$ip:$from $to
}

host='root'
ip='147.139.44.87'
unset from
unset to
unset task
[ $# -gt 0 ] || print_usage
while getopts 'hduH:i:f:t:' flag;do
    case "${flag}" in
        h) print_usage; exit 1;;
        H) host="${OPTARG}";;
        i) ip="${OPTARG}";;
        f) from="${OPTARG}";;
        t) to="${OPTARG}";;
        d) task='d'; [ ! -z $from ] && [ ! -z $to ] && download && exit 0|| (print_usage && echo -e "\nfrom: $from\nto: $to\nmissing flag f/t") ;;
        u) task='u'; [ ! -z $from ] && [ ! -z $to ] && upload && exit 0|| (print_usage && echo -e "\nfrom: $from\nto: $to\nmissing flag f/t") ;;
        *) print_usage; exit 1;;
    esac
done

[ -z $task ] && print_usage && echo 'missing flag d/u'



