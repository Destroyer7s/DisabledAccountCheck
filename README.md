# Active Directory Disabled Users Checker

This PowerShell script is designed to identify users in Active Directory who are marked as "disabled" in the Description field but are still enabled and are members of their respective groups.

## Prerequisites

- Ensure that the Active Directory module is installed. You can import it using the following command:

    ```powershell
    Import-Module ActiveDirectory
    ```

## Usage

1. Run the script.
2. Enter the search base when prompted. This can be found under the 'distinguishedName' attribute in AD (e.g., `OU=Disabled Users,DC=example,DC=com`).

## Script Logic

1. **Prompt for Search Base:**
   - The script prompts the user to enter the search base, which determines the scope of the search.

    ```powershell
    $searchBase = Read-Host "Enter the search base (e.g., OU=Disabled Users,DC=example,DC=com):"
    ```

2. **Get Disabled Users:**
   - Retrieve all users with "disabled" in the Description field that are still enabled.

    ```powershell
    $disabledUsers = Get-ADUser -Filter {(Description -like "*disabled*") -and (Enabled -eq $true)} -SearchBase $searchBase -Properties Description, MemberOf
    ```

3. **Check Group Membership:**
   - For each disabled user, check if they are still a member of their groups.

    ```powershell
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
    ```

4. **Display Results:**
   - If the user is not a member of any group, display information.

    ```powershell
        if ($groupsNotFound.Count -eq 0) {
            Write-Host "User $($user.SamAccountName) is marked as disabled but is still enabled and is a member of their groups."
        } else {
            Write-Host "User $($user.SamAccountName) is marked as disabled but is still enabled. Groups not found: $($groupsNotFound -join ', ')"
        }
    }
    ```
