# Create log file
$tempPath = $env:TEMP
$logNow = (Get-Date).ToString("yyyyMMddThhmmssZ")
$logName = "Process Name $logNow.txt"
$logItem = New-Item -Path $tempPath -ItemType File -Name $logName

# Example of adding to file
"Some data" | Out-File -FilePath $logItem -Append

# Check if log has content before uploading
if (Get-Content $logItem) {
    # Connect to site you want to store logs in
    $creds = Get-AutomationPSCredential -Name "NameOfYourStoredCred"
    $teamSite = "https://yourtenant.sharepoint.com/sites/yoursite"
    Connect-PnPOnline -Url $spTeamSite -Credentials $creds
    # Specify the folder
    $logFolderPath = "Documents/Project Logs"
    # Upload log
    # See https://github.com/SharePoint/PnP-PowerShell/issues/722 to learn why this is stored in a variable
    $uploadLog = Add-PnPFile -Path $logItem -Folder $logFolderPath
}
else {
    # Log is empty so do nothing
}
