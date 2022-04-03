#! /usr/bin/bash

usage() 
{ 
    echo "Usage: init-recon [-t <target>] (or) [-f <file>]"
    echo "Example: init-recon -t google.com"
    echo "Example: init-recon -f domains.txt"
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
if [ ! -d ~/bug-bounty/$dir ];then
    mkdir ~/bug-bounty/$dir
fi
if [ ! -d ~/bug-bounty/$dir/recon ];then
    mkdir ~/bug-bounty/$dir/recon
fi

######################## Copy root domains file ########################
if [ $FLAG = "f" ]; then
    cp $OPTARG ~/bug-bounty/$dir/recon/
fi

######################## Change directory ########################
cd ~/bug-bounty/$dir/recon
tput setaf 42; echo "----------- changed directory to $(pwd)-----------";tput setaf 7
echo;echo;echo;

######################## subdomain enumeration with findomain ########################
mkdir findomain-subs; cd findomain-subs;
tput setaf 42; echo "[+] subs enum -------> findomain";tput setaf 7
findomain-linux -$findomain_flag $OPTARG -q -r -o
sort -u *.txt | tee subs.findomain
cp subs.findomain ..;cd ..;rm -rf findomain-subs
echo;echo
sleep 0.5

######################## subdomain enumeration with subfinder ########################
tput setaf 42; echo "[+] subs enum -------> subfinder";tput setaf 7
echo;echo
subfinder -$subfinder_flag $OPTARG -silent -o subs.subfinder
sleep 0.5

######################## subdomain enumeration with amass ########################
echo;echo
tput setaf 42; echo "[+] subs enum -------> Amass";tput setaf 7
echo;echo
amass enum -$amass_flag $OPTARG -silent -dir .
sleep 0.5

######################## Sorting subs to single file & removing redundant ########################
sort -u subs.subfinder subs.findomain | tee subs.final
rm subs.findomain subs.subfinder

######################## Probing for live domains with httpx ########################
echo;echo
tput setaf 42; echo "[+] Probing for live domains -------> httpx"; tput setaf 7
echo;echo
httpx -l subs.final -silent -nc | awk -F "http(|s)://" {'print $2'} | cut  -d "/" -f 1 | tee subs.live
sleep 0.5

######################## Subdomain takeover test with subzy ########################
echo;echo
tput setaf 42; echo "[+] subdomain takeover test -------> subzy"; tput setaf 7
echo;echo
subzy -targets subs.live -hide_fails
sleep 0.5

######################## Screenshoting with aquatone ########################
echo;echo
mkdir aquatone; cd aquatone;
tput setaf 42; echo "[+] screenshot -------> Aquatone"; tput setaf 7
echo;echo
cat ../subs.live | aquatone
cd ..
sleep 0.5

######################## Screenshoting with gowitness ########################
echo;echo
mkdir gowitness; cd gowitness;
tput setaf 42; echo "[+] screenshot -------> gowitness"; tput setaf 7
echo;echo
gowitness file ../subs.live
cd ..
sleep 0.5

######################## URL Enumeration with waybackurls & gau ########################
echo;echo
mkdir gowitness; cd gowitness;
tput setaf 42; echo "[+] URL Enumeration -------> waybackurls & gau"; tput setaf 7
cat subs.live | waybackurls | tee urls.waybackurls
cat subs.live | gau | tee urls.gau
sort -u urls.waybackurls urls.gau | urls.live
rm urls.gau urls.waybackurls
sleep 0.5

######################## Probing for live urls with httpx ########################
echo;echo
tput setaf 42; echo "[+] Probing for live urls -------> httpx"; tput setaf 7
echo;echo
httpx -l subs.live -silent -nc -o urls.live
sleep 0.5

######################## Grep only urls with params ########################
echo;echo
tput setaf 42; echo "[+] Greping for urls with params -------> grep"; tput setaf 7
echo;echo
cat urls.live | grep "=" | tee urls.params
sleep 0.5

######################## Remove params values with qsreplace ########################
echo;echo
tput setaf 42; echo "[+] Remove params values -------> qsreplace"; tput setaf 7
echo;echo
cat urls.params | qsreplace | tee urls.params
sleep 0.5

######################## Replace params value as FUZZ with qsreplace ########################
echo;echo
tput setaf 42; echo "[+] Replacing params value as FUZZ -------> qsreplace"; tput setaf 7
echo;echo
cat urls.params | qsreplace FUZZ | tee urls.fuzz 
sleep 0.5

######################## Test for reflective values with kxss ########################
echo;echo
tput setaf 42; echo "[+] Test for reflective values -------> kxss"; tput setaf 7
echo;echo
cat urls.params | kxss | tee urls.kxss | qsreplace
sleep 0.5

######################## XSS Test with dalfox ########################
echo;echo
tput setaf 42; echo "[+] XSS Test -------> dalfox"; tput setaf 7
echo;echo
dalfox file urls.kxss -o urls_XSS.dalfox
sleep 0.5

######################## LFI Test with ffuf ########################
echo;echo
tput setaf 42; echo "[+] LFI Test -------> ffuf"; tput setaf 7
echo;echo
cat urls.params | xargs -I {} ffuf -w wordlist {}  -fc 404, 500 -o urls_LFI.ffuf
sleep 0.5

######################## Open Redirect Test with ffuf ########################
echo;echo
tput setaf 42; echo "[+] LFI Test -------> ffuf"; tput setaf 7
echo;echo
cat urls.params | xargs -I {} ffuf -w wordlist {}  -fc 404, 500 -o urls_OpenRedirect.ffuf
sleep 0.5

######################## Port Analysis ########################
echo;echo
tput setaf 42; echo "[+] Port Scan -------> naabu with nmap service enumeration"; tput setaf 7
echo;echo
naabu -l subs.live -tp 150 -sa -rate 10000 -json -nmap-cli 'sudo nmap -sS -sV' -no-color -silent
sleep 0.5

######################## WAF Detection ########################
cat subs.live | xargs -I {} wafw00f -a {}
cat subs.live | xargs -I {} nmap {} --script=http-waf-fingerprint -p80,443
sleep 0.5


