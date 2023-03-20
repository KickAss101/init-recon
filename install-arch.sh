#! /usr/bin/bash

echo "Tools are saved: /opt"
echo "Tools binaries are saved: /opt/bin"

# Add /opt/bin to PATH if not already present

# Create directories if not already present
if [ ! -d /opt ];then
    sudo mkdir /opt
fi
if [ ! -d /opt/bin ];then
    sudo mkdir /opt/bin
fi

### Print any uninstalled tools ###
tools=("anewer" "naabu" "dalfox" "findomain" "altdns" "amass" "subfinder" "github-subdomains" "puredns" "massdns" "cargo" "ripgen" "dnsx" "gobuster" "httpx" "github-endpoints" "gau" "gospider" "unfurl" "subjs" "xnLinkFinder.py" "nuclei" "whatweb" "gf" "qsreplace" "kxss" "arjun")

for tool in "${tools[@]}"; do
    if ! command -v $tool > /dev/null 2>&1; then
        echo -e "\033[31mInstall $tool missing\033[0m"
    else
        echo -e "\033[32mFound $tool \033[0m"
    fi
done

### Tools ###
# pacman installs
sudo pacman -Syu
sudo pacman -S go lolcat figlet jq cargo blackarch/gau blackarch/altdns blackarch/seclists blackarch/naabu blackarch/findomain blackarch/nuclei blackarch/dalfox blackarch/arjun blackarch/qsreplace blackarch/gf blackarch/subjs blackarch/massdns blackarch/gobuster blackarch/whatweb blackarch/subfinder blackarch/amass blackarch/dnsx blackarch/httpx blackarch/gospider blackarch/unfurl

# github-subdomains
if ! command -v github-subdomains > /dev/null 2>&1; then
    go install github.com/gwen001/github-subdomains@latest
fi

# puredns
if ! command -v puredns > /dev/null 2>&1; then
    go install github.com/d3mondev/puredns/v2@latest
fi

# github-endpoints
if ! command -v github-subdomains > /dev/null 2>&1; then
    go install github.com/gwen001/github-endpoints@latest
fi

# kxss
if ! command -v kxss > /dev/null 2>&1; then
    go install github.com/Emoe/kxss@latest
fi

# nuclei
nuclei -validate

# ripgen
if ! command -v ripgen > /dev/null 2>&1; then
    cargo install ripgen
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

# anewer
if ! command -v anewer > /dev/null 2>&1; then
    cargo install anewer
fi

### Wordlists ###
# gf-patterns
if [ ! -d /opt ];then
    mkdir ~/.gf
fi
cp go/pkg/mod/github.com/tomnomnom/gf*/examples/*.json ~/.gf 2>/dev/null
cd /opt
git clone https://github.com/1ndianl33t/Gf-Patterns 2>/dev/null
mv Gf-Patterns/*.json ~/.gf 2>/dev/null

# resolvers
if [ ! -d ~/git/wordlists ];then
    mkdir -p ~/git/wordlists
fi
git clone https://github.com/trickest/resolvers
git clone https://github.com/KickAss101/ALL.TXTs
git clone https://github.com/six2dez/OneListForAll

# assestnotes wordlists

### Print any uninstalled tools ###
tools=("anew" "naabu" "dalfox" "findomain" "amass" "altdns" "subfinder" "github-subdomains" "puredns" "massdns" "cargo" "ripgen" "dnsx" "gobuster" "httpx" "github-endpoints" "gau" "gospider" "unfurl" "subjs" "xnLinkFinder.py" "nuclei" "whatweb" "gf" "qsreplace" "kxss" "arjun")

for tool in "${tools[@]}"; do
    if ! command -v $tool > /dev/null 2>&1; then
        echo -e "\033[31mInstall $tool manually\033[0m"
    fi
done