<#
    .SYNOPSIS
    Construit le sujet du certificat.

    .DESCRIPTION
    D'après les informations données en entré du script, cette fonction construit le sujet.
    Le nom de l'objet est le seul attribut obligatoire.
    Sont ensuite demandés si non renseignés les attributs suivant :
    - OU
    - Email
    - Organisation
    - Localisation
    - Région
    - Pays

    .PARAMETER ObjectName
    Le nom du sujet pour lequel ce certificat est destiné.

    .PARAMETER OrganizationalUnit
    Le nom de l'unité d'organisation distribuant le certificat.

    .PARAMETER Email
    Le mail du responsable distribuant le certificat.

    .PARAMETER Organisation
    Le nom de l'Organisation distribuant le certificat.

    .PARAMETER Localisation
    La ville depuis laquelle le certificat est distribué.

    .PARAMETER Region
    La région depuis laquelle le certificat est distribué.

    .PARAMETER Pays
    Le pays depuis lequel le certificat est distribué.
#>
function Get-Subject {
    param(
        [String]
        $ObjectName,

        [String]
        $OrganizationalUnit,
    
        [String]
        $Email,

        [String]
        $Organisation,

        [String]
        $Localisation,

        [String]
        $Region,

        [String]
        $Pays
    )

    if (-not $ObjectName) {
        $ObjectName = Read-Host "Spécifier un sujet pour formuler la demande de certificat "
        if (-not $ObjectName) {
            Write-Host -ForegroundColor Red "Le sujet ne peut pas être vide.`nFermeture du programme."
            exit
        }
    }

    $Subject = "CN=$ObjectName"

    if (-not $OrganizationalUnit -or -not $Email -or -not $Organisation -or -not $Localisation -or -not $Region -or -not $Pays) {
        Write-Host "Définition des attributs complémentaires.`nLaissez vide si l'attribut n'est pas souhaité."
    }    

    if (-not $Organisation) {
        $Organisation = Read-Host "Organisation"
    }
    if ($Organisation) {
        $Subject += ",O=$Organisation"
    }

    if (-not $OrganizationalUnit) {
        $OrganizationalUnit = Read-Host "OU"
    }
    if ($OrganizationalUnit) {
        $Subject += ",OU=$OrganizationalUnit"
    }

    if (-not $Email) {
        $Email = Read-Host "Email"
    }
    if ($Email) {
        $Subject += ",E=$Email"
    }

    if (-not $Localisation) {
        $Localisation = Read-Host "Localisation"
    }
    if ($Localisation) {
        $Subject += ",L=$Localisation"
    }
    
    if (-not $Region) {
        $Region = Read-Host "Région"
    }
    if ($Region) {
        $Subject += ",S=$Region"
    }
    
    if (-not $Pays) {
        $Pays = Read-Host "Pays"
    }
    if ($Pays) {
        $Subject += ",C=$Pays"
    }
    
    return $Subject
}