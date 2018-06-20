$TemplateURI = "https://raw.githubusercontent.com/ExploitationSMAG/ARMTemplates/master/BASE/WINDOWS/BASEWINDOWS.JSON"
$ParameterURI = "https://raw.githubusercontent.com/ExploitationSMAG/ARMTemplates/master/BASE/WINDOWS/PARAMETERS.JSON"
$ResourceGroupName = "TESTS"
$random = Get-Random -Minimum 0 -Maximum 100
$DeploymentName = $ResourceGroupName + $random 
$TemplateFile = ".\BASEWINDOWS.JSON"
$ParameterFile = ".\PARAMETERS.JSON"
#New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateUri $TemplateURI -TemplateParameterUri $ParameterURI 
New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $resourceGroupname -TemplateFile $TemplateURI -TemplateParameterFile $ParameterFile  