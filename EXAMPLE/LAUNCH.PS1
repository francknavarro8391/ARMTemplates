$TemplateFile = ".\DEPLOY.JSON"
$ParameterFile = ".\PARAMETERS.JSON"
$Random = Get-Random -Minimum 0 -Maximum 100
$DeploymentName = "DEPLOY" + $Random
$ResourceGroupName = "TESTS"
New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile -vmName DEPLOY -DisplayName DEPLOY -Module DEPLOY -owner DEPLOY -Application DEPLOY -EXPIRATION NONE
