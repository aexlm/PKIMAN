<#
    .SYNOPSIS
    Permet de sélectionner l'autorité de certification à interroger.

    .DESCRIPTION
    Dans le cas où aucune autorité n'est désignée au moment de l'appel du script, cette fonction est appelée pour que l'utilisateur fasse le choix.
    La liste des autorités disponibles est affichée avec pour chacune un numéro attribué.
    L'utilisateur doit indiqué l'index correspondant à l'autorité qu'il souhaite interroger.
    S'il n'y a qu'une autorité de disponible, elle est automatiquement sélectionnée.
#>

#Requires -Modules @{ ModuleName="PSPKI"; ModuleVersion="4.0.0" }

function Select-TargetCA {

    $AvailableCA = Get-CertificationAuthority | Where-Object { $_.IsAccessible -and $_.ServiceStatus -eq "Running" }

    if (-not $AvailableCA) {
        Write-Host -ForegroundColor Yellow "Aucune autorité de certification joignable actuellement.`nFermeture du programme."
        exit
    } elseif ($AvailableCA.Length -eq 1) {
        return "$($AvailableCA[0].ComputerName)\$($AvailableCA[0].DisplayName)"
    }

    Write-Host "Sélectionner une autorité à interroger :"
    for ($i = 1 ; $i -le $AvailableCA.Length ; $i++) {
        Write-Host "$i. $($AvailableCA[$i-1].ComputerName)\$($AvailableCA[$i-1].DisplayName)"
    }

    try {
        [int]$Choix = (Read-Host "Choix") - 1
        if (($Choix -lt 0) -or ($Choix + 1 -gt $AvailableCA.Length)) { 
            throw 
        } else {
            return "$($AvailableCA[$Choix].ComputerName)\$($AvailableCA[$Choix].DisplayName)"
        }
    } catch {
        Write-Host -ForegroundColor Yellow "Choix incorrect, fermeture du programme"       
        exit
    } 
}