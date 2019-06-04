Connect-PnPOnline -Url https://yourtenant.sharepoint.com/sites/yoursite -Credentials yourcreds
$listName = "Test"
$fieldName = "AssignedTo"
$oldEmail = "jim@company.org"
$newEmail = "bob@air.org"

$listItems = Get-PnPListItem -List $listName | Where-Object { $_.FieldValues.$FieldName.Email -eq $oldEmail} 

foreach ($item in $listItems) {
    $userEmails = @()
    $emails = $item[$fieldName].email;
    foreach ($email in $emails) {
        if ($email -eq $oldEmail) {
            $userEmails += $newEmail
        }
        else {
            $userEmails += $email
        }
    }
    Set-PnPListItem -List $listName -Identity $item["ID"] -Values @{$fieldName = $userEmails}
}