#!/bin/bash

echo site:codepad.co \"$1\" >> gdorks-3rd-party.txt
echo site:scribd.com \"$1\" >> gdorks-3rd-party.txt
echo site:npmjs.com \"$1\" >> gdorks-3rd-party.txt
echo site:npm.runkit.com \"$1\" >> gdorks-3rd-party.txt
echo site:libraries.io \"$1\" >> gdorks-3rd-party.txt
echo site:coggle.it \"$1\" >> gdorks-3rd-party.txt
echo site:papaly.com \"$1\" >> gdorks-3rd-party.txt
echo site:trello.com \"$1\" >> gdorks-3rd-party.txt
echo site:prezi.com \"$1\" >> gdorks-3rd-party.txt
echo site:jsdelivr.net \"$1\" >> gdorks-3rd-party.txt
echo site:codepen.io \"$1\" >> gdorks-3rd-party.txt
echo site:justpaste.it | site:heypasteit.com | site:pastebin.com \"$1\" >> gdorks-3rd-party.txt
echo site:repl.it \"$1\" >> gdorks-3rd-party.txt
echo site:gitter.im \"$1\" >> gdorks-3rd-party.txt
echo site:bitbucket.org \"$1\" >> gdorks-3rd-party.txt
echo site:*.atlassian.net \"$1\" >> gdorks-3rd-party.txt
echo site:$1 inurl:Dashboard.jspa intext:"Atlassian Jira Project Management Software" >> gdorks-3rd-party.txt
echo site:gitlab \"$1\" >> gdorks-3rd-party.txt
echo site:http://groups.google.com \"$1\" >> gdorks-3rd-party.txt
echo site:.s3.amazonaws.com \"$1\" >> gdorks-3rd-party.txt
echo site:productforums.google.com \"$1\" >> gdorks-3rd-party.txt
echo site:replt.it \"$1\" >> gdorks-3rd-party.txt 
echo site:ycombinator.com \"$1\" >> gdorks-3rd-party.txt