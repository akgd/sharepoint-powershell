[CmdletBinding()]
Param
([object]$WebhookData) # To be called WebHookData is a must otherwise the webhook does not work

# Check if Runbook is called from Webhook
if ($WebHookData) {

    # Collect properties of WebhookData
    $WebhookName = $WebHookData.WebhookName
    $WebhookHeaders = $WebHookData.RequestHeader
    $WebhookBody = $WebHookData.RequestBody

    $Input = (ConvertFrom-Json -InputObject $WebhookBody)
}
else {
    Write-Error -Message 'Runbook was not started from Webhook' -ErrorAction stop
}

# Function we'll use to ensure and add workspace users
function ensureAndAddUsersToGroup($userArr, $groupName) {
    # Check if there are users to process
    if ($userArr.Count -gt 0) {
        foreach ($user in $userArr) {
            # Determine if the userArr is an SP field object or one of our manual email arrays
            if ($user.Email) {
                $email = $user.Email
            }
            else {
                $email = $user
            }
            # Ensure user is in site collection
            $getUser = Get-PnPUser | Where-Object Email -eq "$email"

            if ( !$getUser ) {
                # User not found - try to add them
                $newUser = New-PnPUser -LoginName $email -ErrorAction SilentlyContinue

                if ($newUser) {
                    # User created - add to group
                    try {
                    Add-PnPUserToGroup -LoginName $email -Identity $groupName
                    } catch {
                        "Unable to add $email to $groupName" | Out-File -FilePath $logItem -Append
                    } 
                }
                else {
                    # User not valid in AAD - do nothing
                }
            }
            else { 
                # Valid user - add to group
                try {
                    Add-PnPUserToGroup -LoginName $email -Identity $groupName
                } catch {
                    "Unable to add $email to $groupName" | Out-File -FilePath $logItem -Append
                } 
            }
        }
    }
}

# Get ID from webhook data
$itemID = $Input.itemID

# Prepare log file
$tempPath = $env:TEMP
$logNow = (Get-Date).ToString("yyyyMMddThhmmssZ")
$logName = "Workspace Request $logNow SP ID $itemID.txt"
$logItem = New-Item -Path $tempPath -ItemType File -Name $logName

"List item ID received from webhook is $itemID" | Out-File -FilePath $logItem -Append

$creds = Get-AutomationPSCredential -Name "[redacted]"

$requestsSiteCollection = "[redacted]sites/WorkspaceGenerator"
$requestListName = "Requests"

# Connect to the site with the request list
Connect-PnPOnline -Url $requestsSiteCollection -Credentials $creds

# Get request item and details
$listItem = Get-PnPListItem -List $requestListName -Id $itemID
$subSiteTitle = $listItem["Title"]
$siteType = $listItem["SiteType"]

"Requested site title is $subSiteTitle" | Out-File -FilePath $logItem -Append
"Requested site type is $siteType" | Out-File -FilePath $logItem -Append

# Requestor hash because our ensure user function will expect it
$requestorEmail = @($listItem["Author"].Email)
"Requestor is $requestorEmail" | Out-File -FilePath $logItem -Append

# Store requested users
$siteOwners = $listItem["SiteOwners"]
$siteMembers = $listItem["SiteMembers"]
$siteVisitors = $listItem["SiteVisitors"]
$siteConfidential = $listItem["ConfidentialUsers"]

# Create unique subdirectory name
# $date = (Get-Date).ToString("yyyyMMdd")
$subSiteDir = "SPO-$itemID" 

# Special access to proposal workspaces
# Note the CGO group will be added during site creation
$proposalPDOOwners = @("[redacted]""[redacted]","[redacted]","[redacted]","[redacted]","[redacted]")
$proposalSpecialReaders = @("[redacted]", "[redacted]")

# Default confidential and valid request settings
$validRequest = $true
$isProposal = $false
$confidentialRequired = $false

