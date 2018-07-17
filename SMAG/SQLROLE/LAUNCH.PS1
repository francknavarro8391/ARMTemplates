$TemplateFile = ".\SQLROLE.JSON"
$ParameterFile = ".\PARAMETERS.JSON"
$Random = Get-Random -Minimum 0 -Maximum 100
$DeploymentName = "SQLROLE" + $Random
$ResourceGroupName = "TESTS"
$VMNAME = "TESTSQL003"
$DisplayName = "$VMNAME"
$Module = "SQL"
$owner = "benoit.sautiere@cellenza.com"
$Application = "AGREO"
$Expiration = "TODAY"
$Costcenter = "IT"
$DiskType = "Premium_LRS"
$oupath = "ou=BDD,ou=SERVEURS PREPROD,dc=NEOPROD2,dc=LOCAL"
$AzureZone = "1"
New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile -vmname $VMNAME -DisplayName $DisplayName -module $Module -owner $owner -Application $Application -Expiration $Expiration -Oupath $oupath -CostCenter $Costcenter -DiskType $DiskType -AzureZone $AzureZone


