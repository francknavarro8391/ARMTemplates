$TemplateFile = ".\SENDGRID.JSON"
$ParameterFile = ".\PARAMETERS.JSON"
$Random = Get-Random -Minimum 0 -Maximum 100
$DeploymentName = "SENDGRID" + $Random
$ResourceGroupName = "Management"
$DisplayName = "SMAGSendGridEmail"
$CostCenter = "IT"
$Module = "Core IT services"
$Application = "Mail"
$Owner = "eestrayer@smag-group.com"
$Expiration = "None"
New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile  -DisplayName $DisplayName  -CostCenter $CostCenter -Module $Module -Application $Application  -Owner $Owner -Expiration $Expiration -NameFromTemplate $DisplayName

