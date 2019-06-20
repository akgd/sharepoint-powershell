$tempPath = $env:TEMP
$now = (Get-Date).ToString("yyyyMMddThhmmssZ")
$logName = "Your process $now.txt"
$logItem = New-Item -Path $tempPath -ItemType File -Name $logName

"Some update" | Out-File -FilePath $logItem -Append
"Another update" | Out-File -FilePath $logItem -Append

$spoCreds = Get-AutomationPSCredential -Name "YourCredName"
$site = "https://YourTenant.sharepoint.com/sites/YourSite"
Connect-PnPOnline -Url $site -Credentials $spoCreds
$uploadLog = Add-PnPFile -Path $logItem -Folder "Documents/Logs"
