$TemplateFile = ".\BASESQLSERVER.JSON"
$ParameterFile = ".\PARAMETERS.JSON"
$vmname = "PPREPORT102"
$Random = Get-Random -Minimum 0 -Maximum 100
$DeploymentName = "PPREPORT102" + $Random
$ResourceGroupName = "AGREO-FRONTEND-PREPRODUCTION"
$DeploymentName = "SQLROLE" + $Random 
$ImageOffer = "SQL2016SP2-WS2016"
$sqlImageSku = "Standard"
$OuPath = "OU=REPORT,ou=SERVEURS PREPROD,dc=NEOPROD2,dc=LOCAL"
$AzureZone = 1
$DisplayName = $VMNAME
$CostCenter = "AGREO-PREPROD"
$Module = "Core IT services"
$Application = "AGREO"
$Owner = "Benoit.sautiere@cellenza.com"
$Expiration = "None"
$Subnetname = "frontendSubnet"
New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile -DisplayName $DisplayName -Module $Module -owner $Owner -Application $Application -EXPIRATION $Expiration -CostCenter $CostCenter -OuPath $OuPath -ImageOffer $ImageOffer -sqlImageSku $sqlImageSku -AzureZone $AzureZone -SubnetName $SubnetName