# Collections and template for the selected type
# Add or update this area if options change
# When adding a proposal site set the isProposal variable to true
# When adding an extranet site set the confidential variable to true
if ($siteType -eq "Internal Project") {
    $collection = "[redacted]sites/projects"
    $template = "{06A45CDB-42EA-457B-B92E-ECC4D4472441}#2018-08-09-Project-Workspace"
    $groupNameStart = "Project $itemID"
}
elseif ($siteType -eq "Internal Community") {
    $collection = "[redacted]sites/communities"
    $template = "{E9256574-6E6A-4382-A66C-900B72298D9F}#2018-08-09-Community-Template"
    $groupNameStart = "Community $itemID"
}
elseif ($siteType -eq "Internal Proposal") {
    $collection = "[redacted]sites/proposals"
    $template = "{165D0F09-9275-42FB-9555-D7575ED71748}#Proposal-Template-2019-02-07"
    $groupNameStart = "Proposal $itemID"
    $isProposal = $true
}
elseif ($siteType -eq "Internal Proposal - multi-submission") {
    $collection = "[redacted]sites/proposals"
    $template = "{C8E3737B-B806-48AD-A1DB-BE71B72A1770}#2019-03-28 Proposal MultiSub"
    $groupNameStart = "Proposal $itemID"
    $isProposal = $true
}
elseif ($siteType -eq "Internal Proposal - contract vehicle") {
    $collection = "[redacted]sites/proposals"
    $template = "{2E677EBE-DB1A-44F3-9D27-83F3DCB6C6C8}#2019-03-28 Proposal Contract Vehicle"
    $groupNameStart = "Proposal $itemID"
}
elseif ($siteType -eq "Extranet Project") {
    $collection = "[redacted]sites/ext3"
    $template = "{68695E69-E69B-466E-8304-6D15C95B6688}#2019-01-16-Extranet"
    $groupNameStart = "Extranet Project $itemID"
    $confidentialRequired = $true
}
elseif ($siteType -eq "Extranet Proposal") {
    $collection = "[redacted]sites/ext-proposals"
    $template = "{C18EFA32-42D5-4582-AC55-E793C74A1821}#2019-01-16-ExtPropV5"
    $groupNameStart = "Extranet Proposal $itemID"
    $confidentialRequired = $true
    $isProposal = $true
}
elseif ($siteType -eq "Internal Proposal - QA") {
    $collection = "[redacted]sites/proposals"
    $template = "{D4FB95BF-319C-468C-B8FE-7F8FA6D7ED5D}#TemplatePropQADev"
    $groupNameStart = "Proposal $itemID"
    $isProposal = $true
}
else {
    # Requested site type not found
    $validRequest = $false
}

