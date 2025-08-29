Clear-Host

# Prompt for default password
$NewPassword = Read-Host "Enter default password for new users" -AsSecureString

# Path to CSV
$FilePath = ".\UsersFile.csv"
if (-not (Test-Path $FilePath)) {
    Write-Error "CSV file not found at $FilePath"
    exit
}

# Import CSV
$NewADUsers = Import-CSV $FilePath

# Create AD users
foreach ($user in $NewADUsers) {
    try {
        New-ADUser `
            -SamAccountName $user.SamAccountName `
            -Name $user.Name `
            -GivenName $user.FirstName `
            -Surname $user.LastName `
            -DisplayName $user.DisplayName `
            -Title $user.Title `
            -UserPrincipalName $user.UserPrincipalName `
            -EmailAddress $user.Email `
            -EmployeeID $user.EmployeeID `
            -AccountPassword $NewPassword `
            -ChangePasswordAtLogon $true `
            -Enabled $true `
            -PasswordNeverExpires $false `
            -Path $user.OU `
            -PassThru
        Write-Host "Created user: $($user.SamAccountName)"
        # Add to group (if specified)
        if ($user.Group) {
            $groups = $user.Group -split ';'
            foreach ($group in $groups) {
                try {
                    Add-ADGroupMember -Identity $group -Members $user.SamAccountName
                    Write-Host "Added $($user.SamAccountName) to group: $group"
                } catch {
                    Write-Warning "Failed to add $($user.SamAccountName) to group $group : $_"
                }
            }
        }
    } catch {
        Write-Warning "Failed to create user $($user.SamAccountName): $_"
    }
}
