# Run in SharePoint management shell using an admin account
$orgName = [YOUR ORG]
Connect-SPOService -Url "https://$orgName-admin.sharepoint.com"
$site = "https://$orgName.sharepoint.com/sites/[YOUR SITE]"

# Check custom scripting status
Get-SPOSite $site -Detailed | select DenyAddAndCustomizePages

# Allow custom scripting or set to 1 to prevent it
Set-SPOSite -Identity $site -DenyAddAndCustomizePages 0
