$site = "https://[YOUR TENANT].sharepoint.com/sites/[YOUR SITE]"
Connect-PnPOnline -Url $site -Credentials [YOUR CREDS]

$listName = "Projects"
$listItems = Get-PnPListItem -List $listName

foreach ($item in $listItems) {
    $itemID = $item["ID"]
    $update = Set-PnPListItem -List $listName -Identity $itemID -Values @{"Editor" = "[YOUR ADMIN EMAIL]";"Author" = "[YOUR ADMIN EMAIL]"}
}

