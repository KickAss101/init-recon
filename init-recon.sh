#!/usr/bin/bash

usage() 
{ 
    echo "Usage: init-recon.sh [-t <target>] (or) [-f <file>]"
    echo "Example: init-recon.sh -t tesla.com"
    echo "Example: init-recon.sh -f root_domains.txt"
    exit 1
}

# command line Arguments
getopts t:f:h: FLAG;
case $FLAG in
    t) t=$OPTARG;;
    f) f=$OPTARG;;
    *|h) usage;;
esac

dir=$(echo $OPTARG | cut -d "." -f 1)

# Create the output directory if it doesn't exist
if [ ! -d ~/bug-hunting ];then
    mkdir ~/bug-hunting
fi
if [ ! -d ~/bug-hunting/recon ];then
    mkdir ~/bug-hunting/recon
fi
if [ ! -d ~/bug-hunting/recon/$dir ];then
    mkdir ~/bug-hunting/recon/$dir
fi

# Setting flags for file or domain | reduces code
if [ $FLAG = "t" ]; then
    findomain_flag=t
    amass_flag=d
    subfinder_flag=d
else
    findomain_flag=f
    amass_flag=df
    subfinder_flag=dL
    cp $OPTARG ~/bug-hunting/recon/$dir
fi

# Print the name of the script with figlet
echo init-recon.sh | figlet -c| lolcat -ad 2

# Print the output directory
cd ~/bug-hunting/recon/$dir
echo
echo "+++++ Storing data here: $(pwd) +++++" | lolcat -i
echo

# Variables & Wordlists
nameservers=~/git/wordlists/ALL.TXTs/nameservers.txt
permutations=~/git/wordlists/ALL.TXTs/permutations.txt
waymore_path=~/tools/waymore/results

################################# Subdomain enumeration Starts #################################
mkdir subs
# subdomain enum with findomain
tput setaf 42; echo -n "[+] subs enum: findomain "
findomain -$findomain_flag $OPTARG -q --lightweight-threads 25 -u subs/subs.findomain &>/dev/null
tput setaf 3; echo "[$(sort -u subs/subs.findomain 2>/dev/null | wc -l)]"
sleep 2

# subdomain enum with subfinder
tput setaf 42; echo -n "[+] subs enum: subfinder "
subfinder -$subfinder_flag $OPTARG -silent -t 25 >> subs/subs.subfinder
tput setaf 3; echo "[$(sort -u subs/subs.subfinder 2>/dev/null | wc -l)]"
sleep 2

# subdomain enum with amass active
tput setaf 42; echo -n "[+] subs enum: amass "
amass enum -$amass_flag $OPTARG -src -passive -alts -active -max-depth 5 -brute -silent -dir ./amass-active
cat amass-active/amass.json | jq .name -r | sort -u > subs/subs.amass
tput setaf 3; echo "[$(cat subs/subs.amass 2>/dev/null | wc -l)]"
sleep 2

# subdomain enum with github-subdomains
tput setaf 42; echo -n "[+] subs enum: github-subdomains "
if [ $FLAG = "t" ]; then
    github-subdomains -d $OPTARG -o subs.github-unsort &>/dev/null
    sort -u subs.github-unsort > subs/subs.github && rm subs.github-unsort
else
    cat $OPTARG | while read line; do github-subdomains -d $line -o subs-$line.github-unsort; done >/dev/null
    sort -u subs-*.github-unsort >> subs/subs.github && rm subs-*.github-unsort
fi
tput setaf 3; echo "[$(cat subs/subs.github 2>/dev/null | wc -l)]"
sleep 2

