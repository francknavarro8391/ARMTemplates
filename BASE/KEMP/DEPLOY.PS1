$TemplateFile = ".\template.json"
$ParameterFile = ".\PARAMETERS.JSON"
$Random = Get-Random -Minimum 0 -Maximum 100
$DeploymentName = "KEMP" + $Random
$ResourceGroupName = "TESTSKEMP"
$VMNAME = "KEMP003"
$DisplayName = "$VMNAME"
$Module = "Securite"
$owner = "benoit.sautiere@cellenza.com"
$Application = "Kemp"
$Expiration = "NONE"
$Costcenter = "IT"
$AzureZone = "1"
New-AzureRmResourceGroupDeployment -Name $DeploymentName `
-ResourceGroupName $ResourceGroupName `
 -TemplateFile $TemplateFile `
 -TemplateParameterFile $ParameterFile `
 -AzureZone $AzureZone `
 -VirtualmachineName $VMNAME `
 -DisplayName $DisplayName `
 -Module $Module `
 -Owner  $owner `
 -Application $Application `
 -Expiration $Expiration `
 -CostCenter $CostCenter



