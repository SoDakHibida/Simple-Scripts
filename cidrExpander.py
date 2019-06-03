import ipaddress

fin = open("input.txt","r")
fout = open("ip_list.txt","w+")

inputFile = fin.readlines()

for line in inputFile:
  
  cidrLine = line.rstrip("\n")
  unicodeCIDR = unicode(cidrLine, "utf-8")
  network = ipaddress.ip_network(unicodeCIDR)
  
  for ip in network:
    fout.write(str(ip)+"\n")
    
fout.close()
