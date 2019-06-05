$site = "https://yourtenant.sharepoint.com/sites/yoursite"
$listName = "Your List Name"
$workflowName = "Your Workflow Name"

Connect-PnPOnline -Url $site -Credentials yourcreds

$listItems = Get-PnPListItem -List $listName
$workflow = Get-PnPWorkflowSubscription -List $listName -Name $workflowName

foreach ($item in $listItems) {
    Start-PnPWorkflowInstance -Subscription $workflow -ListItem $item["ID"]
}