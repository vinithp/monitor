#!/bin/bash
set -e

setup(){
    cp -r ~/backup/tools ~/tools
    cd
    set +e
    mkdir ~/.config;mkdir ~/.config/amass;mkdir ~/.config/amass/jk;mkdir ~/.local;mkdir ~/.local/bin

    set -e
    echo -e 'tmuxr(){\ntmux attach-session -t $1\n}' >> ~/.bashrc
    echo 'tmuxs(){\ntmux new -s $1\n}' >> ~/.bashrc
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
    echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc 
    echo 'export PATH=$PATH:/usr/local/bin/' >> ~/.bashrc
    cp ~/tools/my/rcfile/vimrc ~/.vimrc
    cp ~/tools/my/config/config.ini ~/.config/amass/jk/
}

install(){
    sudo apt update
    sudo apt install whois
    sudo apt install jq
    sudo apt install python2
    sudo apt install python3
    sudo apt install python3-pip
    curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
    sudo python2 get-pip.py
    rm get-pip.py

    go version || (wget https://dl.google.com/go/go1.16.5.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.16.5.linux-amd64.tar.gz)
    node --version || (curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash - && sudo apt-get install -y nodejs)

    npm install request
    npm install decode-html
    python3 -m pip install typer
    pip2 install py-altdns
    GO111MODULE=on go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder
    go get -u github.com/tomnomnom/assetfinder
    go get -u github.com/tomnomnom/httprobe
    GO111MODULE=on go get -u -v github.com/lc/gau
    go get github.com/tomnomnom/waybackurls
    go get -u github.com/jaeles-project/gospider
    go get -v github.com/OWASP/Amass/v3/...
    wget https://raw.githubusercontent.com/tomnomnom/hacks/master/tok/main.go && go build main.go && mv main ~/go/bin/tok

    cd ~/tools
    git clone https://github.com/gwen001/github-search.git
    git clone https://github.com/blechschmidt/massdns.git
    cd ~/tools/massdns
    make
    sudo cp ~/tools/massdns/bin/massdns ~/.local/bin/
}
[ $# == 0 ] && echo -e "missing flags\nflags :(all, setup, install)" && exit 1
[ $1 == 'all' ] && setup && install
[ $1 == 'setup' ] && setup
[ $1 == 'install' ] && install

