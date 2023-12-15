# Importere fra CSV fil, til oprettelse af brugere
# filen SKAL struktures FirstName,LastName,UserName,Password
# Filerne skal placeres I samme mappe
# -Delimiter ';' skal bruges hvis din csv fil bruger ; i stedet for ,
$users = Import-Csv -Path 'Users.csv' -Delimiter ';'
$homeFolderRoot = "C:\shares\homefolder"

# Loop through each user in the CSV file
foreach ($user in $users) {
    # Opret ny AD bruger
    $newUser = New-ADUser -Name "$($user.FirstName) $($user.LastName)" -GivenName $user.FirstName -Surname $user.LastName -SamAccountName $user.UserName -UserPrincipalName "$($user.UserName)@dctrl.ltj.local" -AccountPassword (ConvertTo-SecureString -AsPlainText $user.Password -Force) -Enabled $true -ChangePasswordAtLogon $true -PassThru

    # Hvis brugeren blev oprettet succesfuldt, tilføj til gruppen og opret hjemmemappe
    if ($newUser) {
        # Tilføj brugeren til Gruppen Remote desktop service
        Add-ADGroupMember -Identity 'Remote Desktop Users' -Members $user.UserName -PassThru

        # Opret hjemmemappe
        $homeFolderPath = Join-Path -Path $homeFolderRoot -ChildPath $user.UserName
        New-Item -ItemType Directory -Path $homeFolderPath -Force

        # Indstil NTFS-tilladelser
        $acl = Get-Acl $homeFolderPath
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($user.UserName, "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($accessRule)
        Set-Acl -Path $homeFolderPath -AclObject $acl

        # Opret netværksdeling for hjemmemappen
        $shareName = $user.UserName + "$" # Bruger et $-tegn for at skabe en skjult deling
        $netShareCommand = "net share $shareName=`"$homeFolderPath`" /GRANT:`"$user.UserName,CHANGE`""
        Invoke-Expression $netShareCommand
    }
}

Write-Host "Brugere er oprettet, tilføjet til gruppen, hjemmemapper er oprettet og delt"
