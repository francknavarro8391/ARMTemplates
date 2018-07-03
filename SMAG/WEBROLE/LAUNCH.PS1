$TemplateFile = ".\WEBROLE.JSON"
$ParameterFile = ".\PARAMETERS.JSON"
$TemplateUri = "https://raw.githubusercontent.com/ExploitationSMAG/ARMTemplates/master/SMAG/WEBROLE/WEBROLE.JSON"
$ParameterUri = "https://raw.githubusercontent.com/ExploitationSMAG/ARMTemplates/master/SMAG/WEBROLE/PARAMETERS.JSON"
$Random = Get-Random -Minimum 0 -Maximum 100
$DeploymentName = "WEBROLE" + $Random
$ResourceGroupName = "TESTS"
New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile -TemplateParameterFile $ParameterFile # -vmName DEPLOY2 -DisplayName DEPLOY2 -Module DEPLOY2 -owner DEPLOY2 -Application DEPLOY2 -EXPIRATION NONE
#New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $TemplateUri -TemplateParameterUri $ParameterUri #  -DisplayName DEPLOY2 -Module DEPLOY2 -owner DEPLOY2 -Application DEPLOY2 -EXPIRATION NONE

