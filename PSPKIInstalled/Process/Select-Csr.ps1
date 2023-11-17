<#
    .SYNOPSIS
    Sélectionne une requête de certificat existante.

    .DESCRIPTION
    Cette fonction permet d'indiquer et de sélectionner un CSR à transmettre à l'autorité de certification voulue.
    Une fois le chemin du fichier indiqué, cette fonction affiche différentes informations concernant la requête :
    - Son sujet
    - Ses noms alternatifs (s'ils sont indiqués)
    Cette fonction retourne le nom de l'objet indiqué dans la requête, ainsi que le chemin du fichier ouvert.

    .PARAMETER Path
    L'emplacement du fichier de demande.
    Si ce paramètre n'est pas renseigné, une boîte de dialogue va s'ouvrir pour sélectionner le fichier.

    .PARAMETER InitialDirectory
    Le répertoire par défaut à ouvrir pour sélectionner le fichier.
    Si aucune valeur n'est indiquée, ouvre le répertoire courrant.
#>
function Select-Csr {
    param(
        [String]
        $Path,    

        [String]
        $InitialDirectory
    )

    $CSRFile = Get-Content -Path $Path -ErrorAction SilentlyContinue

    if (-not $CSRFile) {
        $OpenDialog = [System.Windows.Forms.OpenFileDialog]@{
            InitialDirectory = $InitialDirectory
            Filter = "CSR (*.csr;*.req)|*.csr;*.req|All files (*.*)|*.*"
        }
        if ($OpenDialog.ShowDialog() -eq 'OK') {
            $Path = $OpenDialog.FileName
        } else {
            Write-Host -ForegroundColor Yellow "Aucune requête sélectionnée, fermeture du programme."        
            return
        }
    }
    
    $CSR = Get-CertificateRequest -Path $Path
    
    $Object = $CSR.Subject -split '\s'
    Write-Host -ForegroundColor Green "Objet du CSR indiqué :`n"
    foreach ($FObj in $Object) {
        Write-Host "  $FObj"
    }
    
    Write-Host ""
    
    $ObjectName = (($Object -Match "CN=") -Split "=")[-1]
    
    $SanOid = (Get-ObjectIdentifierEx -Value "Subject Alternative Name").Value
    $SanExtension = $CSR.Extensions | Where-Object { $_.Oid.Value -eq $SanOid }

    if ($SanExtension) {
        Write-Host -ForegroundColor Green "SAN renseignés dans le CSR :`n"
        foreach ($San in $SanExtension.AlternativeNames) {
            Write-Host "  $($San.Type) : $($San.Value)"
        }   
    } else {
        Write-Host -ForegroundColor Yellow "Aucun SAN renseigné dans le CSR."
    }
    
    return $ObjectName, $Path
}