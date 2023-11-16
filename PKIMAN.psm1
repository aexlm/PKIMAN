<#
if (Get-Module -Name "PSPKI") {
    # Import PSPKI Installed

} else {
    # Import PSPKI Not Installed
    Get-ChildItem -Path $PSScriptRoot -Include *.ps1 -Recurse | Forech-Object { . $_.FullName }
}
#>

#Définition des variables globales pour les opérations 'match'
switch ((Get-UICulture).Name) {
    "en-US" {
        $global:CSRObject = "Subject:"
        $global:CSRHash = "Name Hash"
        $global:CSRSAN = "Subject Alternative Name"
        $global:ConfigStr = "Config"
        $global:AutoEnrollStr = "Auto-Enroll"
        $global:RequestIdStr = "RequestID"
        $global:PendingStr = "pending"
        $global:DeniedStr = "Denied"
        $global:ErrorStr = "Error"
        $global:CurrentUserStr = "CurrentUser"
        $global:KeyContainerStr = "Key container"
        $global:SerialNumberStr = "Serial Number"
        $global:IssuerStr = "Issuer"
        $global:NotBeforeStr = "NotBefore"
        $global:NotAfterStr = "NotAfter"
        $global:SubjectStr = "Subject"
        $global:TemplateStr = "Template"
        $global:ExportPKExcpetionStr = "Export"
        $global:GetPKExcpetionStr = "GetRSAPrivateKey"
    }
    "fr-FR" {
        $global:CSRObject = "Objet:"
        $global:CSRHash = "Hachage"
        $global:CSRSAN = "Autre nom de l’objet"
        $global:ConfigStr = "Config"
        $global:AutoEnrollStr = "Inscription automatique"
        $global:RequestIdStr = "IDDemande"
        $global:PendingStr = "en attente"
        $global:DeniedStr = "Denied"
        $global:ErrorStr = "Error"
        $global:CurrentUserStr = "CurrentUser"
        $global:KeyContainerStr = "Nom de conteneur simple"
        $global:SerialNumberStr = "Numéro de série"
        $global:IssuerStr = "Émetteur"
        $global:NotBeforeStr = "NotBefore"
        $global:NotAfterStr = "NotAfter"
        $global:SubjectStr = "Objet"
        $global:TemplateStr = "Modèle"
        $global:ExportPKExcpetionStr = "Export"
        $global:GetPKExcpetionStr = "GetRSAPrivateKey"
    }
}

Get-ChildItem -Path $PSScriptRoot -Include *.ps1 -Recurse | Foreach-Object { . $_.FullName }

Export-ModuleMember -Function @(Get-ChildItem $PSScriptRoot -Include *.ps1 -Recurse | ForEach-Object {$_.Name -replace ".ps1"})