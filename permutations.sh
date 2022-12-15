# Variables & Wordlists
nameservers=~/git/wordlists/resolvers/resolvers.txt
trustedresolvers=~/git/wordlists/resolvers/resolvers-trusted.txt
permutations=~/git/wordlists/ALL.TXTs/permutations.txt

# subdomain permutations with altdns 
tput setaf 42; echo -n "[+] subs permutations: altdns "
sort -u subs/* >> subs.1
altdns -i subs.1 -o subs.all-unsort -w $permutations -t 100
sort -u subs.all-unsort >> subs.altdns && rm subs.all-unsort
tput setaf 3; echo "[$(cat subs.altdns 2>/dev/null | wc -l)]"

# Resolving subdomains & gather IPs with dnsx
tput setaf 42; echo -n "[+] Alive subs from permutations (best to run on VPS) : "
# puredns
cat subs.altdns | puredns resolve -r $nameservers --resolvers-trusted $trustedresolvers --write-wildcards subs.wildcards --write subs.puredns &>/dev/null
# dnsx
cat subs.puredns subs.1 | dnsx -silent -a -cdn -re -txt -rcode servfail,refused -r $trustedresolvers -wt 8 -json -o subs.dnsx.json &>/dev/null

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