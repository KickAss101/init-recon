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
if [ ! -d ~/git ];then
    sudo mkdir ~/git
fi
if [ ! -d ~/git/wordlists ];then
    mkdir ~/git/wordlists
fi

# Change /opt ownership
sudo chown -Rh $USER:$USER /opt

### Print any uninstalled tools ###
tools=("anewer" "naabu" "pv" "dalfox" "findomain" "altdns" "amass" "subfinder" "github-subdomains" "puredns" "massdns" "cargo" "ripgen" "dnsx" "gobuster" "httpx-toolkit" "github-endpoints" "gau" "gospider" "unfurl" "subjs" "xnLinkFinder.py" "nuclei" "whatweb" "gf" "qsreplace" "kxss" "arjun")

for tool in "${tools[@]}"; do
    if ! command -v $tool > /dev/null 2>&1; then
        echo -e "\033[31mInstall $tool missing\033[0m"
    else
        echo -e "\033[32mFound $tool \033[0m"
    fi
done

### Tools ###
# apt installs
sudo apt update -y
echo -e "\033[32mAPT Installs \033[0m"
sudo apt install seclists httpx-toolkit pv python3 python3-pip altdns naabu golang-go lolcat figlet jq cargo massdns gobuster whatweb -y

# Add go bin to path
echo $PATH | grep -q "go/bin" && echo "go/bin is in PATH" || echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.zshrc

# Add cargo bin to path
echo $PATH | grep -q ".cargo/bin" && echo ".cargo/bin is in PATH" || echo 'export PATH=$PATH:$HOME/.cargo/bin' >> ~/.zshrc

# Add /opt/bin to path
echo $PATH | grep -q "/opt/bin" && echo "/opt/bin is in PATH" || echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.zshrc

source ~/.zshrc

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
fi

# ripgen
if ! command -v ripgen > /dev/null 2>&1; then
    cargo install ripgen
fi

# arjun
if ! command -v arjun > /dev/null 2>&1; then
    pip install arjun
fi

# Dalfox
if ! command -v dalfox > /dev/null 2>&1; then
    go install github.com/hahwul/dalfox/v2@latest
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

# gau
if ! command -v gau > /dev/null 2>&1; then
go install github.com/lc/gau/v2/cmd/gau@latest
fi

# anewer
if ! command -v anewer > /dev/null 2>&1; then
    cargo install anewer
fi

### Wordlists ###
# gf-patterns
if [ ! -d /.gf ];then
    mkdir ~/.gf
fi
cp ~/go/pkg/mod/github.com/tomnomnom/gf*/examples/*.json ~/.gf 2>/dev/null
cd /opt
git clone https://github.com/1ndianl33t/Gf-Patterns 2>/dev/null
mv Gf-Patterns/*.json ~/.gf 2>/dev/null

# resolvers
cd ~/git/wordlists
git clone https://github.com/trickest/resolvers
git clone https://github.com/KickAss101/ALL.TXTs
git clone https://github.com/six2dez/OneListForAll

# assestnotes wordlists

### Print any uninstalled tools ###
tools=("anewer" "naabu" "dalfox" "pv" "findomain" "altdns" "amass" "subfinder" "github-subdomains" "puredns" "massdns" "cargo" "ripgen" "dnsx" "gobuster" "httpx-toolkit" "github-endpoints" "gau" "gospider" "unfurl" "subjs" "xnLinkFinder.py" "nuclei" "whatweb" "gf" "qsreplace" "kxss" "arjun")
for tool in "${tools[@]}"; do
    if ! command -v $tool > /dev/null 2>&1; then
        echo -e "\033[31mInstall $tool manually\033[0m"
    fi
done