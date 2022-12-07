#! /usr/bin/bash

usage() 
{ 
    echo "Usage: init-recon.sh [-t <target>] (or) [-f <file>]"
    echo "Example: init-recon.sh -t tesla.com"
    echo "Example: init-recon.sh -f root_domains.txt"
    exit 1
}

########### command line Arguments ###########
getopts t:f:h FLAG;
case $FLAG in
    t) t=$OPTARG;;
    f) f=$OPTARG;;
    *|h) usage;;
esac

dir=$(echo $OPTARG | cut -d "." -f 1)

########### Create the output directory if it doesn't exist
if [ ! -d ~/bug-hunting ];then
    mkdir ~/bug-hunting
fi
if [ ! -d ~/bug-hunting/recon ];then
    mkdir ~/bug-hunting/recon
fi
if [ ! -d ~/bug-hunting/recon/$dir ];then
    mkdir ~/bug-hunting/recon/$dir
fi

########### Setting flags for file or domain | reduces code ###########
if [ $FLAG = "t" ]; then
    findomain_flag=t
    amass_flag=d
else
    findomain_flag=f
    amass_flag=df
    cp $OPTARG ~/bug-hunting/recon/$dir
fi

########### Print the name of the script with figlet
echo init-recon.sh | figlet -c| lolcat -ad 2

########### Print the output directory
cd ~/bug-hunting/recon/$dir
echo
echo "+++++ Storing data here: $(pwd) +++++" | lolcat -ia
echo

################################# Variables & Wordlists #################################
nameservers=~/git/wordlists/ALL.TXTs/nameservers.txt
permutations=~/git/wordlists/ALL.TXTs/permutations.txt
waymore_path=~/tools/waymore/results

