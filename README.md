# SharePoint PowerShell Examples

### Check installed versions
```
Get-Module SharePointPnPPowerShell* -ListAvailable | Select-Object Name,Version | Sort-Object Version
```

### Update Module
Remember to run as administrator
```
Update-Module SharePointPnPPowerShell*
```
