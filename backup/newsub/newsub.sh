#!/bin/bash
print_usage(){
    printf '%s\n' " NEWSUB - MONITOR NEW SUBDOMAIN "
    printf '\n%s\n%s\n%s\n' '-h: help' '-i: install dependence' '-m: provid domain to monitor new subdomains'
    printf '\n%s\n' 'useage: ./newsub.sh -m example.com'
}

install(){
    mkdir -p ~/bug/newsub/
    mkdir -p ~/tools/my/
    cp -r ~/newsub ~/tools/my/
    touch ~/bug/newsub/new_$domain ~/bug/newsub/all_$domain
    mkdir -p ~/.config/amass/jk/
    cp ~/newsub/config/config.ini ~/.config/amass/jk/config.ini
    go get -v github.com/OWASP/Amass/v3/...
}

newsub(){
    while true 
    do
        amass enum -config ~/.config/amass/jk/config.ini -passive -d $domain -nocolor | tee ~/bug/newsub/new_$domain 
        comm -1 -3 <(sort ~/bug/newsub/new_$domain) <(sort ~/bug/newsub/all_$domain) | (grep . || echo no) | tee -a ~/bug/newsub/deleted | sed 's/$/ deleted/' | ~/tools/my/newsub/./tnotify.sh
        comm -2 -3 <(sort ~/bug/newsub/new_$domain) <(sort ~/bug/newsub/all_$domain) | (grep . || exit 0) | sed 's/$/ added/' | ~/tools/my/newsub/./tnotify.sh
        cp ~/bug/newsub/new_$domain ~/bug/newsub/all_$domain
        sleep 1h
    done

}

[ $# -gt 0 ] || (print_usage && exit 0)
while getopts 'him:' flag; do
    case $flag in
        h)print_usage ;;
        i)install ;;
        m)domain=${OPTARG} && newsub ;;
        *)print_usage ;;
    esac
done