################################# Subdomain enumeration Starts #################################
########### sub enum with findomain, subfinder, amass passive ###########
tput setaf 42; echo -n "[+] subs enum: findomain, subfinder, amass passive "
findomain -$findomain_flag $OPTARG --external-subdomains -q --lightweight-threads 25 -u subs.findomain >/dev/null
sort -u external_subdomains/amass/*.txt external_subdomains/subfinder/*.txt >> subs.findomain
rm -rf external_subdomains
tput setaf 3; echo "[$(sort -u subs.findomain | wc -l)]"
sleep 5

########### subdomain enumeration with amass active ###########
tput setaf 42; echo -n "[+] subs enum: amass active bruteforce "
amass enum -$amass_flag $OPTARG -src -active -max-depth 5 -brute -silent -dir ./amass-active
cat amass-active/amass.json | jq .name -r | sort -u > subs.amass
tput setaf 3; echo "[$(cat subs.amass | wc -l)]"
sleep 5

########### subdomain enumeration with github-subdomains ###########
tput setaf 42; echo -n "[+] subs enum: github-subdomains "
if [ $FLAG = "t" ]; then
    github-subdomains -d $OPTARG -o subs.github-unsort >/dev/null
    sort -u subs.github-unsort > subs.github && rm subs.github-unsort
else
    cat $OPTARG | while read line; do github-subdomains -d $line -o subs-$line.github-unsort; done >/dev/null
    sort -u subs-*.github-unsort > subs.github && rm subs-*.github-unsort
fi
tput setaf 3; echo "[$(cat subs.github | wc -l)]"
sleep 5

########### Subs permutations with ripgen ###########
tput setaf 42; echo -n "[+] subs permutations: ripgen "
sort -u subs.* > subs-all && rm subs.*
ripgen -d subs-all -w $permutations > subs.all-unsort
sort -u subs.all-unsort > subs.all && rm subs.all-unsort
rm subs-all
tput setaf 3; echo "[$(cat subs.all | wc -l)]"

########### Resolving Subs & gather IPs with dnsx ###########
tput setaf 42; echo -n "[+] IPs from subs (best to run on VPS) : "
# puredns
cat subs.all| puredns resolve -r $nameservers -t 200 --wildcard-batch 100000 -n 5 --write subs.puredns &>/dev/null
# dnsx
cat subs.puredns | dnsx -silent -a -cdn -re -txt -rcode noerror,servfail,refused -t 250 -rl 300 -r $nameservers -wt 8 -json -o subs.dnsx.json &>/dev/null
# Extract non CDN IPs
cat subs.dnsx.json | jq '. | select(.cdn == null) | .a[]' | tr -d '"' | sort -u > IPs.live && rm subs.all subs.puredns
tput setaf 3; echo "[$(cat IPs.live | wc -l)]"
# Extract resolved subs
cat subs.dnsx.json | jq '.host ' | tr -d '"' | sort -u > subs.alive
# Check http ports with httpx
tput setaf 42; echo -n "[+] subs resolve: httpx "
httpx -l subs.alive -silent -nc -t 20 -rl 80 -o subs.httpx &>/dev/null
tput setaf 3; echo "[$(sort -u subs.httpx | wc -l)]"
# IPs to check in shodan
cat IPs.live | xargs -I {}  echo https://www.shodan.io/host/\{\} > IPs.shodan-urls
sleep 5
################################# Subdomain enumeration Ends #################################

################################# Endpoints enumeration Starts #################################
########### Passive URL Enumeration with waymore ###########
tput setaf 42; echo -n "[+] Passive URL enum: waymore "
waymore.py -i $OPTARG -mode U -ow -p 5 -lcc 45 &>/dev/null
if [ $FLAG = "t" ]; then
    mv $waymore_path/$OPTARG/waymore.txt urls.waymore
else
    cat $OPTARG | while read line; do cat $waymore_path/$line/waymore.txt >> urls.waymore; done
fi
# Clean up
tput setaf 3; echo "[$(cat urls.waymore | wc -l)]"
sleep 5

########### Endpoints enumeration with github-endpoints ###########
tput setaf 42; echo -n "[+] Endpoints enum: github-endpoints "
if [ $FLAG = "t" ]; then
    github-endpoints -d $OPTARG -o urls.github-unsort &>/dev/null
else
    cat $OPTARG | while read line; do github-endpoints -d $line -o urls-$line.github-unsort; done 
fi
Clean up
sort -u urls.waymore urls*.github-unsort > urls.passive && rm urls.github-unsort urls.waymore
tput setaf 3; echo "[$(cat urls.passive | wc -l)]"
sleep 5

########### Active URL Enumeration with gospider ###########
tput setaf 42; echo -n "[+] Active Endpoints enum: gospider "
gospider -S subs.httpx -o urls-active -d 3 -c 20 -w -r -q --js --subs --sitemap --robots --blacklist bmp,css,eot,flv,gif,htc,ico,image,img,jpeg,jpg,m4a,m4p,mov,mp3,mp4,ogv,otf,png,rtf,scss,svg,swf,tif,tiff,ttf,webm,webp,woff,woff2 &>/dev/null
if [ $FLAG = "t" ]; then
    sort -u urls-active/* | sed 's/\[.*\] - //' | grep -iE "$OPTARG" > urls.active &>/dev/null
else
    roots=$(cat $OPTARG | while read line; do echo -n "$line|"; done | sed 's/.$//')
    sort -u urls-active/* | sed 's/\[.*\] - //' | grep -iE "($roots)" > urls.active &>/dev/null
fi
tput setaf 3; echo "[$(cat urls.active | wc -l)]"
sort -u urls.passive urls.active > urls.all && rm urls.passive urls.active
sleep 5
################################# Endpoints enumeration Ends #################################

################################# JS Enumeration Starts #################################
########### JS files Enumeration ###########
# tput setaf 42; echo -n "[+] JS files enum passive & active: "
# cat subs.httpx | subjs -c 25 -ua 'Mozilla/5.0 (X11; Linux x86_64; rv:91.0) Gecko/20100101 Firefox/91.0' > urls.js-unsort
# sort -u urls.js-unsort > urls.js
# tput setaf 3; echo "[$(cat urls.js | wc -l)]"
# sleep 5
# Grep all .js urls
sort -u urls.all | grep -i ".js"  > urls.js

# Make directories to store js files and to store any keys found from them
mkdir js-files cloud-keys &>/dev/null
# Download JS Files from .js urls
cd js-files
cat ../urls.js | xargs -I {} wget {} &>/dev/null
cd ..

#################### XNLinkFinder ####################
tput setaf 42; echo -n "[+] Endpoints enumeration from JS: "
# Find urls in JS Files
xnLinkFinder.py -i js-files -o urls.linkfinder -op params.linkfinder
tput setaf 3; echo "[Done]"
###################### JS Enumeration Ends #################################

########### Grep subdomains from Endpoints ###########
tput setaf 42; echo -n "[+] subs enum: endpoints "
if [ $FLAG = "t" ]; then
    cat urls.all urls.linkfinder &>/dev/null | grep -iE "$OPTARG" | unfurl -u domains > subs.new
else
    cat urls.all urls.linkfinder &>/dev/null | grep -iE "($roots)" | unfurl -u domains > subs.new
fi
tput setaf 3; echo "[$(cat subs.new | wc -l)]"
sleep 5

######## ADD permutations?! Only do permutations on new subs - Implementation pending...
########### Probing for live domains from endpoints and js files with httpx ###########
tput setaf 42; echo -n "[+] Probing for live subdomains from new subdomains with httpx: "
# Resolve subs with puredns
cat subs.new | puredns resolve -r $nameservers -t 200 --wildcard-batch 100000 -n 5 --write subs.puredns &>/dev/null
# Get A records, CDN info with DNSx
cat subs.puredns | dnsx -silent -a -cdn -re -txt -rcode noerror,servfail,refused -t 250 -rl 300 -r $nameservers -wt 8 -json -o subs.dnsx-2.json &>/dev/null
rm subs.puredns subs.new
# Extract non CDN IPs
cat subs.dnsx-2.json | jq '. | select(.cdn == null) | .a[]' | tr -d '"' | sort -u > IPs.new
tput setaf 3; echo "[$(cat IPs.new | wc -l)]"
# Extract resolved subs
cat subs.dnsx-2.json | jq '.host ' | tr -d '"' | sort -u > subs.alive-2
# Check http ports with httpx
cat subs.alive-2 | httpx -silent -nc -t 20 -rl 50 -o subs.httpx-2 &>/dev/null
tput setaf 3; echo "[$(sort -u subs.httpx-2 | wc -l)]"
# House cleaning for resolved subs, subs with http ports and IPs
sort -u subs.httpx subs.httpx-2 > subs.httpx-final && rm subs.httpx subs.httpx-2
sort -u subs.alive subs.alive-2 > subs.txt && rm subs.alive subs.alive-2
sort IPs.live IPs.new > IPs.txt && rm IPs.live IPs.new
echo "Total valid subs: $(cat subs.txt | wc -l)" | lolcat -ia
echo "Total valid IPs: $(cat IPs.txt | wc -l)" | lolcat -ia
sleep 5

########### Subdomain takeover test with Nuclei ###########
tput setaf 42; echo "[+] subdomain takeover test: nuclei"
nuclei -t subdomain-takeover -l subs.httpx-final -o takeover-results.txt &>/dev/null
sleep 3

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
cat js-files/* &>/dev/null | gf aws-keys | sort -u >> cloud-keys/js.aws-keys &>/dev/null
cat js-files/* &>/dev/null | gf firebase | sort -u >> cloud-keys/js.firebase &>/dev/null
cat js-files/* &>/dev/null | gf s3-buckets | sort -u >>  cloud-keys/js.s3-buckets &>/dev/null
cat js-files/* &>/dev/null | gf sec | sort -u >> cloud-keys/js.sec &>/dev/null
tput setaf 3; echo "[Done]"
sleep 3

### Probing for live urls with httpx ###
tput setaf 42; echo -n "[+] Probing for live urls: httpx "
cat urls.all | qsreplace | sort -u | httpx -silent -nc -rl 100 -o urls.live >/dev/null
tput setaf 3; echo "[$(sort -u urls.live | wc -l)]"
sleep 3

################### Need More Tests ###################
### Find more params ###
tput setaf 42; echo -n "[+] Finding more params: arjun "
arjun -q -i urls.live -d 1 -oT urls.params-arjun-GET -m GET  >/dev/null && sleep 180
arjun -q -i urls.live -d 1 -oT urls.params-arjun-POST -m POST >/dev/null && sleep 180
arjun -q -i urls.live -d 1 -oT urls.params-arjun-JSON -m JSON >/dev/null && sleep 180
arjun -q -i urls.live -d 1 -oT urls.params-arjun-XML -m XML >/dev/null
tput setaf 3; echo "[$(sort -u urls.params-arjun-* | wc -l)]"
sleep 3

########### Grep endpoints, params, values, keypairs ###########
tput setaf 42; echo "[+] Greping paths, params keys, keypairs: unfurl"
cat urls.params-arjun-GET | unfurl -u paths >> paths
cat urls.params-arjun-GET | unfurl -u keys >> params
cat urls.params-arjun-GET | unfurl -u keypairs >> keypairs
sleep 3

########### Grep urls with params ###########
tput setaf 42; echo -n "[+] Greping urls with params: "
cat urls.live | grep "=" > urls.params | qsreplace FUZZ | sort -u > urls.fuzz
tput setaf 3; echo "[$(cat urls.fuzz | wc -l)]"
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

########### Nuclei ###########
tput setaf 42; echo "[+] Running Nuclei"
nuclie -l subs.txt -o nuclei.log >/dev/null

########### Automated tests on gf pattern urls ###########
mkdir automated-test && cd automated-test
tput setaf 42; echo "[+] Running Automated Tests: $(pwd)"
echo
tput setaf 42; echo "[+] Redirect Test: "

sleep 180
tput setaf 42; echo "[+] XSS Test: "
cat ../urls.fuzz | kxss | sed s'/URL: //'| qsreplace > ../urls.params-reflect
dalfox file ../urls.params-reflect -F -o xss-1.log &>/dev/null
dalfox file gf-patterns/urls.xss -F -o xss-2.log &>/dev/null
sleep 180
tput setaf 42; echo -n "[+] SQLi Test: nuclie"
nuclie

###################### Dorks Generation Starts ######################
########### Manual shodan dorks file ###########
if [ $FLAG = "t" ]; then
    cat .shodan.dorks | sed 's|${target}|$OPTARG|'  > shodan-dorks.txt
else
    cat .shodan.dorks | while read line; do sed 's|${target}|$line|'  > shodan-dorks-$line.txt
fi
sleep 3

########### Manual GitHub dorks file ###########
if [ $FLAG = "t" ]; then
    cat .github.dorks | sed 's|${target}|$OPTARG|'  > github-dorks.txt
else
    cat .github.dorks | while read line; do sed 's|${target}|$line|'  > github-dorks-$line.txt
fi
sleep 3

########### Manual Search Engine dorks file ########### TO-DO

###################### Dorks Generation Ends ######################

########### RustScan ###########
mkdir nmap
rustscan -a IPs.txt --ulimit 5000 -r 1-65535 -- -A -oA nmap/result >/dev/null

########### Cloud Enumeration ###########


########### WhatWeb Recon ###########
tput setaf 42; echo "[+] Tech stack recon: Whatweb"
whatweb -i subs-interesting.txt --log-brief=whatweb-brief >/dev/null
sleep 5