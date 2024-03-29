#!/bin/bash

echo site:codepad.co \"$1\" 
echo site:scribd.com \"$1\" 
echo site:npmjs.com \"$1\" 
echo site:npm.runkit.com \"$1\" 
echo site:libraries.io \"$1\" 
echo site:coggle.it \"$1\" 
echo site:papaly.com \"$1\" 
echo site:trello.com \"$1\" 
echo site:prezi.com \"$1\" 
echo site:jsdelivr.net \"$1\" 
echo site:codepen.io \"$1\" 
echo site:justpaste.it "|" site:heypasteit.com "|" site:pastebin.com \"$1\" 
echo site:repl.it \"$1\" 
echo site:gitter.im \"$1\" 
echo site:bitbucket.org \"$1\" 
echo site:*.atlassian.net \"$1\" 
echo site:$1 inurl:Dashboard.jspa intext:"Atlassian Jira Project Management Software" 
echo site:gitlab \"$1\" 
echo site:http://groups.google.com \"$1\" 
echo site:.s3.amazonaws.com \"$1\"
echo site:s3.amazonaws.com "$1"
echo site:blob.core.windows.net "$1"
echo site:googleapis.com "$1"
echo site:drive.google.com "$1"
echo site:productforums.google.com \"$1\" 
echo site:replt.it \"$1\"  
echo site:ycombinator.com \"$1\"
echo site:onedrive.live.com "$1"
echo site:dropbox.com/s "$1"
echo site:box.com/s "$1"
echo site:dev.azure.com "$1"
echo site:http://sharepoint.com "$1"
echo site:digitaloceanspaces.com "$1"
echo site:firebaseio.com "$1"
echo site:jfrog.io "$1"
echo site:http://s3-external-1.amazonaws.com "$1"
echo site:http://s3.dualstack.us-east-1.amazonaws.com "$1"  
echo site:docs.google.com inurl:"/d/" "$1"