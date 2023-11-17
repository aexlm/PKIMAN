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

    if (-not (Get-Content -Path $Path -ErrorAction Ignore)) {
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
    
    $CSRDump = C:\Windows\System32\certutil.exe -unicode -dump $Path
    
    $Object = (([Regex]::Match($CSRDump,"$global:CSRObject(.*?)$global:CSRHash").Groups[1].Value) -Replace "^\s{5}") -Split "\s{2,}"
    Write-Host -ForegroundColor Green "Objet du CSR indiqué :`n"
    foreach ($FObj in $Object) {
        Write-Host "  $FObj"
    }
    
    Write-Host ""
    
    $ObjectName = ((($Object -Split "\n") -Match "CN=") -Split "=")[-1]
    
    if ($CSRDump -match "2.5.29.17") {        
        $Groups = [Regex]::Match($CSRDump,"$global:CSRSAN(.*?)([a-zA-Z0-9])\s{2,8}[a-zA-Z0-9]").Groups
        $RawSAN = (($Groups[1].Value + $Groups[2].Value) -Replace "^\s+") -Split "\s{2,}"
    
        if ($RawSAN) {
            Write-Host -ForegroundColor Green "SAN renseignés dans le CSR :`n"
            foreach ($FSan in $RawSAN) {
                Write-Host "  $FSan"
            }            
        } else {
            Write-Host -ForegroundColor Yellow "SAN renseignés dans le CSR mais illisibles."
        }        
    } else {
        Write-Host -ForegroundColor Yellow "Aucun SAN renseigné dans le CSR."
    }
    
    return $ObjectName, $Path
}