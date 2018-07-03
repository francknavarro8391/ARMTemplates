$TemplateFile = ".\SQLROLE.JSON"
$ParameterFile = ".\PARAMETERS.JSON"
$TemplateUri = "https://raw.githubusercontent.com/ExploitationSMAG/ARMTemplates/master/SMAG/SQLROLE/SQLROLE.JSON"
$ParameterUri = "https://raw.githubusercontent.com/ExploitationSMAG/ARMTemplates/master/SMAG/SQLROLE/PARAMETERS.JSON"

$Random = Get-Random -Minimum 0 -Maximum 100
$DeploymentName = "SQLROLE" + $Random
$ResourceGroupName = "TESTS"
New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile 
#New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $TemplateUri -TemplateParameterUri $ParameterUri #  -DisplayName DEPLOY2 -Module DEPLOY2 -owner DEPLOY2 -Application DEPLOY2 -EXPIRATION NONE

