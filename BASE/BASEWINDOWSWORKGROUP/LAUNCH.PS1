$DeplpoymentName = "TEST$(Get-Random -Minimum 0 -Maximum 100)"
$ResourceGroupName = "TESTS"
$TemplateFile = ".\BASEWINDOWSWORKGROUP.JSON"
$TemplateFileURI = "https://raw.githubusercontent.com/ExploitationSMAG/ARMTemplates/master/BASE/BASEWINDOWSWORKGROUP/BASEWINDOWSWORKGROUP.JSON"
$TemplateParameterFile = ".\PARAMETERS.JSON"
$TemplateParameterURI = "https://raw.githubusercontent.com/ExploitationSMAG/ARMTemplates/master/BASE/BASEWINDOWSWORKGROUP/PARAMETERS.JSON"
New-AzureRmResourceGroupDeployment -Name $DeplpoymentName -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile  -TemplateParameterFile $TemplateParameterFile -Verbose
#New-AzureRmResourceGroupDeployment -Name $DeplpoymentName -ResourceGroupName $ResourceGroupName -TemplateUri $TemplateFileURI  -TemplateParameterUri $TemplateParameterURI -Verbose