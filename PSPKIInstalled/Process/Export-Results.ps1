<#
    .SYNOPSIS
    Exporte les résultats du script dans un fichier CSV.

    .DESCRIPTION
    D'après les actions s'étant déroulées au cours du script, ces informations sont exportées dans un fichier au format CSV.
    Ces données comprennent :
    - Le sujet du certificat
    - Le template du certificat
    - La date de validité du certificat
    - La date d'expiration du certificat
    - L'autorité de certification ayant distribué le certificat
    - Le numéro de série du certificat
    - Si le certificat a été exporté ou non au format PEM
    - Si le certificat a été exporté ou non au format PFX
    - Si la clé privée du certificat a été ou non supprimée

    .PARAMETER Thumbprint
    L'empreinte du certificat installé.

    .PARAMETER CSVFilePath
    L'emplacement auquel enregistré le fichier des résultats.

    .PARAMETER PFXFilePath
    L'emplacement supposé du certificat au format PFX.

    .PARAMETER PEMFilePath
    L'emplacement supposé du certificat au format PEM.

    .PARAMETER Store
    Le magasin dans lequel le certificat a été installé.

    .PARAMETER DeletedPrivateKey
    Indique si la clé privée a été supprimée.

    .PARAMETER WorkingDirectory
    Le répertoire de travail défini.
#>
function Export-Results {
    param(
        [String]
        $Thumbprint,

        [String]
        $CSVFilePath,

        [String]
        $PFXFilePath,

        [String]
        $PEMFilePath,

        [String]
        $Store,

        [Boolean]
        $DeletedPrivateKey,

        [String]
        $WorkingDirectory
    )

    $ShortStore = ($Store -split '\\')[-1]
    if ($Store -match $global:CurrentUserStr) {
        $CertDump = C:\Windows\System32\certutil.exe -unicode -user -store $ShortStore $Thumbprint
    } else {
        $CertDump = C:\Windows\System32\certutil.exe -unicode -store $ShortStore $CertObject.Thumbprint
    }

    try {
        $SN = (($CertDump -match $global:SerialNumberStr) -split ':')[-1].Trim()
    } catch {
        Write-Host -ForegroundColor Yellow "Impossible d'exporter le numéro de série."
        $SN = "N\A"
    }
    
    try {
        $Issuer = (($CertDump -match $global:IssuerStr) -split ':')[-1].Trim()    
    } catch {
        Write-Host -ForegroundColor Yellow "Impossible d'exporter le nom de l'émetteur."
        $Issuer = "N\A"
    }
    
    try {
        $NotBefore = [DateTime]::ParseExact(
            $((($CertDump -match $global:NotBeforeStr) -split ': ')[-1]),
            "$((Get-Culture).DateTimeFormat.ShortDatePattern) $((Get-Culture).DateTimeFormat.ShortTimePattern)", 
            $null
        )
    } catch {
        Write-Host -ForegroundColor Yellow "Impossible d'exporter la date de début de validité."
        $NotBefore = "N\A"
    }
    
    try {
        $NotAfter = [DateTime]::ParseExact(
            $((($CertDump -match $global:NotAfterStr) -split ': ')[-1]),
            "$((Get-Culture).DateTimeFormat.ShortDatePattern) $((Get-Culture).DateTimeFormat.ShortTimePattern)", 
            $null
        )
    } catch {
        Write-Host -ForegroundColor Yellow "Impossible d'exporter la date d'expiration."
        $NotAfter = "N\A"
    }
    
    try {
        $Subject = (($CertDump -match $global:SubjectStr) -split ':')[-1].Trim()
    } catch {
        Write-Host -ForegroundColor Yellow "Impossible d'exporter le sujet."
        $Subject = "N\A"
    }
    
    try {
        $Template = (($CertDump -match $global:TemplateStr) -split ': ')[-1]
    } catch {
        Write-Host -ForegroundColor Yellow "Impossible d'exporter le modèle."
        $Template = "N\A"
    }
    
    if (Get-Content -Path $PEMFilePath -ErrorAction Ignore) { $PEMExported = $PEMFilePath } else { $PEMExported = "Non" }
    if (Get-Content -Path $PFXFilePath -ErrorAction Ignore) { $PFXExported = $PFXFilePath } else { $PFXExported = "Non" }
    if ($DeletedPrivateKey) { $DelKey = "Oui" } else { $DelKey = "Non" }

    $Export = [PSCustomObject]@{
        "Sujet" = $Subject
        "Template" = $Template
        "Valide à partir de" = $NotBefore.ToString("dd/MM/yyyy HH:mm")
        "Valide jusqu'au" = $NotAfter.ToString("dd/MM/yyyy HH:mm")
        "Distribué par" = $Issuer
        "Numéro de série"= $SN
        "Export en PEM" = $PEMExported
        "Export en PFX" = $PFXExported
        "Clé privée supprimée" = $DelKey
    }

    if (-not $CSVFilePath) {
        $CSVFilePath = "$WorkingDirectory\Results.csv"
        $Choice = Read-Host "Le chemin de sauvegarde par défaut est $CSVFilePath, souhaitez-vous le modifier ? (Y/N)"
        if ($Choice.ToLower() -ne 'n') {
            $SaveDialog = [System.Windows.Forms.SaveFileDialog]@{
                InitialDirectory = $WorkingDirectory
                Filter = "CSV (*.csv)|*.csv"
            }
            if ($SaveDialog.ShowDialog() -eq 'OK') {
                $CSVFilePath = $SaveDialog.FileName
            }
        }
    }

    try {
        $Export | Export-Csv -Path $CSVFilePath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        Write-Host "Résultats sauvegardés dans le fichier $CSVFilePath`n"
        $Export | Format-List
    } catch {
        Write-Host -ForegroundColor Red "Erreur lors de l'export des résultats"
        Write-Host -ForegroundColor Red $_
    }
}