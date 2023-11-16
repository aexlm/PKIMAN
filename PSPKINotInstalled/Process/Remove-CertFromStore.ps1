<#
    .SYNOPSIS
    Supprime le certificat du magasin de l'utilisateur.

    .DESCRIPTION
    Une fois l'export du certificat terminé, il peut être nécessaire de le supprimer du magasin dans lequel il a été initialement installé.
    Cette opération ne détruit pas la clé privée qui lui est associé.

    .PARAMETER Thumbprint
    L'empreinte du certificat à supprimer.

    .PARAMETER Store
    Le magasin dans lequel se trouve le certificat à supprimer.
#>
function Remove-CertFromStore {
    param(
        [String]    
        $Thumbprint,

        [String]
        $Store
    )

    try {
        Remove-Item -Path "$Store\$Thumbprint"
        Write-Host "Certificat supprimé du magasin."
    } catch {
        Write-Host -ForegroundColor Red "Erreur lors de la suppression du certificat $Thumbprint dans le magasin $Store"
        Write-Host -ForegroundColor Red $_
    }
}