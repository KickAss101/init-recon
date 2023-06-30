#!/bin/bash

echo site:$1 ext:action "|" ext:struts "|" ext:do 
echo site:$1 inurl:\"$1\" not for distribution "|" confidential "|" "employee only" "|" proprietary "|" top secret "|" classified "|" trade secret "|" internal "|" private filetype:xls OR filetype:csv OR filetype:doc OR filetype:pdf
echo site:$1 inurl:" target "notfordistribution"|"confidential"|"\"employeeonly\""|"proprietary"|"topsecret"|"classified"|"tradesecret"|"internal"|"private filetype:xls OR filetype:csv OR filetype:doc OR filetype:pdf
echo 'site:"'"$1"'" intext:"sql syntax near" | intext:"syntax error has occurred" | intext:"incorrect syntax near" | intext:"unexpected end of SQL command" | intext:"Warning: mysql_connect()" | intext:"Warning: mysql_query()" | intext:"Warning: pg_connect()"'
echo 'site:"'"$1"'" "PHP Parse error" | "PHP Warning" | "PHP Error"'
echo 'site:"'"$1"'" ext:php intitle:phpinfo "published by the PHP Group"'
echo '("'"$1"'") (site:*.*.29.* |site:*.*.28.* |site:*.*.27.* |site:*.*.26.* |site:*.*.25.* |site:*.*.24.* |site:*.*.23.* |site:*.*.22.* |site:*.*.21.* |site:*.*.20.* |site:*.*.19.* |site:*.*.18.* |site:*.*.17.* |site:*.*.16.* |site:*.*.15.* |site:*.*.14.* |site:*.*.13.* |site:*.*.12.* |site:*.*.11.* |site:*.*.10.* |site:*.*.9.* |site:*.*.8.* |site:*.*.7.* |site:*.*.6.* |site:*.*.5.* |site:*.*.4.* |site:*.*.3.* |site:*.*.2.* |site:*.*.1.* |site:*.*.0.*)'
echo 'site:"'"$1"'" inurl:q= | inurl:s= | inurl:search= | inurl:query= inurl:&'
echo 'site:"'"$1"'" inurl:url= | inurl:return= | inurl:next= | inurl:redir= inurl:http'
echo site:$1 ext:php inurl:?
echo site:openbugbounty.org inurl:reports intext:"$1"
 
