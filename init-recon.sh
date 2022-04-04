#! /usr/bin/bash

usage() 
{ 
    echo "Usage: init-recon [-t <target>] (or) [-f <file>]"
    echo "Example: init-recon -t tesla.com"
    echo "Example: init-recon -f root_domains.txt"
    exit 1
}

######################## command line Arguments ########################
getopts t:f:h FLAG;
case $FLAG in
    t) t=$OPTARG;;
    f) f=$OPTARG;;
    *|h) usage;;
esac

######################## Setting flags for file or domain | reduces code ########################
if [ $FLAG = "t" ]; then
    dir=$t
    findomain_flag=t
    subfinder_flag=d
    amass_flag=d
else
    dir=$(echo $f | cut -d "." -f 1)
    findomain_flag=f
    subfinder_flag=dL
    amass_flag=df
fi

######################## Make directories ########################
if [ ! -d ~/bug-bounty ];then
    mkdir ~/bug-bounty
fi
if [ ! -d ~/bug-bounty/recon ];then
    mkdir ~/bug-bounty/recon
fi
if [ ! -d ~/bug-bounty/recon/$dir ];then
    mkdir ~/bug-bounty/recon/$dir
fi
if [ ! -d ~/bug-bounty/recon/$dir/findomain-subs ];then
    mkdir ~/bug-bounty/recon/$dir/findomain-subs
fi

######################## Copy root domains file ########################
if [ $FLAG = "f" ]; then
    cp $OPTARG ~/bug-bounty/recon/$dir
    cp $OPTARG ~/bug-bounty/recon/$dir/findomain-subs;
fi

######################## Change directory ########################
cd ~/bug-bounty/recon/$dir
echo
tput setaf 42; echo "----------- Storing data here: $(pwd)-----------";tput setaf 7
echo;echo

######################## subdomain enumeration with findomain ########################
cd findomain-subs
tput setaf 42; echo "[+] subs enum -------> findomain";tput setaf 7
echo;tput setaf 3;echo "findomain-linux -$findomain_flag $OPTARG -q -r -o";tput setaf 7
findomain-linux -$findomain_flag $OPTARG -q -r -o
sort -u *.txt | tee subs.findomain
cd .. && cp findomain-subs/subs.findomain . && rm -rf findomain-subs
echo;echo
sleep 0.5

######################## subdomain enumeration with subfinder ########################
tput setaf 42; echo "[+] subs enum -------> subfinder";tput setaf 7
echo;tput setaf 3;echo "subfinder -$subfinder_flag $OPTARG -silent -o subs.subfinder";tput setaf 7
subfinder -$subfinder_flag $OPTARG -silent -o subs.subfinder
sleep 0.5

######################## subdomain enumeration with amass ########################
echo
tput setaf 42; echo "[+] subs enum -------> Amass";tput setaf 7
echo;tput setaf 3;echo "amass enum -active -$amass_flag $OPTARG -silent -dir amass-results";tput setaf 7
amass enum -active -$amass_flag $OPTARG -silent -dir ./amass-results
cp amass-results/amass.txt .
sleep 0.5

######################## Sorting subs to single file & removing redundant ########################
sort -u subs.subfinder subs.findomain amass.txt | tee subs.final
rm subs.findomain subs.subfinder amass.txt

######################## Probing for live domains with httpx ########################
tput setaf 42; echo "[+] Probing for live domains -------> httpx"; tput setaf 7
echo;tput setaf 3;echo "httpx -l subs.final -silent -nc -o subs.live"
httpx -l subs.final -silent -nc -o subs.live
rm subs.final
sleep 0.5

######################## Subdomain takeover test with subzy ########################
tput setaf 42; echo "[+] subdomain takeover test -------> subzy"; tput setaf 7
echo;tput setaf 3;echo "subzy -targets subs.live -hide_fails -concurrency 20"; tput setaf 7
subzy -targets subs.live -hide_fails -concurrency 20
sleep 0.5

######################## Screenshoting with aquatone ########################
echo
mkdir aquatone; cd aquatone;
tput setaf 42; echo "[+] screenshot -------> Aquatone"; tput setaf 7
echo;tput setaf 3;echo "cat subs.live | aquatone"; tput setaf 7
cat ../subs.live | aquatone 2>/dev/null
cd ../
sleep 0.5

