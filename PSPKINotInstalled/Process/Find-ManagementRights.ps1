<#
    .SYNOPSIS
    Vérifie certains droits de l'utilisateur courant.

    .DESCRIPTION
    Cette fonction commence par récupérer l'ACL de sécurité de la CA interrogée.
    Les groupes de l'utilisateur courrant sont ensuite récupérés.
    Si l'un des groupes de l'utilisateur courrant donne le droit 'ManageCertificates', alors la fonction retourne une valeur positive.

    .PARAMETER TargetCA
    L'autorité de certification interogée pour la demande de certificat.
#>

function Find-ManagementRights {
    param(
        [String]
        $TargetCA
    )

    $LocalMachineName = [System.Net.Dns]::GetHostByName($env:computerName).HostName

    if ($TargetCA) {
        $TargetCA = $TargetCA -replace '"'
        $ServerName, $CAName = $TargetCA.Split('\')
    } else {
        $CAName = Get-ItemPropertyValue -Path 'Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration' -Name 'Active'
        $ServerName = $LocalMachineName
    }

    $RegPath = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration\$CAName"

    if ($ServerName -eq $LocalMachineName) {
        $SD_Bin = Get-ItemPropertyValue -Path $RegPath -Name 'Security'
    } else {
        $SD_Bin = Invoke-Command -ComputerName $ServerName -ScriptBlock {Get-ItemPropertyValue -Path $Using:RegPath -Name 'Security'}
    }
    
    $SD = New-Object -TypeName System.Security.AccessControl.CommonSecurityDescriptor -ArgumentList @($false, $false, $SD_Bin, 0)

    $ACL = @()
    foreach ($ACE in $SD.DiscretionaryAcl) {
        $RightsEnum =[CAAccessMask]$ACE.AccessMask
        $Rights = @($RightsEnum.ToString().Split(",",[StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object{$_.Trim()})
        $ACL += @{"SID" = $ACE.SecurityIdentifier; "Rights" = $Rights}
    }

    $CAManagers = ($ACL | Where-Object {$_.Rights -contains "ManageCertificates"}).SID.Value    
    $CurrentUserGroups = [Security.Principal.WindowsIdentity]::GetCurrent().Groups.Value

    return (Compare-Object -ReferenceObject $CAManagers -DifferenceObject $CurrentUserGroups -IncludeEqual -ExcludeDifferent)    
}
