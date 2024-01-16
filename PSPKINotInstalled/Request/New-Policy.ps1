<#
    .SYNOPSIS
    Construit le fichier de configuration préalable à la demande de certificat

    .DESCRIPTION
    Le fichier de configuration créé par cette fonction contient les informations suivantes :
    - Le sujet présent sur le certificat final
    - La taille de la clé utilisée
    - La mention de l'exportabilité de la clé privée
    De plus, c'est dans ce fichier que sont définis les SAN (Subject Alternate Names).

    .PARAMETER San
    Défini les sujets alternatifs pour le certificat.

    .PARAMETER FilePath
    Défini l'emplacement dans lequel enregistré le fichier de configuration.

    .PARAMETER Subject
    Défini le sujet du certificat.

    .PARAMETER KeyLength
    Spécifie la taille de la clé.
    Les valeurs possibles sont 1024, 2048, 4096, 8192, 16384.
    Si non spécifié dans le fichier, la valeur par défaut est de 1024.
    La valeur par défaut est 2048.

    .PARAMETER ExportableKey
    Indique si la clé privée peut être exportée une fois le certificat délivré.
    Par défaut la valeur est à false.
    
    .PARAMETER InstallMachine
    Spécifie si le certificat est à destination de l'ordinateur depuis lequel le script est exécuté.
#>
function New-Policy {
    param(
        [String]
        $San,

        [String]
        $FilePath = ".\Policy.inf",

        [String]
        $Subject,

        [Int]
        $KeyLength = 2048,

        [Boolean]
        $ExportableKey,

        [Boolean]
        $InstallMachine,

        [String]
        $HashAlgorithm
    )    

    if (-not $ExportableKey -and -not $InstallMachine) {    
        $ExportQ = Read-Host "Souhaitez vous rendre la clé privée exportable ? (Y/N)"
        if ($ExportQ.ToLower() -eq 'y') {
            $ExportableKey = $True
        }
    }

    #Vérifie si la taille de clé indiquée est cohérente
    if ($KeyLength -notin @(1024, 2048, 4096, 8192, 16384)) {
        Write-Host -ForegroundColor Yellow "La valeur $KeyLength n'est pas acceptée comme taille de clé.`nLes tailles possibles sont : 1024, 2048 et 4096."
        $KeyLength = 2048
        Write-Host "La taille de clé choisie par défaut est : $KeyLength."
    }

    $Policy = "[Version]`nSignature=`"`$Windows NT`$`"`n`n[NewRequest]`nSubject=`"$Subject`"`nKeyLength=$KeyLength"

    if ($ExportableKey) {
        $Policy += "`nExportable=true"
    }

    if ($InstallMachine) {
        $Policy += "`nMachineKeySet=true"
    }

    $Algo = Select-HashAlgorithm -HashAlgorithm $HashAlgorithm
    $Policy += "`nHashAlgorithm=$Algo"

    $CN = ((($Subject -split ",") -match "CN=") -split "=")[-1]
    if (-not $San) {
        try {
            Write-Host "Tentative de résolution DNS pour construire le SAN..."
            $Lookup = Resolve-DnsName $CN -ErrorAction Stop
            $Hostnames = @()
            $IpAddresses = @()
            $San = "dns=$CN"

            foreach ($Row in $Lookup) {
                if ($Row.Type -ne "SOA" -and $Row.Name -notin $Hostnames -and $Row.Name -ne $CN) {
                    $Hostnames += $Row.Name
                }
                if ($Row.Type -eq "CNAME" -and $Row.NameHost -notin $Hostnames -and $Row.Name -ne $CN) {
                    $Hostnames += $Row.NameHost                    
                } 
                if ($Row.Type -eq "A" -and $Row.IP4Address -notin $IpAddresses) {
                    $IpAddresses += $Row.IP4Address
                }
            }

            foreach ($Name in $Hostnames) {
                $ShortName = ($Name -split '\.')[0]
                if ($ShortName -notin $Hostnames -and $ShortName -ne $CN ) {
                    $Hostnames += $ShortName
                }
            }
            
            $Hostnames = $Hostnames | Sort-Object

            foreach ($Name in $Hostnames) {
                $San += "&dns=$Name"
            }
            foreach ($IpAddress in $IpAddresses) {
                $San += "&ipaddress=$IpAddress"
            }

            Write-Host -ForegroundColor Green "SAN construit : $SAN"
            $Choice = Read-Host "Le garder ? (Y/N)"
            if ($Choice.ToLower() -ne 'y') {
                $Choice = "denied"
                throw
            }
        } catch {
            if ($Choice -ne "denied") {
                Write-Host "Echec de la résolution automatique"
            }
            Write-Host "`nRappel syntaxique pour les SAN : dns=www.exemple.com&ipaddress=0.0.0.0"
            $San = Read-Host "Entrer le SAN souhaité (laisser vide autrement)"
        }
    }    

    if ($San) {
        $Policy += "`n`n[Extensions]`n2.5.29.17 = {text}"
        $SplitSan = $San -split '&'
        for ($i = 0 ; $i -lt $SplitSan.Length ; $i++) {
            $Policy += "`n_continue_ = `"$($SplitSan[$i])"
            
            if ($i + 1 -lt $SplitSan.Length) {
                $Policy += "&"
            }
            $Policy += "`""
        }        
    }

    $Policy | Out-File -FilePath $FilePath
}    