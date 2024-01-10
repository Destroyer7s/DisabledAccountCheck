# Import the Active Directory module
Import-Module ActiveDirectory

# Prompt user for the search base
$searchBase = Read-Host "Enter the search base (This can be found under the 'distinguishedName' attribute in AD. e.g., OU=Disabled Users,DC=example,DC=com):"

# Get all users with "disabled" in the Description field that are still enabled
$disabledUsers = Get-ADUser -Filter {(Description -like "*disabled*") -and (Enabled -eq $true)} -SearchBase $searchBase -Properties Description, MemberOf

foreach ($user in $disabledUsers) {
    # Check if the user is a member of their groups
    $memberOfGroups = Get-ADUser $user -Properties MemberOf | Select-Object -ExpandProperty MemberOf

    $groupsNotFound = @()
    
    foreach ($group in $memberOfGroups) {
        # Check if the user is still a member of the group
        if (-not (Get-ADGroupMember -Identity $group -Recursive | Where-Object { $_.SamAccountName -eq $user.SamAccountName })) {
            $groupsNotFound += $group
        }
    }

    # If the user is not a member of any group, display the information
    if ($groupsNotFound.Count -eq 0) {
        Write-Host "User $($user.SamAccountName) is marked as disabled but is still enabled and is a member of their groups."
    } else {
        Write-Host "User $($user.SamAccountName) is marked as disabled but is still enabled. Groups not found: $($groupsNotFound -join ', ')"
    }
}
