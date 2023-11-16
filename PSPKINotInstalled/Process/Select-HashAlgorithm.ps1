<#
    .SYNOPSIS
    Permet de sélectionner l'algorithme de hashage à utiliser.

    .DESCRIPTION
    La fonction commence par récupérer la liste des algorithmes disponibles via certutil.
    Le choix est ensuite donné à l'utilisateur.
    Il est possible de passer en argument l'algorithme souhaité. Si la valeur indiquée n'appartient pas à la liste, l'utilisateur doit faire un choix.

    .PARAMETER HashAlgorithm
    L'algorithme de hashage souhaité.
#>
function Select-HashAlgorithm {
    param(
        [String]
        $HashAlgorithm
    )

    $Algos = ((((((C:\Windows\System32\certutil.exe -unicode -oid 1) -match "pwszCNGAlgid") -notmatch "CryptOIDInfo") -split "=") -notmatch "pwszCNGAlgid").Trim() | Select-Object -Unique)

    if ($HashAlgorithm -notin $Algos) {
        Write-Host "Sélectionner l'algorithme de hashage de la requête (par défaut SHA256) :"
        for ($i = 1 ; $i -le $Algos.Length ; $i++) {
            Write-Host "$i. $($Algos[$i-1])"
        }

        try {
            [int]$Choix = (Read-Host "Choix") - 1
            if (($Choix -lt 0) -or ($Choix + 1 -gt $Algos.Length)) { 
                throw 
            } else {
                $HashAlgorithm = $Algos[$Choix]
            }
        } catch {
            Write-Host -ForegroundColor Yellow "Choix incorrect, sélection de l'algorithme par défaut."
            $HashAlgorithm = ($Algos | Where-Object {$_ -eq "SHA256"})
        } 
    }
    
    return $HashAlgorithm
}