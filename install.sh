#! /usr/bin/bash

################
if [ ! -d /opt ];then
    sudo mkdir /opt
fi

if [ ! -d /opt/bin ];then
    sudo mkdir /opt/bin
fi

################ Tools ################
# go
sudo apt install golang

# findomain
cd /opt
sudo git clone https://github.com/findomain/findomain.git
cd findomain
cargo build --release
sudo cp target/release/findomain /opt/bin

# amass
go install -v github.com/OWASP/Amass/v3/...@master

# github-subdomains
go install github.com/gwen001/github-subdomains@latest

# gobuster
sudo apt install gobuster

# httpx
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest

# github-endpoints
go install github.com/gwen001/github-endpoints@latest

# waybackurls
go install github.com/tomnomnom/waybackurls@latest

# gau
go install github.com/lc/gau/v2/cmd/gau@latest

# gospider
go install github.com/jaeles-project/gospider@latest

# unfurl
go install github.com/tomnomnom/unfurl@latest

# subjs
go install github.com/lc/subjs@latest

# linkfinder.py
cd /opt
sudo git clone https://github.com/GerbenJavado/LinkFinder
cd LinkFinder
pip3 install -r requirements.txt
sudo python setup.py install
cd
sudo ln -s /opt/LinkFinder/linkfinder.py /opt/bin

# NtHiM
cargo install NtHiM

# whatweb
sudo apt install whatweb

# gf
go install github.com/tomnomnom/gf@latest

# qsreplace
go install github.com/tomnomnom/qsreplace@latest

# arjun
pip3 install arjun

# kxss
go install github.com/Emoe/kxss@latest

# nuclei
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
nuclei -validate

################ Wordlists ################
# gf-patterns
# seclists
# assestnotes wordlists