#!/bin/bash
#created by M1ndFl4y
#important things to do before the scan
#change the name of the mainfolder to specify the client
MAINFOLDER="/root/Desktop/fision-external"

#example of a valid use of this script
#./externalenum.sh example.com 127.0.0.1,127.0.0.2,127.0.0.3

if [[ $# -eq 0 ]] ; then
	echo 'You need to supply arguments for this script to run properly.'
    echo 'externalenum.sh example.com 127.0.0.1,127.0.0.2,127.0.0.3,example.com,domain.com'
    exit 1
fi



#path location of the scripts to match where you placed them on your system
SCRIPTPATH=$MAINFOLDER"/scripts"
#create folders
sleep 1
#explain
echo -e "\e[32mStatus updates will be posted in color.\e[0m"
echo -e "\e[32mScan progress will be posted in \e[0mwhite."
echo -e "\e[32mCreating working folder... \e[0m"$MAINFOLDER
export MAINFOLDER
export DOMAIN
echo -e "\e[32m"
mkdir $MAINFOLDER
sleep 1
echo -e "\e[31m**WARNING** This script spawns nmap and nikto in the background.  These processes can't be stopped from this terminal.  \e[0m"
#prompt for target domain to scan
DOMAIN=$1
for DOMAIN in "$1"
do
echo -e "\e[32mYou are going to scan \e[0m"$DOMAIN
read -p 'Are you sure? [Y/n]' -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi
done
#prompt for targets to scan
echo "" > $MAINFOLDER"/ip.txt"
targetstring=$2
echo -e "\e[32mYou are going to scan \e[0m"
for targetstring in "$2"
do
shopt -s extglob
targetstring=${2//+([[:space:]])/}
echo "$targetstring" | tr , '\n' >> $MAINFOLDER"/ip.txt"
done
cat $MAINFOLDER"/ip.txt"
read -p 'Are you sure? [Y/n]' -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

#create folders
sleep 1
#explain
echo -e "\e[32mCreating subfolders...\e[0m"
echo -e "\e[32m"
mkdir $MAINFOLDER
sleep 1
mkdir $MAINFOLDER"/scripts"
mkdir $MAINFOLDER"/dns"
mkdir $MAINFOLDER"/nmap"
mkdir $MAINFOLDER"/nikto"
mkdir $MAINFOLDER"/dirb"
echo -e "\e[0m"
sleep 1
#start DNS recon
echo -e "\e[32mStarting DNS recon.\e[0m"
echo "Starting DNS recon on the target $domain $(date)" >> $MAINFOLDER"/worklog.txt"
dnsrecon -d $DOMAIN --xml $MAINFOLDER/dns/dnsrecon >$MAINFOLDER/dns/dnsrecon-raw
echo "DNS recon on the target $domain completed $(date)" >> $MAINFOLDER"/worklog.txt"
echo -e "\e[32mDNS recon done.\e[0m"
sleep 1
cat $MAINFOLDER"/dns/dnsrecon-raw"
sleep 5
#find targets for nikto and dirb
echo -e "\e[32mStarting nmap web portal scans for 80 and 443.\e[0m"
for ip in $(cat $MAINFOLDER"/ip.txt");do
	echo "Starting nmap web portal scan on the target $ip $(date)" >> $MAINFOLDER"/worklog.txt"
	#selective port scan
	nmap -sS -T4 -p 80,443,8080,8443 $ip -oN $MAINFOLDER'/nmap/web-portal-sweep-'$ip'.txt';
	echo "nmap web portal scan on the target $ip completed $(date)" >> $MAINFOLDER"/worklog.txt"
done
echo -e "\e[32mTargets found for web portal scans.\e[0m"
sleep 1
grep -L "open" $MAINFOLDER/nmap/web-portal-sweep-* |xargs rm -f
echo -e "\e[32mNull nmap web portal scans findings purged.\e[0m"
echo -e "\e[32mnmap web portal scans for 80,443,591,8008,8080,8443 done.\e[0m"
sleep 1
#show targets for dirb-nikto
grep "open" $MAINFOLDER/nmap/web-portal-sweep-* |cut -d ':' -f 1 |cut -d '-' -f 4 >targets-for-dirb-nikto
#build scripts to run in background nmap-nikto-dirb.
#nmap
echo " "
echo -e "\e[32mBuilding nmap script in script folder.\e[0m"
echo 'echo -e "\e[32mStarting nmap scans.\e[0m"' > $SCRIPTPATH/nmap.sh
echo "#!/bin/bash" > $SCRIPTPATH'/nmap.sh'
echo 'for ip in $(cat $MAINFOLDER"/ip.txt");do' >> $SCRIPTPATH/nmap.sh
echo 'echo "Starting nmap scan on the target $ip $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/nmap.sh
echo '#top 1000' >> $SCRIPTPATH/nmap.sh
echo 'nmap -sTVC -Pn -T4 -vvv $ip -oN $MAINFOLDER'/nmap/nmap-'$ip;' >> $SCRIPTPATH/nmap.sh
echo 'echo "nmap scan on the target $ip completed $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/nmap.sh
echo 'done' >> $SCRIPTPATH/nmap.sh
echo 'sleep 1;' >> $SCRIPTPATH/nmap.sh
echo 'grep -L "/tcp open\|/tcp filtered\|/udp open\|/udp filtered" $MAINFOLDER/nmap/nmap-* | xargs rm' >> $SCRIPTPATH/nmap.sh
echo 'echo -e "\e[32mNull nmap findings purged.\e[0m"' >> $SCRIPTPATH/nmap.sh
echo 'echo -e "\e[32mnmap done.\e[0m"' >> $SCRIPTPATH/nmap.sh
echo 'sleep 1' >> $SCRIPTPATH/nmap.sh
echo '#show targets for dirb-nikto' >> $SCRIPTPATH/nmap.sh
echo 'grep "open  http\|open  ssl\|open  http" $MAINFOLDER/nmap/nmap-* | cut -d '-' -f 2 | cut -d ':' -f 1 >targets-for-dirb-nikto' >> $SCRIPTPATH/nmap.sh
echo '#show target ports for dirb-nikto' >> $SCRIPTPATH/nmap.sh
echo 'cat $MAINFOLDER/nmap/nmap-* |grep "open  http" >target-ports-for-dirb-nikto' >> $SCRIPTPATH/nmap.sh
sleep 1
chmod 744 $SCRIPTPATH/nmap.sh
echo -e "\e[32mnmap script built\e[0m"
sleep 1
echo -e "\e[32mBuilding nikto script in script folder.\e[0m"
echo '#!/bin/bash' >> $SCRIPTPATH/nikto.sh
echo 'echo -e "\e[32mStarting nikto scans.\e[0m"' >> $SCRIPTPATH/nikto.sh
echo 'for ip in $(cat $MAINFOLDER"/ip.txt");do' >> $SCRIPTPATH/nikto.sh
echo 'echo "Starting nikto scan on the target $ip on port 80 $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/nikto.sh
echo 'nikto -host http://$ip -output $MAINFOLDER"/nikto/nikto-"$ip"-80.txt";' >> $SCRIPTPATH/nikto.sh
echo 'echo "nikto scan on the target $ip on port 80 completed $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/nikto.sh
echo 'done' >> $SCRIPTPATH/nikto.sh
echo 'for ip in $(cat $MAINFOLDER"/ip.txt");do' >> $SCRIPTPATH/nikto.sh
echo 'echo "Starting nikto scan on the target $ip on port 8080 $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/nikto.sh
echo 'nikto -host http://$ip:8080 -output $MAINFOLDER"/nikto/nikto-"$ip"-8080.txt";' >> $SCRIPTPATH/nikto.sh
echo 'echo "nikto scan on the target $ip on port 8080 completed $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/nikto.sh
echo 'done' >> $SCRIPTPATH/nikto.sh
echo 'for ip in $(cat $MAINFOLDER"/ip.txt");do' >> $SCRIPTPATH/nikto.sh
echo 'echo "Starting nikto scan on the target $ip on port 443 $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/nikto.sh
echo 'nikto -host https://$ip -output $MAINFOLDER"/nikto/nikto-"$ip"-443.txt";' >> $SCRIPTPATH/nikto.sh
echo 'echo "nikto scan on the target $ip on port 443 completed $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/nikto.sh
echo 'done' >> $SCRIPTPATH/nikto.sh
echo 'for ip in $(cat $MAINFOLDER"/ip.txt");do' >> $SCRIPTPATH/nikto.sh
echo 'echo "Starting nikto scan on the target $ip on port 8443 $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/nikto.sh
echo 'nikto -host https://$ip:8443 -output $MAINFOLDER"/nikto/nikto-"$ip"-8443.txt";' >> $SCRIPTPATH/nikto.sh
echo 'echo "nikto scan on the target $ip on port 8443 completed $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/nikto.sh
echo 'done' >> $SCRIPTPATH/nikto.sh
echo 'grep -L "Target Host:" $MAINFOLDER/nikto/nikto-* | xargs rm' >> $SCRIPTPATH/nikto.sh
echo 'echo -e "\e[93mnikto findings purged.\e[0m"' >> $SCRIPTPATH/nikto.sh
echo 'echo -e "\e[93mnikto done.\e[0m"' >> $SCRIPTPATH/nikto.sh
echo -e "\e[32mnikto script built\e[0m"
sleep 1
chmod 744 $SCRIPTPATH/nikto.sh
sleep 1
echo -e "\e[32mBuilding dirb script in script folder.\e[0m"
echo '#!/bin/bash' > $SCRIPTPATH/dirb.sh
echo 'echo -e "\e[32mStarting dirb scans.\e[0m"' >> $SCRIPTPATH/dirb.sh
echo 'for ip in $(cat $MAINFOLDER"/ip.txt");do' >> $SCRIPTPATH/dirb.sh
echo 'echo "Starting dirb scan on the target $ip on port 80 $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/dirb.sh
echo 'dirb http://$ip /usr/share/dirb/wordlists/common.txt -f -o $MAINFOLDER"/dirb/dirb-"$ip"-80.txt";' >> $SCRIPTPATH/dirb.sh
echo 'echo "dirb scan on the target $ip on port 80 completed $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/dirb.sh
echo 'done' >> $SCRIPTPATH/dirb.sh
echo 'for ip in $(cat $MAINFOLDER"/ip.txt");do' >> $SCRIPTPATH/dirb.sh
echo 'echo "Starting dirb scan on the target $ip on port 8080 $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/dirb.sh
echo 'dirb http://$ip:8080 /usr/share/dirb/wordlists/common.txt -f -o $MAINFOLDER"/dirb/dirb-"$ip"-8080.txt";' >> $SCRIPTPATH/dirb.sh
echo 'echo "dirb scan on the target $ip on port 8080 completed $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/dirb.sh
echo 'done' >> $SCRIPTPATH/dirb.sh
echo 'for ip in $(cat $MAINFOLDER"/ip.txt");do' >> $SCRIPTPATH/dirb.sh
echo 'echo "Starting dirb scan on the target $ip on port 443 $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/dirb.sh
echo 'dirb https://$ip /usr/share/dirb/wordlists/common.txt -f -o $MAINFOLDER"/dirb/dirb-"$ip"-443.txt";' >> $SCRIPTPATH/dirb.sh
echo 'echo "dirb scan on the target $ip on port 443 completed $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/dirb.sh
echo 'done' >> $SCRIPTPATH/dirb.sh
echo 'for ip in $(cat $MAINFOLDER"/ip.txt");do' >> $SCRIPTPATH/dirb.sh
echo 'echo "Starting dirb scan on the target $ip on port 8443 $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/dirb.sh
echo 'dirb https://$ip:8443 /usr/share/dirb/wordlists/common.txt -f -o $MAINFOLDER"/dirb/dirb-"$ip"-8443.txt";' >> $SCRIPTPATH/dirb.sh
echo 'echo "dirb scan on the target $ip on port 8443 completed $(date)" >> $MAINFOLDER"/worklog.txt"' >> $SCRIPTPATH/dirb.sh
echo 'done' >> $SCRIPTPATH/dirb.sh
echo 'sleep 1' >> $SCRIPTPATH/dirb.sh
echo 'grep -L "+ http" $MAINFOLDER/dirb/dirb-* | xargs rm' >> $SCRIPTPATH/dirb.sh
echo 'echo -e "\e[36mNull dirb findings purged.\e[0m"' >> $SCRIPTPATH/dirb.sh
echo 'echo -e "\e[36mdirb done.\e[0m"' >> $SCRIPTPATH/dirb.sh
echo -e "\e[32mdirb script built\e[0m"
sleep 1
chmod 744 $SCRIPTPATH/dirb.sh
sleep 1
#start nmap
$SCRIPTPATH/nmap.sh &
sleep 5
#start nikto
$SCRIPTPATH/nikto.sh &
sleep 10
#start dirb
$SCRIPTPATH/dirb.sh
sleep 1
#Start process checking every 5 minutes.
counter1=0
counter2=0
counter3=0
#check on nmap and only move on after the process is gone.
while [ $counter1 = 0 ]
do
if pgrep -x "nmap" > /dev/null
then
    echo -e "\e[32mFull Nmap scan is still running...\e[0m"
sleep 300
else
counter1=1
    echo -e "\e[32mFull Nmap scan is DONE!!!. Moving on\e[0m"
fi
done
#check on nikto and only move on after the process is gone.
while [ $counter2 = 0 ]
do
if pgrep -x "nikto" > /dev/null
then
    echo -e "\e[32mFull nikto scan is still running...\e[0m"
sleep 300
else
counter2=1
    echo -e "\e[32mFull nikto scan is DONE!!!. Moving on\e[0m"
fi
done
#check on dirb and only move on after the process is gone.
while [ $counter3 = 0 ]
do
if pgrep -x "dirb" > /dev/null
then
    echo -e "\e[32mFull dirb scan is still running...\e[0m"
sleep 300
else
counter3=1
    echo -e "\e[32mFull dirb scan is DONE!!!. Moving on\e[0m"
fi
done
echo -e "\e[32mDone!  Printing summary of all findings.\e[0m"
sleep 1
echo -e "\e[32m"; #green
echo "** NMAP TCP **";
find $MAINFOLDER -name "nmap-*" |xargs grep "open\|scan report" |cut -d':' -f2
echo -e "\e[0m";
sleep 1
echo -e "\e[93m"; #light yellow
echo "** NIKTO  **";
find $MAINFOLDER -name "nikto-*" |xargs grep "Target Host:\|Target Port:\|+ " |cut -d':' -f2-1337
echo -e "\e[0m";
sleep 1
echo -e "\e[36m"; #cyan
echo "** DIRB **";
find $MAINFOLDER -name "dirb-*" |xargs grep "URL_BASE:\|+ " |cut -d':' -f2-1337
echo -e "\e[0m";
echo -e "\e[32mAll done.  Start focused enumeration.\e[0m"
sleep 2d
