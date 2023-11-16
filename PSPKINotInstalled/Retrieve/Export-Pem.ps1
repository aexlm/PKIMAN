<#
    .SYNOPSIS
    Exporte le certificat au format PEM.

    .DESCRIPTION
    La chaine de certificats est construite à partir de l'emplacement du certificat indiqué.
    Les données du certificat sont ensuite extraite à l'aide de fonction .NET.
    Le fichier est mis en forme en indiquant le début et la fin des certificats à l'aide des balises 'BEGIN CERTIFICATE' et 'END CERTIFICATE'.
    L'ordre des certificats est : Certificat délivré > Certificat Intermédiaire > Certificat Racine.
    Si la clé privée est exportée, elle est indiquée au début du fichier.

    .PARAMETER CertificateThumbprint
    L'empreinte du certificat à exporter.

    .PARAMETER Store
    Le magasin dans lequel est installé le certificat.

    .PARAMETER IncludePrivateKey
    Indique si la clé privée doit être exportée avec le certificat.
    Cette option peut être définie lors de l'appel du script avec le paramètre -ExportPrivateKey.
    Si le paramètre n'est pas spécifié, l'utilisateur est interrogé.

    .PARAMETER PEMPathFile
    Indique le chemin d'export du fichier créé par la fonction.
#>
function Export-Pem {
    param(
        [String]
        $CertificateThumbprint,

        [String]
        $Store,

        [String]
        $PEMPathFile
    )

    $Cert = Get-ChildItem "$Store\$CertificateThumbprint"
    $Chain = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Chain
    Write-Host "Export en PEM..."

    $Chain.Build($Cert) > $null

    $PEM = @()

    foreach ($Crt in $Chain.ChainElements) {
        $CertData = [System.Convert]::ToBase64String($Crt.Certificate.RawData, [System.Base64FormattingOptions]::InsertLineBreaks)
        $PEM += "-----BEGIN CERTIFICATE-----`n$CertData`n-----END CERTIFICATE-----`n"
    }

    if ((Read-Host "Inclure la clé privé ? (Y/N)").ToLower() -eq 'y') {    
        $KeyPEM = Get-PrivateKey -Certificate $Cert     
        $PEM = ,$KeyPEM + $PEM     
    } 

    try {
        $PEM | Out-File -FilePath $PEMPathFile
    } catch [System.UnauthorizedAccessException] {
        Write-Host -ForegroundColor Red "Droits utilisateurs insuffisants pour écrire à l'emplacement $PEMPathFile"
        Write-Host "Export dans le dossier $WorkingDirectory"
        $PEMPathFile = "$WorkingDirectory\$PEMFileName"
        $PEM | Out-File -FilePath $PEMPathFile
    }    

    Write-Host "Résultats exportés dans : $PEMPathFile`n"
}