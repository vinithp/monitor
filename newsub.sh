#!/bin/bash
print_usage(){
    printf '%s\n' " NEWSUB - MONITOR NEW SUBDOMAIN "
    printf '\n%s\n%s\n%s\n%s\n' '-h: help' '-b: provid domain for initial run ' '-i: install dependence' '-m: provid domain to monitor new subdomains'
    printf '\n%s\n' 'useage: ./newsub.sh -m example.com'
}

install(){
    mkdir -p ~/bug/newsub/
    mkdir -p ~/tools/my/
    cp -r ~/newsub ~/tools/my/
    mkdir -p ~/.config/amass/jk/
    cp ~/newsub/config/config.ini ~/.config/amass/jk/config.ini
    sudo apt install tmux
    go version || (wget https://dl.google.com/go/go1.16.5.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.16.5.linux-amd64.tar.gz)
    amass -version || go get -v github.com/OWASP/Amass/v3/...
    echo -e 'tmuxr(){\ntmux attach-session -t $1\n}' >> ~/.bashrc
    echo -e 'tmuxs(){\ntmux new -s $1\n}' >> ~/.bashrc
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:/usr/local/bin/' >> ~/.bashrc
}
brun(){
    touch ~/bug/newsub/new_$domain ~/bug/newsub/all_$domain
    amass enum -config ~/.config/amass/jk/config.ini -passive -d $domain -nocolor | tee ~/bug/newsub/new_$domain

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
while getopts 'hib:m:' flag; do
    case $flag in
        h)print_usage ;;
        i)install ;;
        b)domain=${OPTARG} && brun ;;
        m)domain=${OPTARG} && newsub ;;
        *)print_usage ;;
    esac
done

