<#
    .SYNOPSIS
    Exporte le certificat au format PFX.

    .DESCRIPTION
    Utilise la fonction d'export du certificat native à Powershell avec la clé privée.
    Si l'utilisateur n'a pas les droits d'écriture sur le chemin de destination, le fichier sera enregistré dans le Working Directory.

    .PARAMETER CertificateThumbprint
    L'empreinte du certificat à exporter.

    .PARAMETER Store
    Le magasin dans lequel est installé le certificat.

    .PARAMETER PFXFilePath
    Indique le chemin d'export du fichier créé par la fonction.

    .PARAMETER WorkingDirectory
    Le répertoire défini au lancement du programme définissant l'emplacement par défaut des fichiers créés.

    .PARAMETER Password
    Indique le mot de passe protégeant la clé privée du certificat une fois exportée.
    Il peut être passé lors de l'appel du script avec le paramètre -PfxPassword.
    Cependant, il s'agit d'un type [SecureString], si la valeur passée n'est pas de ce type, le programme ne pourra pas se lancer.
    Le mot de passe peut-être vide mais celà peut causer une faille de sécurité.
#>
function Export-Pfx {
    param(
        [String]
        $CertificateThumbprint,

        [String]
        $Store,

        [String]
        $PFXFilePath,        

        [String]
        $WorkingDirectory,

        [SecureString]
        $Password
    )

    Write-Host "Export en PFX..."

    if (-not $Password) {
        $Password = Read-Host -AsSecureString -Prompt "Mot de passe du PFX"
    }

    try {
        Get-ChildItem -Path "$Store\$CertificateThumbprint" -ErrorAction Stop | Export-PfxCertificate -ChainOption 'BuildChain' -Password $Password -FilePath $PFXFilePath -ErrorAction Stop > $null
        Write-Host "Résultats exportés dans : $PFXFilePath`n"
    } catch [System.UnauthorizedAccessException] {
        Write-Host -ForegroundColor Red "Droits utilisateurs insuffisants pour écrire à l'emplacement $PFXPathFile"
        Write-Host "Export dans le dossier $WorkingDirectory"
        $PFXFileName = ($PFXFilePath -split '\\')[-1]
        $PFXPathFile = "$WorkingDirectory\$PFXFileName"
        Get-ChildItem -Path "$Store\$CertificateThumbprint" -ErrorAction Stop | Export-PfxCertificate -ChainOption 'BuildChain' -Password $Password -FilePath $PFXFilePath -ErrorAction Stop > $null
    } catch [System.ComponentModel.Win32Exception] {
        Write-Host -ForegroundColor Yellow "Impossible d'exporter la clé privé de ce certificat."
    } catch {
        Write-Host -ForegroundColor Red "Erreur lors de l'export en PFX."
        Write-Host -ForegroundColor Red $_
    }    
}