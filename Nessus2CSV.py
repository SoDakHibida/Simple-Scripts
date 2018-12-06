#!/usr/bin/python3
#####################################################################
# Script to Parse Nessus XML File and generate CSV
# output for assisting manual enumeration tracking
#
# Author: Eric Hanson
# Date: 02/13/2018
#
# Usage Example: python3 Nessus2CSV.py ./in.nessus > ./out.csv
#
#####################################################################

import sys
import xml.etree.ElementTree

xmlData = xml.etree.ElementTree.parse(sys.argv[1]).getroot()
ReportHosts = xmlData.find('Report').findall('ReportHost')

ReportHosts[:] = sorted(ReportHosts, key=lambda child: child.find("./HostProperties/tag/[@name='host-ip']").text)

for ReportHost in ReportHosts:
	if ReportHost.find("./ReportItem/[@pluginName='Nessus SYN scanner']"):
		HostIP = ReportHost.find("./HostProperties/tag/[@name='host-ip']").text
		print('{},"",""'.format(HostIP))
		for ReportItem in ReportHost.findall('ReportItem'):
			plugName = ReportItem.get('pluginName')
			if plugName == "Nessus SYN scanner":
				print('"","{}","{}"'.format(ReportItem.get('port'), ReportItem.get('svc_name')))
	
