Connect-PnPOnline -Url "https://yourtenant.sharepoint.com/sites/yoursite" -Credentials $yourCreds

$listName = "Project Inventory"
$choiceFieldIntName = "Alignment"
$oldVal = "Cultural Competence and Equity"
$newVal = "Equitable Opportunities and Outcomes"

$listItems = Get-PnPListItem -List $listName

foreach ($item in $listItems) {
    $itemID = $item["ID"]
    $currentVals = $item[$choiceFieldIntName]
    $updatedVals = $currentVals -replace $oldVal, $newVal

    if ($currentVals -ne $updatedVals) {
        $updatedItemData = @{
            $choiceFieldIntName = $updatedVals
        }
        
        $update = Set-PnPListItem -List $listName -Identity $itemID -Values $updatedItemData
        Write-Host "Updated item ID $itemID"

    }
}

