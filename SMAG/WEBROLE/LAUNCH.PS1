$TemplateFile = ".\WEBROLE.JSON"
$ParameterFile = ".\PARAMETERS.JSON"
$Random = Get-Random -Minimum 0 -Maximum 100
$DeploymentName = "WEBROLE" + $Random
$ResourceGroupName = "TESTS"
$DiskType= "Standard_LRS"
$DisplayName="TESTEXEMPLE" 
$Expiration = "NONE"
$Application = "AGREO"
$owner = "benoit.sautiere@cellenza.com"
$module = "WEB"
$AzureZone = "1"
$Oupath = "ou=WEB,ou=SERVEURS PREPROD,dc=NEOPROD2,dc=LOCAL"
New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile -DiskType  $DiskType -EXPIRATION $Expiration -Application $Application -owner $owner -module $module -Displayname $DisplayName -AzureZone $AzureZone -OuPath $Oupath



