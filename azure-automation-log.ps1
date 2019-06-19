$tempPath = $env:TEMP
$now = (get-date).ToString('yyyyMMddThhmmssZ')
$logName = "Your process $now.txt"
$logItem = New-Item -Path $tempPath -ItemType File -Name $logName

"Some update" | Out-File -FilePath $logItem -Append
"Another update" | Out-File -FilePath $logItem -Append

$spoCreds = Get-AutomationPSCredential -Name "YourCredName"
$site = "https://YourTenant.sharepoint.com/sites/YourSite"
Connect-PnPOnline -Url $site -Credentials $creds
$UploadLog = Add-PnPFile -Path $logItem -Folder "Documents/Logs"
