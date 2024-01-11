function Get-AvailableTemplates {
    param(
        [String]
        $TargetCA,

        [Switch]
        $UseMachine
    )

    #Get templates
    if ($TargetCA) {
        $TargetCA = $TargetCA -replace '"'
        $CAName = $TargetCA.Split('\')[1]
    } else {
        try {
            $CAName = Get-ItemPropertyValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration' -Name 'Active' -ErrorAction Stop
        } catch [System.Management.Automation.ItemNotFoundException] {
            Write-Host -ForegroundColor Red "Erreur : Il n'y a pas d'autorité de certification d'installée sur la machine locale.`nVeuillez réessayer en spécifiant le paramètre -TargetCA."
        }
    }

    $ConfigContext = "CN=Enrollment Services,CN=Public Key Services,CN=Services," + $(([ADSI]"LDAP://RootDSE").configurationNamingContext)
    $Filter = "CN=$CAName"    
    $Templates = (New-object System.DirectoryServices.DirectorySearcher([ADSI]"LDAP://$ConfigContext","$Filter")).FindOne().Properties.certificatetemplates

    $IDs = @()
    if ($UseMachine) {
        $Account = New-Object System.Security.Principal.WindowsIdentity -ArgumentList $(C:\Windows\System32\HOSTNAME.EXE)
    } else {
        $Account = [Security.Principal.WindowsIdentity]::GetCurrent()
    }

    $IDs = @()

    foreach ($Group in $Account.Groups) {
        try {
            $IDs += $Group.Translate([System.Security.Principal.NTAccount])
        } catch [System.Management.Automation.MethodInvocationException] {
            continue
        }
    }

    $IDs += $Account.Name    

    $ConfigContext = "CN=Certificate Templates,CN=Public Key Services,CN=Services," + $(([ADSI]"LDAP://RootDSE").configurationNamingContext)
    $AvailableTemplates = @()
    $ErrorTemplates = @()

    foreach ($Template in $Templates) {
        $IDReferences = @()
        $Filter = "(CN=$Template)"
        $Search = New-object System.DirectoryServices.DirectorySearcher([ADSI]"LDAP://$ConfigContext",$filter)

        try {
            $ADTemplate = $Search.Findone().GetDirectoryEntry() | ForEach-Object { $_ }
        } catch [System.Management.Automation.RuntimeException] {
            $ErrorTemplates += $Template
            continue
        }

        $IDReferences = ($ADTemplate.ObjectSecurity.Access | 
            Where-Object {$_.ObjectType.Guid -eq "0e10c968-78fb-11d2-90d4-00c04f79dc55" -and $_.AccessControlType -eq "Allow"} | 
            Select-Object -Property IdentityReference -Unique).IdentityReference 
        
        if ($IDReferences) {
            if (Compare-Object -ReferenceObject $IDReferences -DifferenceObject $IDs -IncludeEqual -ExcludeDifferent) {
                $AvailableTemplates += $Template
            }
        }        
    }

    return $AvailableTemplates, $ErrorTemplates
}