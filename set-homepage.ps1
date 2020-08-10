$site = "https:/[YOUR_TENANT].sharepoint.com/sites/[YOUR_SITE]"
Connect-PnPOnline -Url $site -Credentials [YOUR_CREDS]
Set-PnPHomePage -RootFolderRelativeUrl "SomeDocLibrary/Forms/AllItems.aspx"
