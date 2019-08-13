Connect-PnPOnline -Url "https://yourtenant.sharepoint.com/sites/yoursite" -Credentials $yourCreds

$listName = "your list name"
$batchSize = 10
$maxEndDate = (Get-Date).AddMonths(-12)
$listItems = (Get-PnPListItem -List $listName -Fields 'Title','ID','EndDate','Category','Modified' | Where-Object {$_["EndDate"] -lt $maxEndDate} | Select-Object -first $batchSize -wait).FieldValues

foreach($item in $listItems) {
    $itemID = $item.ID
    Move-PnPListItemToRecycleBin -List $listName -Identity $itemID -Force
    Write-Host "Deleting item" $itemID "with end date" $item.EndDate -ForegroundColor Yellow
}
