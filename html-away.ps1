Write-Host "html-away PowerShell Script: `n "

$string = Get-Content -Path C:\Users\user\Desktop\input.txt
$string -replace '<[^>]+>',''
