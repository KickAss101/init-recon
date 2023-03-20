#! /usr/bin/bash

echo "Tools are saved: /opt"
echo "Tools binaries are saved: /opt/bin"

# Create directories if not already present
if [ ! -d /opt ];then
    sudo mkdir /opt
fi
if [ ! -d /opt/bin ];then
    sudo mkdir /opt/bin
fi

### Tools ###
# apt installs
sudo apt update -y
echo "APT Installs"
sudo apt install python3 altdns naabu golang-go lolcat figlet jq cargo massdns gobuster whatweb -y

# amass
if ! command -v amass > /dev/null 2>&1; then
    go install -v github.com/OWASP/Amass/v3/...@master
fi

#subfinder
if ! command -v subfinder > /dev/null 2>&1; then
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
fi

# github-subdomains
if ! command -v github-subdomains > /dev/null 2>&1; then
    go install github.com/gwen001/github-subdomains@latest
fi

# puredns
if ! command -v puredns > /dev/null 2>&1; then
    go install github.com/d3mondev/puredns/v2@latest
fi

# dnsx
if ! command -v dnsx > /dev/null 2>&1; then
    go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
fi

# httpx
if ! command -v httpx > /dev/null 2>&1; then
    go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
fi

# github-endpoints
if ! command -v github-subdomains > /dev/null 2>&1; then
    go install github.com/gwen001/github-endpoints@latest
fi

# gospider
if ! command -v gospider > /dev/null 2>&1; then
    go install github.com/jaeles-project/gospider@latest
fi

# unfurl
if ! command -v unfurl > /dev/null 2>&1; then
    go install github.com/tomnomnom/unfurl@latest
fi

# subjs
if ! command -v subjs > /dev/null 2>&1; then
    go install github.com/lc/subjs@latest
fi

# gf
if ! command -v gf > /dev/null 2>&1; then
    go install github.com/tomnomnom/gf@latest
fi

# qsreplace
if ! command -v qsreplace > /dev/null 2>&1; then
    go install github.com/tomnomnom/qsreplace@latest
fi

# kxss
if ! command -v kxss > /dev/null 2>&1; then
    go install github.com/Emoe/kxss@latest
fi

# nuclei
if ! command -v nuclei > /dev/null 2>&1; then
    go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
    nuclei -validate
fi

# ripgen
if ! command -v ripgen > /dev/null 2>&1; then
    cargo install ripgen
fi

# arjun
if ! command -v arjun > /dev/null 2>&1; then
    pip3 install arjun
    sudo apt install arjun &>/dev/null
fi

# Dalfox
if ! command -v dalfox > /dev/null 2>&1; then
    go install github.com/hahwul/dalfox/v2@latest
fi

# waymore.py
if ! command -v waymore.py > /dev/null 2>&1; then
    cd
    mkdir tools
    cd tools
    git clone https://github.com/xnl-h4ck3r/waymore.git
    cd waymore
    sudo python setup.py install
    chmod +x waymore.py
    cd
    sudo ln -s /home/$(whoami)/tools/waymore/waymore.py /opt/bin
fi

# xnLinkFinder.py
if ! command -v xnLinkFinder.py > /dev/null 2>&1; then
    cd /opt
    sudo git clone https://github.com/xnl-h4ck3r/xnLinkFinder.git
    cd xnLinkFinder
    sudo python setup.py install
    sudo chmod +x xnLinkFinder.py
    sudo ln -s /opt/xnLinkFinder/xnLinkFinder.py /opt/bin
fi

# findomain
if ! command -v findomain > /dev/null 2>&1; then
    cd /opt
    sudo curl -LO https://github.com/findomain/findomain/releases/latest/download/findomain-linux.zip
    sudo unzip findomain-linux.zip
    sudo chmod +x findomain
    sudo mv findomain /opt/bin
    cd
fi

# anewer
if ! command -v anewer > /dev/null 2>&1; then
    cargo install anewer
fi

### Wordlists ###
# gf-patterns

# seclists
sudo apt install seclists

# assestnotes wordlists

### Print any uninstalled tools ###
tools=("anewer" "naabu" "dalfox" "altdns" "findomain" "amass" "subfinder" "github-subdomains" "puredns" "massdns" "cargo" "ripgen" "dnsx" "gobuster" "httpx" "github-endpoints" "waymore.py" "gospider" "unfurl" "subjs" "xnLinkFinder.py" "nuclei" "whatweb" "gf" "qsreplace" "kxss" "arjun" "seclists")

for tool in "${tools[@]}"; do
    if ! command -v $tool > /dev/null 2>&1; then
        echo -e "\033[31mInstall $tool manually\033[0m"
    fi
done