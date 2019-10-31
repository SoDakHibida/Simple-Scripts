# Internet Protocol (IP) Address Check PowerShell Script
# Author: SoDakHib
# Last Modified: 10/31/2019

# Checking Our Public IP Address using ifconfig.me/ip
$myip = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content

# Creating a Windows Pop-up Notification using Windows Forms API
Add-Type -AssemblyName System.Windows.Forms
$global:balmsg = New-Object System.Windows.Forms.NotifyIcon
$path = (Get-Process -id $pid).Path
$balmsg.Icon = "C:\Users\jservaty\map-marker.ico"
$balmsg.BalloonTipText = $myip
$balmsg.BalloonTipTitle = "Daily IP Check"
$balmsg.Visible = $true
$balmsg.ShowBalloonTip(2000)

# Add to Daily Log
$log = "$(Get-Date)		[$myip]"
Add-Content C:\Users\jservaty\ip_list.txt $log

# Clean Up
# $balmsg.Dispose()