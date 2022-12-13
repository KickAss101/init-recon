#!/bin/bash

echo site:$1 ext:action | ext:struts | ext:do >> gdorks-vuln.txt
echo inurl:\"$1\" not for distribution | confidential | "employee only" | proprietary | top secret | classified | trade secret | internal | private filetype:xls OR filetype:csv OR filetype:doc OR filetype:pdf)
echo inurl:" target "notfordistribution|confidential|\"employeeonly\"|proprietary|topsecret|classified|tradesecret|internal|privatefiletype:xlsORfiletype:csvORfiletype:docORfiletype:pdf