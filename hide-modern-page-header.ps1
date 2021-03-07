$creds = "[your creds]"
$site = "https://[your tenant].sharepoint.com/sites/[your site]"
Connect-PnPOnline -Url $site -Credentials $creds
# Hide the page header
Set-PnPClientSidePage -Identity "Some-Page.aspx" -LayoutType Home
