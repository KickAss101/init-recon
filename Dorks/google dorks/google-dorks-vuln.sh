#!/bin/bash

echo site:$1 ext:action | ext:struts | ext:do 
echo site:$1 inurl:\"$1\" not for distribution | confidential | "employee only" | proprietary | top secret | classified | trade secret | internal | private filetype:xls OR filetype:csv OR filetype:doc OR filetype:pdf
echo site:$1 inurl:" target "notfordistribution|confidential|\"employeeonly\"|proprietary|topsecret|classified|tradesecret|internal|privatefiletype:xlsORfiletype:csvORfiletype:docORfiletype:pdf