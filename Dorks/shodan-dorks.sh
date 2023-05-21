#!/bin/bash

# Check if a domain or file of domains was provided as an argument
if [ -z "$1" ]; then
    echo "Usage:"
    echo "./shodan-dorks.sh example.com .shodan-dorks.txt"
    echo "./shodan-dorks.sh domains.txt .shodan-dorks.txt"
    exit 1
fi

# Check if a file of Shodan dorks was provided as an argument
if [ -z "$2" ]; then
    echo "Usage:"
    echo "./shodan-dorks.sh example.com .shodan-dorks.txt"
    echo "./shodan-dorks.sh domains.txt .shodan-dorks.txt"
    exit 1
fi

# Read the domains or file of domains into an array
if [ -f "$1" ]; then
    domains=()
    while read -r line; do
        domains+=("$line")
    done < "$1"
else
    domains=("$1")
fi

# Read the Shodan dorks into a variable
dorks=$(<"$2")

# Loop through the domains and substitute them into the Shodan dorks
for domain in "${domains[@]}"; do
    output=$(echo "$dorks" | sed "s/\${target}/$domain/g")

    # Save the modified Shodan dorks to a file
    echo "$output" > "shodan-$domain.txt"
done
