Add-Type -AssemblyName System.Windows.Forms

#Définition des variables globales pour les opérations 'match'
switch ((Get-UICulture).Name) {
    "en-US" {
        $global:CSRObject = "Subject:"
        $global:CSRHash = "Name Hash"
        $global:CSRSAN = "Subject Alternative Name"
        $global:ConfigStr = "Config"
        $global:AutoEnrollStr = "Auto-Enroll"
        $global:RequestIdStr = "RequestID"
        $global:PendingStr = "pending"
        $global:DeniedStr = "Denied"
        $global:ErrorStr = "Error"
        $global:CurrentUserStr = "CurrentUser"
        $global:ExportPKExcpetionStr = "Export"
        $global:GetPKExcpetionStr = "GetRSAPrivateKey"
    }
    "fr-FR" {
        $global:CSRObject = "Objet:"
        $global:CSRHash = "Hachage"
        $global:CSRSAN = "Autre nom de l’objet"
        $global:ConfigStr = "Config"
        $global:AutoEnrollStr = "Inscription automatique"
        $global:RequestIdStr = "IDDemande"
        $global:PendingStr = "en attente"
        $global:DeniedStr = "Denied"
        $global:ErrorStr = "Error"
        $global:CurrentUserStr = "CurrentUser"
        $global:ExportPKExcpetionStr = "Export"
        $global:GetPKExcpetionStr = "GetRSAPrivateKey"
    }
}

$ExcludedModules = @()

if (Get-Module "PSPKI") {    
    $Import = $true
} else {
    try {
        Import-Module "PSPKI" -ErrorAction Stop
        $Import = $true
    } catch {
        $Import = $false
    }
}

if ($Import) {
    #Import PSPKIInstalled, exclude imported Modules from next import
    $PSPKIInstalledModules = Get-ChildItem -Path "$PSScriptRoot`\PSPKIInstalled" -Include *.ps1 -Recurse
    foreach ($Module in $PSPKIInstalledModules) {
        . $Module.FullName
        $ExcludedModules += $Module.FullName -replace "PSPKIInstalled", "PSPKINotInstalled"
    }
}

if (-not $Import) {
    #Définition du masque des droits d'accès sur les autorités de cetification
    [Flags()] Enum CAAccessMask {
        ManageCA = 1
        ManageCertificates = 2
        Read = 256
        Enroll = 512
    }    
}

Get-ChildItem -Path "$PSScriptRoot`\PSPKINotInstalled" -Include *.ps1 -Recurse | Where-Object { $ExcludedModules -notcontains $_.FullName } | Foreach-Object { . $_.FullName }

Export-ModuleMember -Function @(Get-ChildItem "$PSScriptRoot`\PSPKINotInstalled" -Include *.ps1 -Recurse | ForEach-Object {$_.Name -replace ".ps1"})