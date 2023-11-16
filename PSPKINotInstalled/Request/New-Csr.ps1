<#
    .SYNOPSIS
    Construit le fichier de requête du certificat.
    
    .DESCRIPTION
    Utilise le fichier de configuration pour créer le fichier de demande.

    .PARAMETER PolicyFile
    L'emplacement du fichier de configuration.

    .PARAMETER CSRFile
    L'emplacement où enregistrer le fichier de demande.

    .PARAMETER UseMachine
    Indique s'il faut utiliser le paramètre -machine lors de la construction du CSR.
#>
function New-Csr {
    param(
        [String]
        $PolicyFile,

        [String]
        $CSRFile,

        [Boolean]
        $UseMachine
    )

    if ($UseMachine) {
        C:\Windows\System32\certreq.exe -machine -new $PolicyFile $CSRFile > $null    
    } else {
        C:\Windows\System32\certreq.exe -user -new $PolicyFile $CSRFile > $null
    }    
}