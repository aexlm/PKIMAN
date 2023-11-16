<#
    .SYNOPSIS
    Installe le certificat récupérer dans le magasin choisi.

    .DESCRIPTION
    Importe le certificat dans le magasin défini et le lie à sa clé privée.
    La fonction utilisée pour réaliser l'import ne fait pas le lien par défaut.
    La fonction est donc appelée une seconde fois pour créer ce lien.

    .PARAMETER CERFile
    L'emplacement du certificat.

    .PARAMETER Store
    Le magasin dans lequel installer le certificat.
#>
function Install-Cert {
    param(
        [String]
        $CERFile,

        [String]
        $Store
    )

    try {
        $CertObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $CERFile

        if (Get-ChildItem "$Store\$($CertObject.Thumbprint)" -ErrorAction Ignore) {

            if (-not [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($(Get-ChildItem "$Store\$($CertObject.Thumbprint)")[0])) {
                $ShortStore = ($Store -split '\\')[-1]
                if ($Store -match $global:CurrentUserStr) {
                    C:\Windows\System32\certutil.exe -user -repairstore $ShortStore $CertObject.Thumbprint > $null
                } else {
                    C:\Windows\System32\certutil.exe -repairstore $ShortStore $CertObject.Thumbprint > $null
                }
            }
            Write-Host "Certificat portant l'empreinte $($CertObject.Thumbprint) installé dans le magastin $Store`n"   
            return $CertObject.Thumbprint
        } else {
            Write-Host "Installation du certificat dans le store de l'utilisateur actuel."
            Import-Certificate -FilePath $CERFile -CertStoreLocation $Store > $null
            return $null
        }
    } catch {
        Write-Host -ForegroundColor Red "Une erreur est survenue avec le fichier $CERFile, il ne peut pas être lu."
        exit
    }    
}