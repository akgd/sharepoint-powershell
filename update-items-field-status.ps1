$OldLogfile = $MyInvocation.MyCommand.Path -replace "\.ps1$", "-old.csv"
$NewLogfile = $MyInvocation.MyCommand.Path -replace "\.ps1$", ".csv"
 
# Remove oldest log
If (Test-Path -Path $OldLogfile) { Remove-Item -Path $OldLogfile }
 
# Renaming previous log to -old.csv
If (Test-Path -Path $NewLogfile) { Rename-Item -Path $NewLogfile -NewName $OldLogfile }

Connect-PnPOnline -Url https://YOURTENANT.sharepoint.com/sites/YOURSITE -Credentials YOURCREDS
$listName = "Projects"

$timeNow = (Get-Date)
$maxProjectEndDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")

# get all items where the project end date is greater than today minus 30 days (grace period)
$listItems = Get-PnPListItem -List $listName -Query "<View><Query><Where><Geq><FieldRef Name='EndDate' /><Value Type='DateTime'>$maxProjectEndDate</Value></Geq></Where><OrderBy><FieldRef Name='EndDate'/></OrderBy></Query></View>" -PageSize 1000

foreach ($item in $listItems) {

    # default compliance status is New
    $compliance = "New"

    # get last meeting review date
    $lastRevMeeting = $item["LastReviewMeeting"]

    if ($item["ProjectStatus"] -eq "Completed") {
        $compliance = "Completed"
    }
    elseif ($item["SubjectToReview"] -eq "No") {
        $compliance = "Not Applicable"
    }
    elseif ($null -eq $lastRevMeeting) {
        # no last review meeting so lets compare created to today
        $createdDate = $item["Created"]
        $createdTimespan = New-TimeSpan -Start $createdDate -End $timeNow
        $daysSinceCreation = $createdTimespan.Days

        # if older than 60 days w/o review the project is not compliant
        if ($daysSinceCreation -gt 60) {
            $compliance = 'Not Compliant'
        } else {
            $compliance = 'Compliant'
        }
    }
    else {
        # there is a last review date so lets compare it to today
        $reviewTimespan = New-TimeSpan -Start $lastRevMeeting -End $timeNow
        $daysSinceReview = $reviewTimespan.Days
        $acceptableDays = 0
        $reviewSchedule = $item["MeetingScheduleOptions"]

        switch ($reviewSchedule) {
            "Every month" {$acceptableDays = 31; break}
            "Every 2 months" {$acceptableDays = 62; break}
            "Every 3 months" {$acceptableDays = 93; break}
            "Every 4 months" {$acceptableDays = 124; break}
            default {$acceptableDays = 62; break}
        }

        if ($daysSinceReview -gt $acceptableDays) {
            $compliance = 'Not Compliant'
        }
        else {
            $compliance = 'Compliant'
        }
    }
    
    # determine if we need to update the item and log outcome
    if ($item["ComplianceIndicator"] -ne $compliance) {
        $project = [pscustomobject]@{
            ProjectNumber = $item["Title"] 
            Action = "Updated"
            ComplianceBeforeRun = $item["ComplianceIndicator"]
            ComplianceAfterRun = $compliance
        }
        $project | Export-Csv -Path $NewLogfile -Append -NoTypeInformation
        Set-PnPListItem -List $listName -Identity $item["ID"] -Values @{"ComplianceIndicator" = $compliance } #-SystemUpdate
    } else {
        # log to csv
        $project = [pscustomobject]@{
            ProjectNumber = $item["Title"] 
            Action = "No Change"
            ComplianceBeforeRun = $item["ComplianceIndicator"]
            ComplianceAfterRun = $compliance
        }
        $project | Export-Csv -Path $NewLogfile -Append -NoTypeInformation
    }
}
