#! /usr/bin/bash

usage() 
{ 
    echo "Usage: init-recon [-t <target>] (or) [-f <file>]"
    echo "Example: init-recon -t google.com"
    echo "Example: init-recon -f domains.txt"
    exit 1
}

# command line Arguments
getopts t:f:h FLAG;
case $FLAG in
    t) t=$OPTARG;;
    f) f=$OPTARG;;
    *|h) usage;;
esac

# Setting flags for file or domain | reduces code
if [ $FLAG = "t" ]; then
    dir=$t
    findomain_flag=t
    subfinder_flag=d
else
    dir=$(echo $f | cut -d "." -f 1)
    findomain_flag=f
    subfinder_flag=dL
fi

# Make directories
if [ ! -d ~/bug-bounty ];then
    mkdir ~/bug-bounty
fi
if [ ! -d ~/bug-bounty/$dir ];then
    mkdir ~/bug-bounty/$dir
fi
if [ ! -d ~/bug-bounty/$dir/recon ];then
    mkdir ~/bug-bounty/$dir/recon
fi

# Copy scope file
if [ $FLAG = "f" ]; then
    cp $OPTARG ~/bug-bounty/$dir/recon/
fi

# Change directory
cd ~/bug-bounty/$dir/recon
tput setaf 42; echo "----------- changed directory -----------";tput setaf 7
echo
tput setaf 1; echo "------- all .txt files will be deleted in ~/bug-bounty/$dir/recon ------";tput setaf 7
echo "Cancel if not intented"
sleep 1

# subdomain enumeration with findomain and subfinder
findomain-linux -$findomain_flag $OPTARG -r -o
echo
echo
sleep 1
tput setaf 42; echo "[+] subs enum -------> subfinder";tput setaf 7
echo
echo
subfinder -$subfinder_flag $OPTARG -silent -o subfinder.txt

sleep 1
echo
tput setaf 42; echo "[+] sorting -------> subs.final";tput setaf 7
echo
echo
sort -u *.txt | tee subs.final
sleep 1

# clean up
rm *.txt

# Probing for live domains with httpx
echo
echo
tput setaf 42; echo "[+] Probing for live domains -------> httpx"; tput setaf 7
cat subs.final | httpx | awk -F "http(|s)://" {'print $2'} | cut  -d "/" -f 1 | tee subs.live
sleep 1

# Subdomain takeover test with subzy
echo
echo
tput setaf 42; echo "[+] subdomain takeover test -------> subzy"; tput setaf 7
subzy -targets subs.live -hide_fails
sleep 1

# Screenshoting with aquatone
echo
echo
tput setaf 42; echo "[+] screenshot -------> Aquatone"; tput setaf 7
echo
cat subs.live | aquatone
