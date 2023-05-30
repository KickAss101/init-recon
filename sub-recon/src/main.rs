use std::process::{Command, Stdio};
use std::env;
use std::fs;
use std::fs::File;
use std::io::{self, BufRead, BufReader, Write};
use std::sync::Arc;
use std::time::Duration;
use std::thread;
use std::process;
use serde_json::Value;
use rayon::prelude::*;

fn main() {
    // Read the domain from command-line arguments
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        println!("Usage: {} <domain>", args[0]);
        return;
    }
    let domain = Arc::new(args[1].to_owned());

    // Variables & Wordlists
    let nameservers = "~/git/wordlists/resolvers/resolvers.txt";
    let trusted_resolvers = "~/git/wordlists/resolvers/resolvers-trusted.txt";
    let permutations = "~/git/wordlists/ALL.TXTs/permutations.txt";
    let blacklist = "bmp,css,eot,flv,gif,htc,ico,image,img,jpeg,jpg,m4a,m4p,mov,mp3,mp4,ogv,otf,png,rtf,scss,svg,swf,tif,tiff,ttf,webm,webp,woff,woff2";
    let dns_wordlist = "~/git/wordlists/ALL.TXTs/best-dns-wordlist.txt";
    let httpx_command = "httpx-pd";
    let ports_file = "/usr/share/seclists/Discovery/Infrastructure/nmap-ports-top1000.txt";

    // Extract the directory name from the domain
    let dir = domain.split('.').next().unwrap_or("");

    // Create the output directories
    let bug_hunting_dir = format!("{}/bug-hunting", env::var("HOME").unwrap());
    let recon_dir = format!("{}/recon", bug_hunting_dir);
    let output_dir = format!("{}/{}", recon_dir, dir);

    if let Err(err) = fs::create_dir_all(&output_dir) {
        eprintln!("Failed to create directories: {}", err);
        return;
    }

    // Change the current working directory
    if let Err(err) = env::set_current_dir(&output_dir) {
        eprintln!("Failed to change directory: {}", err);
        return;
    }

    // Create directories
    fs::create_dir("subs").unwrap_or_else(|_| {});
    fs::create_dir("urls").unwrap_or_else(|_| {});
    fs::create_dir("port-analysis").unwrap_or_else(|_| {});

    //// Subdomain enumeration Starts //////
    // subdomain enum with amass
    let amass_domain = Arc::clone(&domain);
    let amass_thread = thread::spawn(move|| {
        println!("Running amass ...");
        Command::new("amass")
            .args(&["enum", "-d", &amass_domain, "-src", "-passive", "-nocolor", "-active", "-max-depth", "5", "-o", "subs/amass.txt"])
            .output()
            .expect("Failed to execute amass");
        println!("amass Done");
    });

    // subdomain enum with findomain
    let findomain_domain = Arc::clone(&domain);
    let findomain_thread = thread::spawn(move || {
        println!("Running findomain ...");
        Command::new("findomain")
            .args(&["-t", &findomain_domain, "-q", "--lightweight-threads", "25", "-u", "subs/subs.findomain"])
            .output()
            .expect("Failed to execute findomain");
        println!("findomain Done");
    });

    // subdomain enum with subfinder
    let subfinder_domain = Arc::clone(&domain);
    let subfinder_thread = thread::spawn(move || {
        println!("Running subfinder ...");
        Command::new("subfinder")
            .args(&["-d", &subfinder_domain, "-silent", "-t", "25", "-o", "subs/subs.subfinder"])
            .output()
            .expect("Failed to execute subfinder");
        println!("subfinder Done");
    });

    // subdomain enum with github-subdomains
    let github_subdomains_domain = Arc::clone(&domain);
    let github_subdomains_thread = thread::spawn(move|| {
        println!("Running github_subdomains ...");
        Command::new("github-subdomains")
            .args(&["-d", &github_subdomains_domain, "-o", "subs/subs.github"])
            .output()
            .expect("Failed to execute github-subdomains");
        println!("github_subdomains Done");
    });

    // Wait for all threads to finish
    amass_thread.join().expect("Failed to join amass_thread");
    findomain_thread.join().expect("Failed to join findomain_thread");
    subfinder_thread.join().expect("Failed to join subfinder_thread");
    github_subdomains_thread.join().expect("Failed to join github_subdomains_thread");

    // Clean amass.txt
    Command::new("bash")
        .args(&["-c","cat subs/amass.txt | cut -d ] -f 2 | tr -d ' ' > subs/subs.amass"])
        .output()
        .expect("Failed to clean subs/amass.txt");

    // Sort the subs
    Command::new("bash")
        .args(&["-c","sort -u subs/subs.* >> subs/subs.1"])
        .output()
        .expect("Failed to sort subs");
    
    // Altdns
    println!("Running altdns ...");
    Command::new("bash")
        .arg("-c")
        .arg(format!("altdns -i subs/subs.1 -o subs/subs.altdns -w {} -t 1000", permutations))
        .output()
        .expect("Failed to execute altdns");
    
    // puredns command args
    let resolve_command = format!("puredns resolve subs/subs.altdns -t 300 -r {} --resolvers-trusted {} --write-wildcards subs/subs.wildcards --write subs/subs.resolve -q",nameservers, trusted_resolvers);
    let bruteforce_command = format!("puredns bruteforce {} {} -t 300 -w subs/subs.brute --rate-limit-trusted 100 -r {} --resolvers-trusted {} -q", dns_wordlist, domain, nameservers, trusted_resolvers);

    // Run brute force if only -brute is specified
    if args.contains(&String::from("-brute")) {
        // Puredns resolve
        let resolve_thread = thread::spawn(move || {
            println!("Running puredns to resolve ...");
            run_puredns(&resolve_command);
        });
        // Puredns brute-force
        let bruteforce_thread = thread::spawn(move || {
            println!("Running puredns to bruteforce ...");
            run_puredns(&bruteforce_command);
        });
        resolve_thread.join().expect("Failed to join resolve_thread");
        bruteforce_thread.join().expect("Failed to join bruteforce_thread");
    } else {
        // Puredns resolve
        let resolve_thread = thread::spawn(move || {
            println!("Running puredns to resolve ...");
            run_puredns(&resolve_command);
        });
        resolve_thread.join().expect("Failed to join resolve_thread");
    }

    // Sort the subs
    Command::new("bash")
    .args(&["-c","sort -u subs/subs.brute subs/subs.resolve >> subs/subs.puredns"])
    .output()
    .expect("Failed to sort subs");

    // DNSx
    println!("Running dnsx ...");
    let dnsx_command = Command::new("bash")
        .arg("-c")
        .arg(format!(
            "dnsx -l subs/subs.puredns -silent -a -cname -ns -srv -cdn -re -txt -r {} -t 75 -wt 10 -json -o subs/subs.dnsx.json",
            trusted_resolvers
        ))
        .output()
        .expect("Failed to execute dnsx");
    
    if dnsx_command.status.success() {
        println!("dnsx Done");

        // Copy live subs from dnsx output
        Command::new("bash")
            .arg("-c")
            .arg("cat subs/subs.dnsx.json | jq '.host ' | tr -d '\"' | sort -u >> subs/subs.live")
            .output()
            .expect("Failed to copy live subs from dnsx o/p");

        // Copy Non CDN IPs from dnsx output
        Command::new("bash")
            .arg("-c")
            .arg("cat subs/subs.dnsx.json | jq '. | select(.cdn == null) | .a[]' 2>/dev/null | tr -d '\"' | sort -u >> IPs.live")
            .output()
            .expect("Failed to copy Non CDN IPs from dnsx o/p");
    } else {
        eprintln!(
            "dnsx failed with error: {}",
            String::from_utf8_lossy(&dnsx_command.stderr)
        );
    }

    // Sleep for 5s
    thread::sleep(Duration::from_secs(5));

    // Httpx probing
    println!("Running httpx ...");
    let httpx_status = Command::new(&httpx_command)
        .args(&["-l", "subs/subs.live", "-server", "-method", "-cname", "-ip", "-title", "-sc", "-silent", "-delay", "25ms" , "-x", "all", "-rl", "30", "-o", "subs.httpx"])
        .output()
        .expect("Failed to execute httpx");
    
    if httpx_status.status.success() {
        println!("httpx Done");

        // clean httpx o/p
        Command::new("bash")
        .arg("-c")
        .arg("cat subs.httpx | cut -d '[' -f 1 | sort -u > urls/httpx.urls")
        .output()
        .expect("Failed to clean httpx o/p");
    } else {
        eprintln!(
            "httpx failed with error: {}",
            String::from_utf8_lossy(&httpx_status.stderr)
        );
    }

    println!("\n+++++ Subdomain Enumeration Done +++++\n");
    ////// Subdomain Enumeration Ends //////

    ////// Endpoint Enumeration Starts //////
    // gau (passive)
    let gau_domain = Arc::clone(&domain);
    let gau_thread = Box::new(|| {
        println!("Running gau ...");
        Command::new("gau")
            .args(&[&gau_domain, "--subs", "--threads", "25", "--o", "urls.gau", "--providers","wayback,commoncrawl,otx,urlscan,gau", "--from", "201701", "--blacklist", blacklist])
            .output()
            .expect("Failed to execute gau");
    });

    // github_endpoints (passive)
    let github_endpoints_domain = Arc::clone(&domain);
    let github_endpoints_thread = Box::new(|| {
        println!("Running github-endpoints ...");
        Command::new("github-endpoints")
            .args(&["-d", &github_endpoints_domain, "-o", "urls.github-unsort"])
            .output()
            .expect("Failed to execute github-endpoints");
    });

    // katana (active)
    let katana_thread = Box::new(|| {
        println!("Running katana ...");
        Command::new("bash")
            .arg("-c")
            .arg(format!("katana -list urls/httpx.urls -o urls/urls.katana -d 5 -rl 8 -rd 1 -jc -retry 2 -kf all -r {}", trusted_resolvers))
            .output()
            .expect("Failed to execute katana");
    });

    let threads: Vec<Box<dyn FnOnce() + Send>> = vec![gau_thread, github_endpoints_thread, katana_thread];

    threads.into_par_iter().for_each(|thread| {
        thread();
    });
    println!("\n+++++ Endpoint Enumeration Done +++++\n");
    ////// Endpoint Enumeration Ends //////

    ////// JS Enumeration Starts //////


    ////// Naabe & Nuclei //////
    // Find ports on subs
    let subs_thread = thread::spawn(|| {
        Command::new("naabu")
            .args(&["-list", "subs/subs.live", "-ports-file", ports_file, "-rate", "1000", "-o", "port-analysis/subs.naabu"])
            .output()
            .expect("Failed to execute naabu command for subs");
    });

    // Find ports on IPs
    let ips_thread = thread::spawn(|| {
        Command::new("naabu")
            .args(&["-list", "IPs.live", "-ports-file", ports_file, "-rate", "1000", "-o", "port-analysis/IPs.naabu"])
            .output()
            .expect("Failed to execute naabu command for IPs");
    });

    subs_thread.join().expect("Failed to join subs_thread");
    ips_thread.join().expect("Failed to join ips_thread");

    // Run nuclei on subs
    let subs_nuclei_thread = thread::spawn(|| {
        Command::new("nuclei")
            .args(&["-l", "port-analysis/subs.naabu", "-fr", "-es", "info", "-o", "subs.nuclei"])
            .output()
            .expect("Failed to execute nuclei command for subs");
    });

    // Run nuclei on IPs
    let ips_nuclei_thread = thread::spawn(|| {
        Command::new("nuclei")
            .args(&["-l", "port-analysis/IPs.naabu", "-fr", "-es", "info", "-o", "IPs.nuclei"])
            .output()
            .expect("Failed to execute nuclei command for IPs");
    });

    subs_nuclei_thread.join().expect("Failed to join subs_nuclei_thread");
    ips_nuclei_thread.join().expect("Failed to join ips_nuclei_thread");
}

// puredns function
fn run_puredns(puredns_command: &str) {
    let command_output = Command::new("bash")
        .arg("-c")
        .arg(format!(
            "{}", puredns_command
        ))
        .output()
        .expect("Failed to execute puredns command");

    if ! command_output.status.success() {
        eprintln!(
            "Puredns Error: {}",
            String::from_utf8_lossy(&command_output.stderr)
        );
        process::exit(0); 
    }
}