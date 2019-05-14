$site = "YOUR SITE";
Connect-PnPOnline -Url $site -UseWebLogin;

$listName = "YOUR LIST NAME";
$batchSize = 10;
$maxEndDate = (Get-Date).AddMonths(-12);
$listItems = (Get-PnPListItem -List $listName -Fields 'Title','ID','EndDate','Category','Modified' | ? {$_["EndDate"] -lt $maxEndDate} | Select -first $batchSize -wait).FieldValues;

foreach($item in $listItems) {
    $itemID = $item.ID;
    Move-PnPListItemToRecycleBin -List $listName -Identity $itemID -Force;
    Write-Host "Deleting item" $itemID "with end date" $item.EndDate -ForegroundColor Yellow;
}
