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

########### Make directories ###########
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

########### Figlet ###########
echo init-recon.sh | figlet -c| lolcat

########### Change directory ###########
cd ~/bug-hunting/recon/$dir
echo
echo "++++++++++++++++++ Storing data here: $(pwd) ++++++++++++++++++"| lolcat
echo

########### subdomain enumeration with findomain, subfinder, amass passive ###########
tput setaf 42; echo -n "[+] subs enum: findomain, subfinder, amass passive "
findomain -$findomain_flag $OPTARG --external-subdomains -i -q --lightweight-threads 25 -u subs.findomain-1 >/dev/null
sort -u external_subdomains/amass/*.txt external_subdomains/subfinder/*.txt > subs.findomain-external
# Resolve external-subdomains and enumerate with IPs
findomain -f subs.findomain-external -x -q -i --lightweight-threads 25 -u subs.findomain-2 >/dev/null
sort -u subs.findomain-1 subs.findomain-2 > subs.findomain_IPs
# Clean up
rm -rf external_subdomains subs.findomain-*
cat subs.findomain_IPs | cut -d "," -f 1 | sort -u > subs.findomain
tput setaf 3; echo "[$(cat subs.findomain | wc -l)]"
sleep 10

########### subdomain enumeration with amass active ###########
tput setaf 42; echo -n "[+] subs enum: amass active, altdns, bruteforce "
amass enum -$amass_flag $OPTARG -src -active -max-depth 5 -ip -brute -alts -silent -dir ./amass-active
# Clean up
cp amass-active/amass.txt subs.amass_IPs
cat amass-active/amass.json | jq .name -r | sort -u > subs.amass
tput setaf 3; echo "[$(cat subs.amass | wc -l)]"
sleep 10

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
sleep 150

########### Vhosts enumeration with gobuster ###########
# tput setaf 42; echo -n "[+] Vhosts enum: gobuster "
# if [ $FLAG = "t" ]; then
#     gobuster vhost -q -t 25 -o subs.vhosts -u $OPTARG -w /usr/share/seclists/Discovery/DNS/dns-Jhaddix.txt; >/dev/null
# else
#     cat $OPTARG | while read line; do gobuster vhost -q -t 25 -o subs-$line.vhosts -u $line -w /usr/share/seclists/Discovery/DNS/dns-Jhaddix.txt; done >/dev/null
# fi
# tput setaf 3; echo "[$(cat subs.vhosts | wc -l)]"
# sleep 300

########### Probing for live domains with httpx ###########
tput setaf 42; echo -n "[+] Probing for live github domains: httpx "
httpx -l subs.github -silent -nc -t 25 -rl 50 -o subs.github-live >/dev/null
# Clean up
tput setaf 3; echo "[$(sort -u subs.github-live | wc -l)]"
sed -i 's|^|http://|' subs.findomain
sed -i 's|^|http://|' subs.amass
sort -u subs.findomain subs.amass subs.github-live > subs.live && rm subs.findomain subs.amass subs.github 
mv subs.github-live subs.github
sleep 100

########### Endpoints enumeration with github-endpoints ###########
# tput setaf 42; echo -n "[+] Endpoints enum: github-endpoints "
# if [ $FLAG = "t" ]; then
#     github-endpoints -d $OPTARG -o urls.github-unsort 1>/dev/null
# else
#     cat $OPTARG | while read line; do github-endpoints -d $line -o urls-$line.github-unsort; done 
# fi
# Clean up
# sort -u urls*.github-unsort > urls.github && rm urls*.github-unsort
# tput setaf 3; echo "[$(cat urls.github | wc -l)]"
# sleep 30

########### Passive URL Enumeration with waybackurls,gau ###########
tput setaf 42; echo -n "[+] Passive URL enum: waybackurls "
cat subs.live | waybackurls | grep -vE ".(png|jpeg|jpg|gif|svg|css|ttf|tif|tiff|woff|woff2|ico|pdf)" > urls.wayback
tput setaf 3; echo "[$(sort -u urls.wayback | wc -l)]"
tput setaf 42; echo -n "[+] Passive URL enum: gau "
cat subs.live | gau --subs --threads 25 --fc 404,302 --o urls.gau --blacklist png,jpeg,jpg,gif,svg,css,ttf,tif,tiff,woff,woff2,ico,pdf >/dev/null
# Clean up
tput setaf 3; echo "[$(sort -u urls.gau | wc -l)]"
sort -u urls.wayback urls.gau urls.github > urls.passive && rm urls.gau urls.wayback urls.github
sleep 30

########### Active URL Enumeration with gospider ###########
tput setaf 42; echo -n "[+] Active URL enum: gospider "
gospider -S subs.live -o urls-active -d 3 -c 15 -w -r -q --js --subs --sitemap --robots --blacklist png,jpeg,jpg,gif,svg,css,ttf,tif,tiff,woff,woff2,ico,pdf >/dev/null
if [ $FLAG = "t" ]; then
    sort -u urls-active/* | sed 's/\[.*\] - //' | grep -iE "$OPTARG" > urls.active 2>/dev/null
else
    roots=$(cat $OPTARG | while read line; do echo -n "$line|"; done | sed 's/.$//')
    sort -u urls-active/* | sed 's/\[.*\] - //' | grep -iE "($roots)" > urls.active 2>/dev/null
fi
# Clean up
tput setaf 3; echo "[$(cat urls.active | wc -l)]"
sleep 60

########### Grep subdomains from passive & active urls ###########
tput setaf 42; echo -n "[+] Subs enum: passive & active urls "
sort -u urls.active urls.passive | unfurl -u domains > subs.urls
tput setaf 3; echo "[$(cat subs.urls | wc -l)]"
sleep 3

################################# JS Enumeration Starts #################################

########### JS endpoints Enumeration ###########
tput setaf 42; echo -n "[+] JS endpoints enum passive & active: "
cat subs.live | subjs -c 25 -ua 'Mozilla/5.0 (X11; Linux x86_64; rv:91.0) Gecko/20100101 Firefox/91.0' > urls.subjs
sort -u urls.passive urls.active urls.subjs | grep -i ".js" > urls.js && rm urls.subjs
sort -u urls.passive urls.active > urls.all && rm urls.passive urls.active
tput setaf 3; echo "[$(cat urls.js | wc -l)]"
sleep 3

########### Grep secrets from JS files ###########
tput setaf 42; echo -n "[+] Finding secrets from JS (maybe false positive): "
mkdir js-files secrets 2>/dev/null
cat urls.js | xargs -I {} linkfinder.py -i {} -o cli  2>/dev/null | sort -u > urls.linkfinder 2>/dev/null
cd js-files
cat ../urls.js | xargs -I {} wget {} 2>/dev/null
cd ..
cat js-files/* 2>/dev/null | gf aws-keys > secrets/js.aws-keys 2>/dev/null
cat js-files/* 2>/dev/null | gf firebase > secrets/js.firebase 2>/dev/null
cat js-files/* 2>/dev/null | gf s3-buckets >  secrets/js.s3-buckets 2>/dev/null
cat js-files/* 2>/dev/null | gf sec > secrets/js.sec 2>/dev/null
tput setaf 3; echo "[$(cat secrets/* 2>/dev/null | wc -l)]"
sleep 3

########### Grep subdomains from JS files ###########
tput setaf 42; echo -n "[+] subs enum: js files "
if [ $FLAG = "t" ]; then
    cat js-files/* 2>/dev/null | gf urls | grep -iE "$OPTARG" | unfurl -u domains > subs.js
else
    cat js-files/* 2>/dev/null | gf urls | grep -iE "($roots)" | unfurl -u domains > subs.js
fi
tput setaf 3; echo "[$(cat subs.js | wc -l)]"
sleep 3

###################### JS Enumeration Ends #################################

########### Probing for live domains from urls & JS files with httpx ###########
tput setaf 42; echo -n "[+] Probing for live domains from JS files & links: httpx "
sort -u subs.urls subs.js | httpx -silent -nc -t 25 -rl 50 -o subs.live-new >/dev/null && rm subs.js subs.urls
tput setaf 3; echo "[$(cat subs.live-new | wc -l)]"
sort -u subs.live subs.live-new > subs.final && rm subs.live subs.live-new
sleep 300

########### Subdomain takeover test with NtHiM ###########
tput setaf 42; echo "[+] subdomain takeover test: NtHiM"
NtHiM -u >/dev/null
NtHiM -f subs.final -c 25 -o subs.takeover  2>/dev/null
sleep 5

########### WhatWeb Recon ###########
tput setaf 42; echo "[+] Tech stack recon: Whatweb"
whatweb -i subs.final --log-brief=whatweb-brief >/dev/null

################################# Greping Values Starts #################################

########### Grep secrets from urls ###########
tput setaf 42; echo -n "[+] Finding secrets from urls (maybe false positive): "
cat urls.all | gf aws-keys > secrets/urls.aws-keys
cat urls.all | gf firebase > secrets/urls.firebase
cat urls.all | gf s3-buckets > secrets/urls.s3-buckets
cat urls.all | gf sec > secrets/urls.sec
tput setaf 3; echo "[$(cat secrets/urls.* | wc -l)]"
sleep 3

########### Probing for live urls with httpx ###########
tput setaf 42; echo -n "[+] Probing for live urls: httpx "
cat urls.all | qsreplace | sort -u | httpx -silent -nc -rl 100 -o urls.live >/dev/null
tput setaf 3; echo "[$(cat urls.live | wc -l)]"
sleep 3

########### Find more params ###########
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
cat urls.live | grep "=" > urls.params | qsreplace FUZZ > urls.params-raw
sort -u urls.params-raw > urls.params-fuzz
tput setaf 3; echo "[$(cat urls.params-fuzz | wc -l)]"
sleep 3

########### Replace params values as FUZZ with qsreplace ###########
tput setaf 42; echo "[+] Gf patterning urls: gf"
mkdir gf-patterns && cd gf-patterns
cat ../urls.params-fuzz | gf xss > urls.xss
cat ../urls.params-fuzz | gf ssrf > urls.ssrf
cat ../urls.params-fuzz | grep -i "=\/" > urls.take-paths
cat ../urls.params-fuzz | gf redirect > urls.redirect
cat ../urls.params-fuzz | gf rce > urls.rce
cat ../urls.params-fuzz | gf interestingparams > urls.interestingparams
cat ../urls.params-fuzz | gf http-auth > urls.http-auth
cat ../urls.params-fuzz | gf upload-fields > urls. upload-fields
cat ../urls.params-fuzz | gf img-traversal > urls.img-traversal
cat ../urls.params-fuzz | gf lfi > urls.lfi
cat ../urls.params-fuzz | gf ip > urls.ip
cat ../urls.params-fuzz | gf ssti > urls.ssti
cat ../urls.params-fuzz | gf idor > urls.idor
cat ../urls.params-fuzz | gf base64 > urls.base64
cat ../urls.params-fuzz | gf sqli > urls.sqli
cd ..
sleep 3

###################### Greping Values Ends ######################

########### Automated tests ###########
mkdir automated-test && cd automated-test
tput setaf 42; echo "[+] Running Automated Test: ./automated-test"
echo
tput setaf 42; echo "[+] Redirect Test: "
cat ../gf-patterns/urls.redirect | qsreplace 'http://evil.com'| while read host do; curl -s -L $host -I 
| grep "evil.com" && echo "$host Vulnerable"; done | tee vulnerable.redirect
sleep 180
tput setaf 42; echo "[+] XSS Test: "
cat ../urls.params-fuzz | kxss | sed s'/URL: //'| qsreplace > ../urls.params-reflect
dalfox file ../urls.params-reflect -F -o vulnerable.xss
sleep 180
tput setaf 42; echo -n "[+] SQLi Test: nuclie"
nuclie

###################### Dorks Generation Starts ######################

########### Manual shodan dorks file ###########
if [ $FLAG = "t" ]; then
    cat .shodan.dorks | sed 's|${target}|$OPTARG|'  > Shodan-dorks.manual
else
    cat .shodan.dorks | while read line; do sed 's|${target}|$line|'  > Shodan-dorks-$line.manual
fi
sleep 3

########### Manual GitHub dorks file ###########
if [ $FLAG = "t" ]; then
    cat .shodan.dorks | sed 's|${target}|$OPTARG|'  > Shodan-dorks.manual
else
    cat .shodan.dorks | while read line; do sed 's|${target}|$line|'  > Shodan-dorks-$line.manual
fi
sleep 3

###################### Dorks Generation Ends ######################