<#
    .SYNOPSIS
    Demande et récupère le certificat voulu.

    .DESCRIPTION
    Au premier passage dans cette fonction, le fichier de demande est envoyé à l'autorité de certification sélectionnée.
    Si le certificat est directement délivré, il est enregistré immédiatement.
    Autrement, un fichier temporaire est créé (.rsp), indiquant que la demande a été faite mais que le certificat n'a pas été délivré.
    Dans ce fichier est également enregitré l'identifiant de la demande.
    Pour les passages suivants, le fichier .RSP est lu afin de récupérer l'identifiant et une nouvelle tentative est proposé à l'utilisateur.
    Plusieurs cas sont alors possibles :
    - Le certificat a été délivré, il est alors enregistré.
    - Le certificat est toujours en attente, l'utilisateur est informé et peut actionner une nouvelle tentative.
    - Le certificat a été refusé, l'utilisateur en est informé et le programme se termine.
    - Une erreur est survenue, l'identifiant peut-être incorrect ou une erreur est survenue au moment de la demande, idem qu'en cas de refus.

    .PARAMETER CSRFile
    L'emplacement du fichier de demande (.req)

    .PARAMETER TargetCA
    L'autorité de certification à interroger.

    .PARAMETER CertificateTemplate
    Le modèle sélectionné pour le certificat demandé.

    .PARAMETER CERFile
    L'emplacement dans lequel est sauvegardé le certificat au moment de sa récupération.

    .PARAMETER RequestId
    L'identifiant de la demande.

    .PARAMETER UseMachine
    Indique s'il faut utiliser le paramètre -AdminForceMachine lors de la soumission de la requête.
#>
function New-Cer {
    param(
        [String]
        $CSRFile,

        [String]
        $TargetCA,

        [String]
        $CertificateTemplate,

        [String]
        $CERFile,

        [Int]
        $RequestId,

        [Boolean]
        $UseMachine
    )
    
    $FileName = ($CERFile -split "\.cer$")[0]
    $RSPFile = $FileName + ".rsp"    

    if (-not $TargetCA) {
        $TargetCA = Select-TargetCA
        if (-not $TargetCA) { return }
    }

    Write-Host "Autorité de certification à interroger : $TargetCA"

    if (-not (Get-Content -Path $RSPFile -ErrorAction Ignore) -and -not $RequestId) {
        if (-not $CertificateTemplate) {
            if ($UseMachine) {
                $CertificateTemplate = Select-Template -TargetCA $TargetCA -MachineTemplates
            } else {
                $CertificateTemplate = Select-Template -TargetCA $TargetCA
            }            
        }

        if (-not $CertificateTemplate) { return }

        if ($UseMachine) {
            $Submit = C:\Windows\System32\certreq.exe -unicode -submit -AdminForceMachine -config "$TargetCA" -attrib "CertificateTemplate:$CertificateTemplate" $CSRFile $CERFile
        } else {
            $Submit = C:\Windows\System32\certreq.exe -unicode -submit -config "$TargetCA" -attrib "CertificateTemplate:$CertificateTemplate" $CSRFile $CERFile
        }
        Start-Sleep 1        

        if (-not (Get-Content -Path $CERFile -ErrorAction Ignore)) {     
            $RequestId = ((($Submit -match $global:RequestIdStr) -split ':')[1] -replace '[«»]').Trim()

            $("$global:RequestIdStr : $RequestId", (Get-Content -Path $RSPFile)) | Set-Content -Path $RSPFile

            Write-Host "Le certificat est en attente de validation."
            Write-Host "La demande pour ce certificat porte l'identifiant $RequestId. Cet identifiant est enregistré dans le fichier $RSPFile."
        } else {
            Write-Host "Certificat récupéré et enregistré à l'emplacement $CERFile`n"
        }

    } else {
        if (-not $RequestId) {
            $RequestId = (((Get-Content -Path $RSPFile -ErrorAction Ignore) -match $global:RequestIdStr) -split ':')[1].Trim()
        }

        if (Find-ManagementRights -TargetCA $TargetCA) {
            $Issue = Read-Host "Souhaitez-vous délivrer le certificat portant l'identifiant $RequestId ? (Y/N)"
            if ($Issue.ToLower() -eq 'y') {
                $Issue = C:\Windows\System32\certutil.exe -unicode -config $TargetCA -resubmit $RequestId
            }
        }

        $Retry = Read-Host "Essayer de récupérer le certificat portant l'identifiant $RequestId ? (Y/N)"
        while ($Retry.ToLower() -eq 'y') {
            $Retrieve = C:\Windows\System32\certreq.exe -unicode -retrieve -f -q -config $TargetCA $RequestId $CERFile
            $("$global:RequestIdStr : $RequestId", (Get-Content -Path $RSPFile)) | Set-Content -Path $RSPFile

            if ($Retrieve -match $global:PendingStr) {                
                $Retry = Read-Host "Le certificat n'a pas été délivré.`nRéessayer ? (Y/N)"
            } elseif ($Retrieve -match $global:DeniedStr) {
                Write-Host -ForegroundColor Yellow "La demande de certificat portant l'identifiant $RequestId a été rejeté par un administrateur."
                Write-Host -ForegroundColor Yellow "Veuillez procéder à une nouvelle requête."
                exit
            } elseif ($Retrieve -match $global:ErrorStr) {
                Write-Host -ForegroundColor Red "Erreur lors de la récupération du certificat."
                Write-Host -ForegroundColor Red "Vérifiez que l'autorité $TargetCA soit en ligne."
                Write-Host -ForegroundColor Red "Vérifiez que le certificat portant l'identifiant $RequestId existe."
                exit
            } else {
                Write-Host "Certificat récupéré et enregistré à l'emplacement $CERFile`n"
                break
            }
        }
        if ($Retry.ToLower() -ne 'y') {
            Write-Host "La demande pour ce certificat porte l'identifiant $RequestId. Cet identifiant est enregistré dans le fichier $RSPFile."
            Write-Host "Attendez qu'il soit délivré et relancez le programme."
            Write-Host "Arrêt..."
            return
        }        
    }    

    return $TargetCA
}