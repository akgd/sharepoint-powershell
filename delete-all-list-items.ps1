$site = "https://[YourTenant].sharepoint.com/sites/[YourSite]"
Connect-PnPOnline -Url $site -Credentials [YourCreds]

$listName = "Neat List"
$listItems = Get-PnPListItem -List $listName

$listItems.Count

foreach ($item in $listItems) {
    $itemID = $item["ID"]
    Remove-PnPListItem -List $listName -Identity $itemID -Force -Recycle
}
