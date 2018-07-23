$TemplateFile = ".\BASESQLSERVER.JSON"
$ParameterFile = ".\PARAMETERS.JSON"
#$TemplateUri = "https://raw.githubusercontent.com/ExploitationSMAG/ARMTemplates/master/SMAG/BASESQLSERVER/BASESQLSERVER.JSON"
#$ParameterUri = "https://raw.githubusercontent.com/ExploitationSMAG/ARMTemplates/master/SMAG/BASESQLSERVER/PARAMETERS.JSON"

$Random = Get-Random -Minimum 0 -Maximum 100
$DeploymentName = "SQLROLE" + $Random
$ResourceGroupName = "AGREO-FRONTEND-PREPRODUCTION"
$ImageOffer = "SQL2008R2SP3-WS2008R2SP1"
$sqlImageSku = "Standard"
$OuPath = "OU=REPORT,ou=SERVEURS PREPROD,dc=NEOPROD2,dc=LOCAL"
$AzureZone = 1
$VMNAME = "PPREPORT101"
$DisplayName = $VMNAME
$CostCenter = "AGREO-PREPROD"
$Module = "Core IT services"
$Application = "AGREO"
$Owner = "Benoit.sautiere@cellenza.com"
$Expiration = "None"
New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile -ouPath $OuPath -ImageOffer $ImageOffer -sqlImageSku $sqlImageSku -AzureZone $AzureZone -VMNAME $VMNAME -DisplayName $DisplayName  -CostCenter $CostCenter -Module $Module -Application $Application  -Owner $Owner -Expiration $Expiration
#New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $TemplateUri -TemplateParameterUri $ParameterUri 

