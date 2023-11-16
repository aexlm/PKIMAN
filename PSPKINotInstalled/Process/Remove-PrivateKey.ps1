<#
    .SYNOPSIS
    Supprime la clé privée du contexte utilisateur.

    .DESCRIPTION
    Une fois le certificat exporté avec sa clé privée, il peut être nécessaire de supprimer la clé privée.
    Par défaut, le certificat est demandé depuis le contexte utilisateur, la clé privée est donc liée à son compte.
    Afin de ne pas garder en mémoire la clé, cette fonction permet de la supprimer.

    .PARAMETER Thumbprint
    L'empreinte du certificat pour lequel il faut supprimer la clé privée associée.

    .PARAMETER Store
    Le magasin dans lequel se trouve le certificat.
#>
function Remove-PrivateKey {
    param(
        [String]
        $Thumbprint,

        [String]
        $Store
    )

    $ShortStore = ($Store -split '\\')[-1]
    if ($Store -match $global:CurrentUserStr) {
        $CertDump = C:\Windows\System32\certutil.exe -unicode -user -store $ShortStore $Thumbprint
    } else {
        $CertDump = C:\Windows\System32\certutil.exe -unicode -store $ShortStore $Thumbprint
    }

    #A vérifier
    $KeyIdentifier = (($CertDump -match $global:KeyContainerStr) -split '[:=]')[-1].Trim()

    if ($Store -match $global:CurrentUserStr) {
        Write-Host "Commande pour supprimer la clé privée : certutil -user -delkey $KeyIdentifier`n"
    } else {
        Write-Host "Commande pour supprimer la clé privée : certutil -delkey $KeyIdentifier`n"
    }

    Write-Host -ForegroundColor Yellow "Attention, il n'y a pas de retour en arrière possible.`nCette action doit être effectuée une fois la clé privée exportée."
    $Choice = Read-Host "Procéder à la suppression ? (Y/N)"

    if ($Choice.ToLower() -eq 'y') {
        C:\Windows\System32\certutil.exe -user -delkey $KeyIdentifier > $null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "La clé privée $KeyIdentifier correspondant au certificat $Thumbprint a été supprimée."
            return $true
        }
    }

    return $false
}