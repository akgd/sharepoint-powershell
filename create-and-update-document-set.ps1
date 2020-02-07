# connect to SharePoint site
$site = "https://[your_tenant].sharepoint.com/sites/[your_site]"
Connect-PnPOnline -Url $site -Credentials [your_creds]

# provide the target list, doc set name, and doc set properties
$listName = "2020 Projects"
$newDocSetName = "Test"
$props = @{
    "Status" = "New";
    "ProjectManager" = "Andrea"
}

# create a new doc set
$newDocSet = Add-PnPDocumentSet -List $listName -ContentType "Document Set" -Name $newDocSetName

# query for and update the new doc set properties
$query = "<View><Query><Where><And><Eq><FieldRef Name='ContentType' /><Value Type='Computed'>Document Set</Value></Eq><Eq><FieldRef Name='LinkFilenameNoMenu' /><Value Type='Computed'>$newDocSetName</Value></Eq></And></Where></Query></View>"
$listItems = Get-PnPListItem -List $listName -Query $query
foreach ($item in $listItems | Select-Object -First 1) {
    Set-PnPListItem -List $listName -Identity $item["ID"] -Values $props
}