######################## URL Enumeration with waybackurls & gau ########################
echo
tput setaf 42; echo "[+] URL Enumeration -------> waybackurls & gau"; tput setaf 7
tput setaf 3
echo 'cat subs.live | waybackurls | grep -vE ".(png|jpeg|jpg|gif|svg|css|ttf|tif|tiff|woff|woff2|ico|pdf)"| tee urls.waybackurls'
tput setaf 7
cat subs.live | waybackurls | grep -vE ".(png|jpeg|jpg|gif|svg|css|ttf|tif|tiff|woff|woff2|ico|pdf)" | tee urls.waybackurls
tput setaf 3;echo "cat subs.live | gau --o urls.gau"; tput setaf 7
cat subs.live | gau --o urls.gau
sort -u urls.waybackurls urls.gau | tee urls.all
rm urls.gau urls.waybackurls
sleep 0.5

######################## Probing for live urls with httpx ########################
echo
tput setaf 42; echo "[+] Probing for live urls -------> httpx"; tput setaf 7
echo;tput setaf 3;echo "httpx -l urls.all -nc -o urls.live"; tput setaf 7
httpx -l urls.all -silent -nc -o urls.live
rm urls.all
sleep 0.5

######################## Grep only urls with params ########################
echo
tput setaf 42; echo "[+] Greping for urls with params -------> grep"; tput setaf 7
tput setaf 3;echo 'sort -u urls.live | grep "=" | tee urls.params'; tput setaf 7
sort -u urls.live | grep "=" | tee urls.params
sleep 0.5

######################## Remove params values with qsreplace ########################
echo
tput setaf 42; echo "[+] Remove params values -------> qsreplace"; tput setaf 7
echo;tput setaf 3;echo 'cat urls.params | qsreplace | tee urls.params'; tput setaf 7
cat urls.params | qsreplace | tee urls.params
sleep 0.5

######################## Replace params value as FUZZ with qsreplace ########################
echo
tput setaf 42; echo "[+] Replacing params value as FUZZ -------> qsreplace"; tput setaf 7
echo;tput setaf 3;echo 'cat urls.params | qsreplace FUZZ | tee urls.fuzz'; tput setaf 7
cat urls.params | qsreplace FUZZ | tee urls.fuzz
sleep 0.5

######################## Test for reflective values with kxss ########################
echo
tput setaf 42; echo "[+] Test for reflective values -------> kxss"; tput setaf 7
echo;tput setaf 3;echo "cat urls.params | kxss | sed s'/URL: //'| qsreplace | tee urls.kxss"; tput setaf 7
cat urls.params | kxss | sed s'/URL: //'| qsreplace | tee urls.kxss
sleep 0.5

######################## XSS Test with dalfox ########################
echo
tput setaf 42; echo "[+] XSS Test -------> dalfox"; tput setaf 7
echo;tput setaf 3;echo "dalfox file urls.kxss -o urls_XSS.dalfox"; tput setaf 7
dalfox file urls.params -o urls_XSS.dalfox
sleep 5

######################## Screenshoting with gowitness ########################
echo
mkdir gowitness; cd gowitness;
tput setaf 42; echo "[+] screenshot -------> gowitness"; tput setaf 7
echo;tput setaf 3;echo "gowitness file -f ../subs.live -t 20"; tput setaf 7
gowitness file -f ../subs.live -t 20
cd ..
sleep 0.5

######################## LFI Test with ffuf ########################
# echo;echo
# tput setaf 42; echo "[+] LFI Test -------> ffuf"; tput setaf 7
# echo;echo
# cat urls.params | xargs -I {} ffuf -w wordlist {}  -fc 404, 500 -o urls_LFI.ffuf
# sleep 0.5

######################## Open Redirect Test with ffuf ########################
# echo;echo
# tput setaf 42; echo "[+] Open Redirect Test -------> ffuf"; tput setaf 7
# echo;echo
# cat urls.params | xargs -I {} ffuf -w wordlist {}  -fc 404, 500 -o urls_OpenRedirect.ffuf
# sleep 0.5

######################## Port Analysis ########################
# echo;echo
# tput setaf 42; echo "[+] Port Scan -------> naabu with nmap service enumeration"; tput setaf 7
# echo;echo
# naabu -l subs.live -tp 150 -sa -rate 10000 -json -nmap-cli 'sudo nmap -sS -sV' -no-color -silent
# sleep 0.5

######################## WAF Detection ########################
# cat subs.live | xargs -I {} wafw00f -a {}
# cat subs.live | xargs -I {} nmap {} --script=http-waf-fingerprint -p80,443
# sleep 0.5


