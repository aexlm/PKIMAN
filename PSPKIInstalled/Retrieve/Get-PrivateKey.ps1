<#
    .SYNOPSIS
    Retourne la clé privée d'un certificat.

    .DESCRIPTION
    Cette fonction récupère les informations sur la clé privée d'un certificat donné.
    Ce certificat peut être passé directement en argument. Il est également possible de donner son chemin d'installation.
    Si la clé privée est exportable, elle est retournée au format base64 et mise en forme.
    La mise en forme inclus les balises `BEGIN PRIVATE KEY` et `END PRIVATE KEY`

    .PARAMETER Certificate
    Le certificat dont il faut retourner la clé privée.
    Le type attendu pour cet argument est X509Certificate2.
    Ce paramètre est obligatoire si le chemin du certificat n'est pas spécifié.
    Ce paramètre ne peut pas être utilisé avec les autres paramètres.

    .PARAMETER CertificatThumbprint
    L'empreinte du certificat dont il faut extraire la clé privée.
    Ce paramètre est obligatoire si le paramètre -Certificate n'est pas spécifié.
    Ce paramètre ne peut pas être utilisé si le paramètre -Certificate est spécifié.    

    .PARAMETER Store
    Le magasin dans lequel se trouve le certificat.
    La valeur par défaut de se paramètre est le magasin personnel de l'utilisateur courrant.
    Ce paramètre ne peut être utilisé qu'avec le paramètre -CertficateThumbprint.
#>
function Get-PrivateKey {
    param(
        [Parameter(Mandatory = $true,
        ParameterSetName = 'X509Certificate')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]
        $Certificate,

        [Parameter(Mandatory = $true,
        ParameterSetName = 'CertificatePath')]
        [String]
        $CertificateThumbprint,

        [Parameter(ParameterSetName = 'CertificatePath')]
        [String]
        $Store = "Cert:\CurrentUser\My"        
    )

    if (-not $Certificate) {
        try {
            $Certificate = Get-ChildItem "$Store\$CertificateThumbprint" -ErrorAction Stop
        } catch [System.Management.Automation.ItemNotFoundException] {
            Write-Host -ForegroundColor Yellow "Le chemin spécifié pour le certificat n'existe pas."
            return $null
        }
    }

    try {
        $RSACng = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate)
        $KeyBytes = $RSACng.Key.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
        $KeyBase64 = [System.Convert]::ToBase64String($KeyBytes, [System.Base64FormattingOptions]::InsertLineBreaks)
        return "-----BEGIN PRIVATE KEY-----`n$KeyBase64`n-----END PRIVATE KEY-----`n"        
    } catch [System.Management.Automation.MethodInvocationException] {
        if ($_.Exception -match $global:ExportPKExcpetionStr) {
            Write-Host -ForegroundColor Yellow "La clé privée n'est pas exportable pour le certificat portant l'empreinte $($Certificate.Thumbprint)."
        } elseif ($_.Exception -match $global:GetPKExcpetionStr) {
            Write-Host -ForegroundColor Yellow "Vous ne possédez pas la clé privée pour le certificat portant l'empreinte $($Certificate.Thumbprint)."
        }        
    } catch {
        Write-Host -ForegroundColor Yellow "Une erreur est survenue lors de l'export de la clé privée.`n$_"        
    } 
    return $null
}