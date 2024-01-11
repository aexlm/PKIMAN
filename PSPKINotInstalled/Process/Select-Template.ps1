<#
    .SYNOPSIS
    Permet de sélectionner le modèle du certificat à demander.

    .DESCRIPTION
    Dans le cas où aucun modèle n'est désignée au moment de l'appel du script, cette fonction est appelée pour que l'utilisateur fasse le choix.
    La liste des templates disponibles pour l'utilisateur est affichée avec pour chacun un numéro attribué.
    L'utilisateur doit indiqué l'index correspondant au modèle qu'il souhaite demander.

    .PARAMETER TargetCA
    L'autorité de certification sélectionnée pour envoyer la demande.
    Seules les modèles distribués par cette autorité seront proposés à l'utilisateur.
#>
function Select-Template {
    param(
        [String]
        $TargetCA,

        [Switch]
        $MachineTemplates
    )

    if ($MachineTemplates) {
        $AvailableTemplates, $ErrorTemplates = Get-AvailableTemplates -TargetCA $TargetCA -UseMachine
    } else {
        $AvailableTemplates, $ErrorTemplates = Get-AvailableTemplates -TargetCA $TargetCA
    }            

    if (-not $AvailableTemplates) {
        Write-Host -ForegroundColor Yellow "Aucun modèle de certificat disponible à la demande.`nFermeture du programme."
        return
    }

    if ($ErrorTemplates) {
        if ($ErrorTemplates.Count -eq 1) {
            Write-Host -ForegroundColor Yellow "Attention, un template distribué par l'autorité $TargetCA est en erreur :"
        } else {
            Write-Host -ForegroundColor Yellow "Attention, plusieurs templates distribués par l'autorité $TargetCA sont en erreur :"
        }
        
        foreach ($ErrTemp in $ErrorTemplates) {
            Write-Host -ForegroundColor Yellow "- $ErrTemp"
        }
    }

    Write-Host "Sélectionner un modèle de certificat disponible :"
    for ($i = 1 ; $i -le $AvailableTemplates.Length ; $i++) {
        Write-Host "$i. $($AvailableTemplates[$i-1])"
    }

    try {
        [int]$Choix = (Read-Host "Choix") - 1
        if (($Choix -lt 0) -or ($Choix + 1 -gt $AvailableTemplates.Length)) { 
            throw 
        } else {
            return $AvailableTemplates[$Choix]
        }
    } catch {
        Write-Host -ForegroundColor Yellow "Choix incorrect, fermeture du programme"       
        return
    } 
}