# subdomain permutations with altdns 
tput setaf 42; echo -n "[+] subs permutations: altdns "
sort -u subs/* >> subs.1
altdns -i subs.1 -o subs.all-unsort -w $permutations -t 100
sort -u subs.all-unsort >> subs.altdns && rm subs.all-unsort
tput setaf 3; echo "[$(cat subs.altdns 2>/dev/null | wc -l)]"

# Resolving subdomains & gather IPs with dnsx
tput setaf 42; echo -n "[+] Alive subs from permutations (best to run on VPS) : "
# puredns
# cat subs.altdns | puredns resolve -r $nameservers --write-wildcards subs.wildcards --write subs.puredns &>/dev/null
# dnsx
cat subs.altdns subs.1 | dnsx -silent -a -cdn -re -txt -rcode servfail,refused -r $nameservers -wt 8 -json -o subs.dnsx.json &>/dev/null

# Alive subs after dnsx
cat subs.dnsx.json | jq '.host ' | tr -d '"' | sort -u >> subs.live
tput setaf 3; echo "[$(cat subs.live 2>/dev/null | wc -l)]"

# Wildcard domains
tput setaf 42; echo -n "[+] Wildcard domains : "
tput setaf 3; echo "[$(cat subs.wildcards 2>/dev/null | wc -l)]"

# Non CDN IPs
tput setaf 42; echo -n "[+] Non CDN IPs : "
cat subs.dnsx.json | jq '. | select(.cdn == null) | .a[]' 2>/dev/null | tr -d '"' | sort -u >> IPs.live && rm subs.altdns subs.puredns
tput setaf 3; echo "[$(cat IPs.live 2>/dev/null | wc -l)]"

# CDN IPs
tput setaf 42; echo -n "[+] CDN IPs : "
cat subs.dnsx.json | jq '. | select(.cdn == true) | .a[]' 2>/dev/null | tr -d '"' | sort -u >> IPs.cdn
tput setaf 3; echo "[$(cat IPs.cdn 2>/dev/null | wc -l)]"

# Check http ports with httpx
tput setaf 42; echo -n "[+] subs resolve: httpx "
httpx -l subs.live -x GET,POST -silent -nc -rl 80 -o subs.httpx &>/dev/null
tput setaf 3; echo "[$(sort -u subs.httpx 2>/dev/null | wc -l)]"

# IPs to check in shodan
cat IPs.live | xargs -I {} echo https://www.shodan.io/host/\{\} >> IPs.shodan-urls
sleep 2
################################# Subdomain enumeration Ends #################################

################################# Endpoints enumeration Starts #################################
# Passive URL Enumeration with waymore
tput setaf 42; echo -n "[+] Passive URL enum: waymore "
waymore.py -i $OPTARG -mode U -ow -p 5 -lcc 45 &>/dev/null
if [ $FLAG = "t" ]; then
    mv $waymore_path/$OPTARG/waymore.txt urls.waymore
else
    cat $OPTARG | while read line; do cat $waymore_path/$line/waymore.txt >> urls.waymore; done
fi
# Clean up
tput setaf 3; echo "[$(cat urls.waymore 2>/dev/null | wc -l)]"
sleep 5

# Endpoints enumeration with github-endpoints
tput setaf 42; echo -n "[+] Endpoints enum: github-endpoints "
if [ $FLAG = "t" ]; then
    github-endpoints -d $OPTARG -o urls.github-unsort &>/dev/null
else
    cat $OPTARG | while read line; do github-endpoints -d $line -o urls-$line.github-unsort; done 
fi
# Clean up
sort -u urls.waymore urls*.github-unsort > urls.passive && rm urls.github-unsort urls.waymore
tput setaf 3; echo "[$(cat urls.passive 2>/dev/null | wc -l)]"
sleep 5

# Active URL Enumeration with gospider
tput setaf 42; echo -n "[+] Active Endpoints enum: gospider "
gospider -S subs.httpx -o urls-active -d 3 -c 20 -w -r -q --js --subs --sitemap --robots --blacklist bmp,css,eot,flv,gif,htc,ico,image,img,jpeg,jpg,m4a,m4p,mov,mp3,mp4,ogv,otf,png,rtf,scss,svg,swf,tif,tiff,ttf,webm,webp,woff,woff2 >/dev/null
if [ $FLAG = "t" ]; then
    cat urls-active/* | sed 's/\[.*\] - //' | grep -iE "$OPTARG" | sort -u >> urls.active
else
    roots=$(cat $OPTARG | while read line; do echo -n "$line|"; done | sed 's/.$//')
    cat urls-active/* | sed 's/\[.*\] - //' | grep -iE "($roots)" | sort -u >> urls.active
fi
tput setaf 3; echo "[$(cat urls.active 2>/dev/null | wc -l)]"
sort -u urls.passive urls.active > urls.all && rm urls.passive urls.active
sleep 5
################################# Endpoints enumeration Ends #################################

################################# JS Enumeration Starts #################################
# JS files Enumeration
sort -u urls.all | grep -i ".js"  > urls.js

# Make directories to store js files and to store any keys found from them
mkdir js-files cloud-keys &>/dev/null
# Download JS Files from .js urls
cd js-files
tput setaf 42; echo -n "[+] Downloading js files... "
pv ../urls.js | while read line; do wget $line; done &>/dev/null
tput setaf 3; echo "[Done]"
cd ..

# XNLinkFinder
tput setaf 42; echo -n "[+] Endpoints enum: JS "
# Find urls in JS Files
xnLinkFinder.py -i js-files -o urls.linkfinder -op params.linkfinder &>/dev/null
tput setaf 3; echo "[Done]"
###################### JS Enumeration Ends #################################

########### Grep subdomains from Endpoints ###########
tput setaf 42; echo -n "[+] subs enum: endpoints "
if [ $FLAG = "t" ]; then
    cat urls.all urls.linkfinder | grep -iE "$OPTARG" | unfurl -u domains > subs.new
else
    cat urls.all urls.linkfinder | grep -iE "($roots)" | unfurl -u domains > subs.new
fi
tput setaf 3; echo "[$(cat subs.new | wc -l)]"
sleep 5

########### Probing for live domains from endpoints and js files with httpx ###########
tput setaf 42; echo -n "[+] Probing for live subs with httpx: "
# Save only newly found subs
cat subs.new | anew -d subs.live > subs.altdns-2
# DNS Permutations
altdns -i subs.altdns-2 -o subs.all-unsort -w $permutations -t 100
# Resolve subs with puredns
cat subs.all-unsort | puredns resolve -r $nameservers -t 200 --wildcard-batch 100000 -n 5 --write-wildcards subs.wildcards-2 --write subs.puredns &>/dev/null
# Get A records, CDN info with DNSx
cat subs.puredns | dnsx -silent -a -cdn -re -txt -rcode noerror,servfail,refused -t 250 -rl 300 -r $nameservers -wt 8 -json -o subs.dnsx-2.json &>/dev/null
rm subs.puredns subs.new subs.all-unsort subs.altdns-2
# Extract non CDN IPs
cat subs.dnsx-2.json | jq '. | select(.cdn == null) | .a[]' | tr -d '"' | sort -u > IPs.new
tput setaf 3; echo "[$(cat IPs.new | wc -l)]"
# Extract resolved subs
cat subs.dnsx-2.json | jq '.host ' | tr -d '"' | sort -u > subs.live-2

# Check http ports with httpx
cat subs.live-2 | httpx -silent -nc -t 20 -rl 50 -o subs.httpx-2 &>/dev/null
tput setaf 3; echo "[$(sort -u subs.httpx-2 | wc -l)]"

# House cleaning for resolved subs, subs with http ports and IPs
sort -u subs.httpx subs.httpx-2 > subs.httpx-final && rm subs.httpx subs.httpx-2
sort -u subs.live subs.live-2 > subs.txt && rm subs.live subs.live-2
sort -u subs.wildcards subs.wildcards-2 > wildcard-subs.txt && rm subs.wildcards subs.wildcards-2
sort IPs.live IPs.new > IPs.txt && rm IPs.live IPs.new
echo "Total valid subs: $(cat subs.txt | wc -l)" | lolcat
echo "Total valid IPs: $(cat IPs.txt | wc -l)" | lolcat
sleep 5

### Portscan with naabu for subs ###
naabu -list subs.txt -p- -rate 4000 -o subs.naabu &>/dev/null

### Portscan with naabu for IPs###
naabu -list IPs.txt -p- -rate 4000 -o IPs.naabu &>/dev/null

### Nuclie Test for subs ###
nuclei -l subs.naabu -fr -es info -o subs.nuclei &>/dev/null

### Nuclie Test for IPs ###
nuclei -l IPs.naabu -fr -es info -o IPs.nuclei &>/dev/null

################### Greping Values Starts ###################
### Grep cloud-keys from endpoints ###
tput setaf 42; echo -n "[+] Finding cloud-keys from endpoints: "
cat urls.all | gf aws-keys | sort -u >> cloud-keys/urls.aws-keys
cat urls.all | gf firebase | sort -u >> cloud-keys/urls.firebase
cat urls.all | gf s3-buckets | sort -u >> cloud-keys/urls.s3-buckets
cat urls.all | gf sec | sort -u >> cloud-keys/urls.sec
tput setaf 3; echo "[Done]"
sleep 3

### Grep cloud-keys from JS files ###
tput setaf 42; echo -n "[+] Finding cloud-keys from js files: "
cat js-files/* | gf aws-keys | sort -u >> cloud-keys/js.aws-keys
cat js-files/* | gf firebase | sort -u >> cloud-keys/js.firebase
cat js-files/* | gf s3-buckets | sort -u >>  cloud-keys/js.s3-buckets
cat js-files/* | gf sec | sort -u >> cloud-keys/js.sec
tput setaf 3; echo "[Done]"
sleep 3

### Probing for live urls with httpx ###
tput setaf 42; echo -n "[+] Probing for live urls: httpx "
cat urls.all | qsreplace | sort -u | httpx -silent -nc -rl 100 -o urls.live &>/dev/null
tput setaf 3; echo "[$(sort -u urls.live | wc -l)]"
sleep 3

### Find more params ###
tput setaf 42; echo -n "[+] Finding more params: arjun "
arjun --passive -q -i urls.live -d 1 -oT urls.params-arjun-GET -m GET -t 15  >/dev/null && sleep 60
arjun --passive -q -i urls.live -d 1 -oT urls.params-arjun-POST -m POST -t 15 >/dev/null
# arjun -q -i urls.live -d 1 -oT urls.params-arjun-JSON -m POST-JSON >/dev/null && sleep 180
# arjun -q -i urls.live -d 1 -oT urls.params-arjun-XML -m POST-XML >/dev/null
tput setaf 3; echo "[Done]"
sleep 3

########### Grep endpoints, params, values, keypairs ###########
tput setaf 42; echo "[+] Greping paths, params keys, keypairs: unfurl"
mkdir unfurl
cat urls.params-arjun-GET | unfurl -u paths >> unfurl/paths.txt
cat urls.params-arjun-GET | unfurl -u keys >> unfurl/params.txt
cat urls.params-arjun-GET | unfurl -u keypairs >> unfurl/keypairs.txt
sleep 3

########### Grep urls with params ###########
tput setaf 42; echo -n "[+] Greping urls with params: "
cat urls.live urls.params-arjun-GET | grep "=" | sort -u urls.params | qsreplace FUZZ | sort -u > urls.fuzz
tput setaf 3; echo "[$(cat urls.fuzz | wc -l)]"
sleep 3

########### Run urls against nuclei ###########
tput setaf 42; echo -n "[+] Run urls against nuclei: "
nuclei -l urls.live -fr -es info -o urls.nuclei
tput setaf 3; echo "[Done]"
sleep 3

########### Replace params values as FUZZ with qsreplace ###########
tput setaf 42; echo "[+] Gf patterning urls: gf"
mkdir gf-patterns && cd gf-patterns
cat ../urls.fuzz | gf xss > urls.xss
cat ../urls.fuzz | gf ssrf > urls.ssrf
cat ../urls.fuzz | grep -i "=\/" > urls.take-paths
cat ../urls.fuzz | gf redirect > urls.redirect
cat ../urls.fuzz | gf rce > urls.rce
cat ../urls.fuzz | gf interestingparams > urls.interestingparams
cat ../urls.fuzz | gf http-auth > urls.http-auth
cat ../urls.fuzz | gf upload-fields > urls. upload-fields
cat ../urls.fuzz | gf img-traversal > urls.img-traversal
cat ../urls.fuzz | gf lfi > urls.lfi
cat ../urls.fuzz | gf ip > urls.ip
cat ../urls.fuzz | gf ssti > urls.ssti
cat ../urls.fuzz | gf idor > urls.idor
cat ../urls.fuzz | gf base64 > urls.base64
cat ../urls.fuzz | gf sqli > urls.sqli
cd ..
sleep 3
###################### Greping Values Ends ######################

# Find interesting subs to test
cat subs.httpx-final | gf interestingsubs > subs.interesting

########### Automated tests on gf pattern urls ###########
mkdir automated-test && cd automated-test
tput setaf 42; echo "[+] Running Automated Tests: $(pwd)"

# XSS Test
tput setaf 42; echo "[+] XSS Test: "
cat ../urls.fuzz | kxss | sed s'/URL: //'| qsreplace >> ../urls.params-reflect
dalfox file ../urls.params-reflect --blind $blindXSS -F -o xss-1.log &>/dev/null
dalfox file gf-patterns/urls.xss --blind $blindXSS -F -o xss-2.log &>/dev/null
sleep 180

# SSRF Test

# Redirect Test

# SQLi Test

# LFI Test

# RCE Test

# File Upload Test

# SSTI


###################### Dorks Generation Starts ######################
########### shodan dorks file ###########
if [ $FLAG = "t" ]; then
    cat .shodan.dorks | sed 's|${target}|$OPTARG|'  > shodan-dorks.txt
else
    cat .shodan.dorks | while read line; do sed 's|${target}|$line|'; done  > shodan-dorks-$line.txt
fi
sleep 3
###################### Dorks Generation Ends ######################


########### Cloud Enumeration ###########


########### WhatWeb Recon ###########
# Fingerprint interesting subs and save subs to new file which don't have WAF
# tput setaf 42; echo "[+] Tech stack recon: Whatweb"
# whatweb -i subs-interesting.txt --log-brief=whatweb-brief >/dev/null
# sleep 5