# If site type is valid, create site
if ($validRequest) {

    "Valid request, attempt to create site" | Out-File -FilePath $logItem -Append

    # Connect to the workspace collection
    Connect-PnPOnline -Url $collection -Credentials $creds

    $newPath = "$collection/$subSiteDir"
    $newSite = New-PnPWeb -Title $subSiteTitle -Url $subSiteDir -Description $siteType -Locale 1033 -Template $template -BreakInheritance
    Start-Sleep -s 5
  
    # Set new SP group names
    $ownersGroupName = "$groupNameStart Owners"
    $membersGroupName = "$groupNameStart Members"
    $visitorsGroupName = "$groupNameStart Visitors"
    $confidentialGroupName = "$groupNameStart Confidential"

    if ($newSite) {

        "Site created at $newPath" | Out-File -FilePath $logItem -Append

        # Connect to new sub-site
        Connect-PnPOnline -Url $newPath -Credentials $creds
        # Create groups in the site collection
        $newOwnersGroup = New-PnPGroup -Title $ownersGroupName -Owner $ownersGroupName -ErrorAction SilentlyContinue
        # Allow owners group to be created so we can set the owner for the other groups
        Start-Sleep -s 3
        $newMembersGroup = New-PnPGroup -Title $membersGroupName -Owner $ownersGroupName -ErrorAction SilentlyContinue
        $newVisitorsGroup = New-PnPGroup -Title $visitorsGroupName -Owner $ownersGroupName -ErrorAction SilentlyContinue
        Start-Sleep -s 3

        "Owners group" | Out-File -FilePath $logItem -Append
        $newOwnersGroup | Out-File -FilePath $logItem -Append
        "Members group" | Out-File -FilePath $logItem -Append
        $newMembersGroup | Out-File -FilePath $logItem -Append
        "Visitors group" | Out-File -FilePath $logItem -Append
        $newVisitorsGroup | Out-File -FilePath $logItem -Append


        Set-PnPGroup -Identity $ownersGroupName -SetAssociatedGroup Owners -AddRole "Full Control"
        Set-PnPGroup -Identity $membersGroupName -SetAssociatedGroup Members -AddRole "Edit"
        Set-PnPGroup -Identity $visitorsGroupName -SetAssociatedGroup Visitors -AddRole "Read" 
            
        ensureAndAddUsersToGroup $siteOwners $ownersGroupName
        ensureAndAddUsersToGroup $siteMembers $membersGroupName
        ensureAndAddUsersToGroup $siteVisitors $visitorsGroupName
        ensureAndAddUsersToGroup $requestorEmail $ownersGroupName

        # Unfortunately, we still need to MANUALLY set the access request owner to the Owners group

        if ($isProposal) {
            "This is a proposal site. Adding PDO, VPs, and CGO..." | Out-File -FilePath $logItem -Append
            # This is a proposal workspace, give PDO access
            ensureAndAddUsersToGroup $proposalPDOOwners $ownersGroupName
            # Give VPs read access
            ensureAndAddUsersToGroup $proposalSpecialReaders $visitorsGroupName
            # Add the CGO SP group
            Set-PnPGroup -Identity "Everyone in Contracts and Grants SharePoint Group" -AddRole "Edit" 
        }

        if ($confidentialRequired) {

            "This is an extranet site. Attempt special confidential processing." | Out-File -FilePath $logItem -Append

            $newConfidentialGroup = New-PnPGroup -Title $confidentialGroupName -Owner $ownersGroupName -ErrorAction SilentlyContinue
            Start-Sleep -s 3
            $newConfidentialGroup | Out-File -FilePath $logItem -Append
            Set-PnPGroup -Identity $confidentialGroupName -AddRole "Read" 

            $confidentialLibExists = Get-PnPList -Identity "/Confidential"
            if ($confidentialLibExists) {
                # Library exists so must be part of the template
                "Confidential library exists." | Out-File -FilePath $logItem -Append
            }
            else {
                # Library does not exist so lets create it
                "Confidential library does not exist. Creating library..." | Out-File -FilePath $logItem -Append
                New-PnPList -Title "Confidential" -Template DocumentLibrary -OnQuickLaunch
                Start-Sleep -s 3
            }
             "Breaking confidential permissions..." | Out-File -FilePath $logItem -Append
            Set-PnPList -Identity "Confidential" -BreakRoleInheritance
            Set-PnPListPermission -Identity "Confidential" -Group $ownersGroupName -AddRole "Full Control"
            Set-PnPListPermission -Identity "Confidential" -Group $confidentialGroupName -AddRole "Edit"
        }

        "Processing complete. Updating original request item to trigger email." | Out-File -FilePath $logItem -Append
        # Update the request list so we can trigger an email
        Connect-PnPOnline -Url $requestsSiteCollection -Credentials $creds
        $listItem = Get-PnPListItem -List $requestListName -Id $itemID
        $requestItemUpdate = Set-PnPListItem -List $requestListName -Identity $itemID -Values @{"SiteURL" = "$newPath"; "Status" = "Site created" }
        "END" | Out-File -FilePath $logItem -Append
    }
} else {
    "Invalid request, site creation not attempted" | Out-File -FilePath $logItem -Append
}

$spTeamSite = "[redacted]sites/SharePoint"
Connect-PnPOnline -Url $spTeamSite -Credentials $creds
$uploadSPTeamLog = Add-PnPFile -Path $logItem -Folder "Shared Documents/Logs/Shared Workspace Generation"