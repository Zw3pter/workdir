# Importere fra CSV fil, til oprettelse af brugere
# Filen SKAL struktures med kolonnerne: FirstName,LastName,Title,UserName,Company,Initials,Office,Password
# Filerne skal placeres I samme mappe
# -Delimiter ';' skal bruges hvis din csv fil bruger ; i stedet for ,
$users = Import-Csv -Path 'Users.csv' -Delimiter ';'
$homeFolderRoot = "C:\shares\homefolder"

# Loop through each user in the CSV file
foreach ($user in $users) {
    # Opret ny AD bruger
    $newUser = New-ADUser -Name "$($user.FirstName) $($user.LastName)" `
                          -GivenName $user.FirstName `
                          -Surname $user.LastName `
                          -SamAccountName $user.UserName `
                          -UserPrincipalName "$($user.UserName)@dctrl.ltj.local" `
                          -AccountPassword (ConvertTo-SecureString -AsPlainText $user.Password -Force) `
                          -Enabled $true `
                          -Title $user.Title `
                          -Company $user.Company `
                          -Initials $user.Initials `
                          -Office $user.Office `
                          -ChangePasswordAtLogon $true `
                          -PassThru

    # Vent og tjek om brugeren er blevet oprettet
    Start-Sleep -Seconds 5
    $userExists = Get-ADUser -Filter { SamAccountName -eq $user.UserName }

    # Hvis brugeren blev oprettet succesfuldt og eksisterer i AD, fortsæt med at konfigurere
    if ($userExists) {
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
    } else {
        Write-Warning "Brugeren $($user.UserName) blev ikke fundet i AD. Kontroller oprettelsesprocessen."
    }
}

Write-Host "Brugere er oprettet, tilføjet til gruppen, hjemmemapper er oprettet og delt"
