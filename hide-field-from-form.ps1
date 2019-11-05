$site = "https://[tenant].sharepoint.com/sites/[site]"
Connect-PnPOnline -Url $site -Credentials [creds]

$listName = "Vacation"
$columnName = "Title"

# Hide field from default SP items forms
Set-PnPField -List $listName -Identity $columnName -Values @{Required=$false;Hidden=$true}
