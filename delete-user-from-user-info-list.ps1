$site = "https://[yourtenant].sharepoint.com/sites/[yourcollection]"
Connect-PnPOnline -Url $site -Credentials $creds

Get-PnPUser | Where-Object Email -eq "someone@gmail.com" | Remove-PnPUser
# You will be prompted to confirm deletion
