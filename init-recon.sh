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
cp subs.findomain ..;cd ..
echo;echo
sleep 1

######################## subdomain enumeration with subfinder ########################
tput setaf 42; echo "[+] subs enum -------> subfinder";tput setaf 7
echo;echo
subfinder -$subfinder_flag $OPTARG -silent -o subs.subfinder
sleep 1

######################## subdomain enumeration with amass ########################
echo;echo
tput setaf 42; echo "[+] subs enum -------> Amass";tput setaf 7
echo;echo
amass enum -$amass_flag $OPTARG -silent -no-color -dir .
sleep 1

######################## Sorting subs to single file ########################
echo;echo
tput setaf 42; echo "[+] sorting -------> subs.final";tput setaf 7
echo;echo
sort -u subs.subfinder subs.findomain | tee subs.final

######################## Probing for live domains with httpx ########################
echo;echo
tput setaf 42; echo "[+] Probing for live domains -------> httpx"; tput setaf 7
echo;echo
cat subs.final | httpx -silent | awk -F "http(|s)://" {'print $2'} | cut  -d "/" -f 1 | tee subs.live
sleep 1

######################## Subdomain takeover test with subzy ########################
echo;echo
tput setaf 42; echo "[+] subdomain takeover test -------> subzy"; tput setaf 7
echo;echo
subzy -targets subs.live -hide_fails
sleep 1

######################## Screenshoting with aquatone ########################
echo;echo
mkdir aquatone; cd aquatone;
tput setaf 42; echo "[+] screenshot -------> Aquatone"; tput setaf 7
echo;echo
cat ../subs.live | aquatone
cd ..
sleep 1

######################## Screenshoting with gowitness ########################
echo;echo
mkdir gowitness; cd gowitness;
tput setaf 42; echo "[+] screenshot -------> gowitness"; tput setaf 7
echo;echo
gowitness file ../subs.live
cd ..
sleep 1

######################## Port Analysis ########################
masscan

######################## WAF Detection ########################
if [ $FLAG = "t" ]; then
    ip=$(host $OPTARG | grep $OPTARG -m 1 | awk -F "$OPTARG has address " {'print $2'})
    wafwoof $ip
    echo;echo;echo;
    nmap $ip --script=http-waf-fingerprint -p80,443
fi
