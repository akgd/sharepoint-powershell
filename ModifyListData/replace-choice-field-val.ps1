Connect-PnPOnline -Url "https://yourtenant.sharepoint.com/sites/yoursite" -Credentials $yourCreds

$listName = "Project Inventory"
$choiceFieldIntName = "Category"
$oldVal = "foo"
$newVal = "bar"

$listItems = Get-PnPListItem -List $listName

foreach ($item in $listItems) {
    $itemID = $item["ID"]
    $currentVals = $item[$choiceFieldIntName]

    if ($currentVals -contains $oldVal) {
        $updatedVals = $currentVals -replace $oldVal, $newVal
        $uniqueVals = $updatedVals | Sort-Object -unique

        $updatedItemData = @{
            $choiceFieldIntName = $uniqueVals
        }
        
        $update = Set-PnPListItem -List $listName -Identity $itemID -Values 
        Write-Host "Updated item ID $itemID"

    }
}

