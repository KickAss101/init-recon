#!/bin/bash

echo site:$1 \"ext:doc | ext:docx | ext:odt | ext:pdf\" filetype:password >> gdorks-sensitive-files.txt
echo site:$1 \"ext:sql | ext:db\" intext:password >> gdorks-sensitive-files.txt
echo site:$1 \"ext:config | ext:cnf | ext:reg | ext:inf\" intext:password >> gdorks-sensitive-files.txt
echo site:$1 \"ext:asp | ext:aspx | ext:php | ext:jsp\" intext:password >> gdorks-sensitive-files.txt
echo site:$1 \"ext:swf | ext:fla\" intext:password >> gdorks-sensitive-files.txt
echo site:$1 \"ext:doc | ext:docx | ext:odt | ext:pdf\" intext:confidential >> gdorks-sensitive-files.txt
echo site:$1 \"ext:xls | ext:xlsx | ext:csv\" intext:credit card >> gdorks-sensitive-files.txt
echo site:$1 \"ext:ppt | ext:pptx | ext:odp\" intext:presentation >> gdorks-sensitive-files.txt
echo site:$1 \"ext:doc | ext:docx | ext:odt | ext:pdf\" intext:proposal >> gdorks-sensitive-files.txt
echo site:$1 \"ext:doc | ext:docx | ext:odt | ext:pdf\" intext:financial report >> gdorks-sensitive-files.txt
echo site:$1 ext:bkf | ext:bkp | ext:bak | ext:old | ext:backup >> gdorks-sensitive-files.txt
echo site:$1 allintext:username filetype:log >> gdorks-sensitive-files.txt
echo site:$1 inurl:/proc/self/cwd >> gdorks-sensitive-files.txt
echo site:$1 \"index of\" \"database.sql.zip\" >> gdorks-sensitive-files.txt
echo site:$1 inurl:admin \"@gmail.com\" >> gdorks-sensitive-files.txt 
echo site:$1 inurl:zoom.us/j and intext:\"scheduled for\" >> gdorks-sensitive-files.txt
echo site:$1 allintitle: restricted filetype:doc site:gov >> gdorks-sensitive-files.txt
echo site:$1 intitle:\"Index of\" wp-admin >> gdorks-sensitive-files.txt