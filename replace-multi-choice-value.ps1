Connect-PnPOnline -Url "https://[yourtenant].sharepoint.com/sites/[yoursite]" -Credentials [yourcreds]

$listName = "Projects"
$choiceFieldIntName = "Alignment"
$oldVal = "Some value"
$newVal = "Some other value"

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

        $update = Set-PnPListItem -List $listName -Identity $itemID -Values $updatedItemData
        Write-Host "Updated item ID $itemID"
    }
}

