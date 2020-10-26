$processedUsers = new-object system.collections.arraylist
function ensureUser($email, $propToReturn) {
    if ($processedUsers.email -contains $email) {
        # We previously processed this email
        $user = $processedUsers | ? email -eq "$email"
        return $user.$propToReturn
    }
    else {
        if ($email) {
            $user = Get-PnPUser | ? Email -eq "$email"
            if ( !$user ) {
                # User not found so try to create one
                $newUser = New-PnPUser -LoginName $email -ErrorAction SilentlyContinue
                if ( !$newUser ) {
                    # User isn't a valid in AAD
                    $storeUser = [pscustomobject]@{
                        email = $email
                        $propToReturn = $false
                    }
                    $processedUsers.add($storeUser)
                    return $false
                }
                else {
                    # User created
                    $storeUser = [pscustomobject]@{
                        email = $email
                        $propToReturn  = $user.$propToReturn
                    }
                    $processedUsers.add($storeUser)
                    return $newUser.$propToReturn
                }
            }
            else { 
                $storeUser = [pscustomobject]@{
                    email = $email
                    $propToReturn  = $user.$propToReturn
                }
                $processedUsers.add($storeUser)
                return $user.$propToReturn
            }
        }
        else {
            # No email passed
            return $false
        }
    }
}

# Usage
$p1 = ensureUser "andrea@fomain.org" "Title"
$p2 = ensureUser "jack@domain.org" "Title"
