<#
    .SYNOPSIS
    Exporte la clé privée d'un certificat.

    .DESCRIPTION
    D'après le chemin donné d'un certificate installé, exporte sa clé privée dans le fichier spécifié.

    .PARAMETER CertificatThumbprint
    L'empreinte du certificat dont il faut extraire la clé privée.

    .PARAMETER Store
    Le magasin dans lequel se trouve le certificat.

    .PARAMETER PrivateKeyFilePath
    Le fichier dans lequel extraire la clé privée.
#>
function Export-PrivateKey {
    param(
        [String]
        $CertificateThumbprint,

        [String]
        $Store,

        [String]
        $PrivateKeyFilePath
    )

    $Key = Get-PrivateKey -CertificateThumbprint $CertificateThumbprint -Store $Store

    if ($Key) {
        $Key | Out-File -FilePath $PrivateKeyFilePath -Encoding utf8
        Write-Host "Clé privée exportée dans : $PrivateKeyFilePath`n"
    }
}