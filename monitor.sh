#!/bin/bash
print_usage(){
    printf '%s\n' " MONITORING TOOL "
    printf '\n%s\n%s\n%s\n%s\n%s\n' '-h: help' '-i: install dependence' '-d: provid domain' '-s: subdomain monitor [f: first run][m: start monitoring]' '-g: github monitor [query search]'
    printf '\n%s\n' 'useage: ./newsub.sh -m example.com'
}

unset domain
unset arg

install(){
    cd
    mkdir -p ~/bug/newsub/
    mkdir -p ~/tools/my/
    cp -r ~/newsub ~/tools/my/
    mkdir -p ~/.config/amass/jk/
    mkdir -p ~/.config/amass/jk2/
    cp ~/newsub/config/config.ini ~/.config/amass/jk/config.ini
    cp ~/newsub/config/config.ini2 ~/.config/amass/jk2/config.ini
    echo -e 'tmuxr(){\ntmux attach-session -t $1\n}' >> ~/.bashrc
    echo -e 'tmuxs(){\ntmux new -s $1\n}' >> ~/.bashrc
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:/usr/local/bin/' >> ~/.bashrc
    source ~/.bashrc
    sudo apt install tmux
    go version || (wget https://dl.google.com/go/go1.16.5.linux-amd64.tar.gz && sudo tar -C /usr/local -xzf go1.16.5.linux-amd64.tar.gz)
    python3 --version || sudo apt install python3
    python --version || sudo apt install python

    #=======newsub requirements==============#
    amass -version || go get -v github.com/OWASP/Amass/v3/...
    
    #=======jsmonitor requirements==============#
    GO111MODULE=on go get -u -v github.com/lc/gau
    go get -u github.com/ffuf/ffuf
    GO111MODULE=on go get -v github.com/projectdiscovery/httpx/cmd/httpx
    go get -u github.com/tomnomnom/unfurl
    git clone https://github.com/robre/jsmon.git 
    cd jsmon
    sudo python3 setup.py install
}

subdomain(){
    count=1
    while true
    do
        ~/tools/my/newsub/./newsub.sh -d $domain $arg
        [ $arg == '-f' ] && exit 0
        echo -e "\n===========sleeping $count time============\n"
        sleep 1h
        ((count=count+1))
    done
}
githubrecon(){
    count=1
    while true
    do
        ~/tools/my/newsub/./githubrecon -q $domain -t $arg
        echo -e "\n===========sleeping $count time============\n"
        sleep 24h
        ((count=count+1))

    done
}



[ $# -gt 0 ] || (print_usage && exit 0)
while getopts 'hid:s:g:' flag; do
    case $flag in
        h)print_usage ;;
        i)install ;;
        d)domain=${OPTARG} ;;
        s)([ ! -z $domain ] && [ ! -z ${OPTARG} ]) && arg="-${OPTARG}"; subdomain ;;
        g)([ ! -z $domain ] && [ ! -z ${OPTARG} ]) && arg="${OPTARG}"; githubrecon ;;
        *)print_usage ;;
    esac
done
