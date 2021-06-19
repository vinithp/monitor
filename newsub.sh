#!/bin/bash
print_usage(){
    printf '%s\n' " NEWSUB - MONITOR NEW SUBDOMAIN "
    printf '\n%s\n%s\n%s\n%s\n' '-h: help' '-d: provid domain to monitor' '-f: first run' '-m: monitoring for subdomain'
    printf '\n%s\n' 'useage: ./newsub.sh -d example.com -m'
}
unset domain

first_run(){
    touch ~/bug/newsub/new_$domain ~/bug/newsub/all_$domain
    amass enum -config ~/.config/amass/jk/config.ini -passive -d $domain -nocolor | tee ~/bug/newsub/all_$domain

}

newsub(){
    amass enum -config ~/.config/amass/jk2/config.ini -passive -d $domain -nocolor | tee ~/bug/newsub/new_$domain
    comm -1 -3 <(sort ~/bug/newsub/new_$domain) <(sort ~/bug/newsub/all_$domain) | (grep . || exit 0) | tee -a ~/bug/newsub/deleted | sed 's/$/ deleted/' | ~/tools/my/newsub/./tnotify.sh
    comm -2 -3 <(sort ~/bug/newsub/new_$domain) <(sort ~/bug/newsub/all_$domain) | (grep . || exit 0) | sed 's/$/ added/' | ~/tools/my/newsub/./tnotify.sh
    cp ~/bug/newsub/new_$domain ~/bug/newsub/all_$domain
}

#=======================================#

[ $# -gt 0 ] || (print_usage && exit 0)
while getopts 'hmfd:' flag; do
    case $flag in
        h)print_usage ;;
        d)domain=${OPTARG} ;;
        f)([ -z $domain ] && print_usage) || first_run ;;
        m)([ -z $domain ] && print_usage) || newsub ;;
        *)print_usage ;;
    esac
done

