#
# Export Selected Network Security Group into an XML File
#
#
Param(
[Parameter(Mandatory = $true)]
[String]$XMLFile,
[Parameter(Mandatory = $true)]
[String]$NSGName,
[Parameter(Mandatory = $true)]
[String]$ResourceGroupName
)
$CheckXMLPath = Test-Path -Path $XMLFile -IsValid
If ($CheckXMLPath -eq $True)
{
    #
    # File Path appear to be valid but check if output files already exists
    # 
    if([System.IO.File]::Exists($XMLFile))
    {
       write-warning "File $XMLFile Already exists."
       Exit
    }
    #
    # Check if currently logged to Azure
    #
    $CheckContext = Get-AzureRmContext -ErrorAction SilentlyContinue
    If($CheckContext -Ne $null)
    {
        Write-Host "Currently connected to subscription $($CheckContext.Subscription.Name)"
        #
        # Check if resource Group exists in subscription
        #
        $checkResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
        If ($checkResourceGroup -Ne $null)
        {
            Write-Host "Resource Group $ResourceGroupName found in subscription $($CheckContext.Subscription.Name)"
            #
            # Check if Network Security Group object exists in Resource Group or not
            #
            $CheckNSG = Get-AzureRMNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NSGName -ErrorAction SilentlyContinue
            If ($CheckNSG -ne $null)
            { 
                Write-Host "Network Security group object $NSGName found in Resource Group $ResourceGroupName."
                $TemplateNSGRules =  Get-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName | Get-AzureRmNetworkSecurityRuleConfig
               #
               # Extract workspace if is Network Security group connected to Log Analytics Workspace
               #
                $workspaceID = (Get-AzureRmDiagnosticSetting -ResourceId (Get-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName).id).workspaceid
                If ($workspaceID -ne $null)
                {
                    $workspace = Get-AzureRmOperationalInsightsWorkspace | where {$_.resourceid -eq $workspaceid}
                    $workspacename = $workspace.name
                    $workspaceresourcegroup = $workspace.ResourceGroupName 
                    Write-host "Network Security Group $NSGName is connected to Log Analytics instance $($workspace.name) located in resource Group $($workspace.ResourceGroupName)." 
                }
                Else
                {
                    $workspacename = ""
                    $workspaceresourcegroup = ""
                    Write-Host "Network Security Group $NSGName si not connected to a Log Analytics instance."                
                }
                #
                # Parse collection and create XML file
                #
                $Processing = 1
                [System.XML.XMLDocument]$oXMLDocument=New-Object System.XML.XMLDocument 
                $Declaration = $oXMLDocument.CreateXmlDeclaration("1.0","utf-8",$null)   
                $oXMLDocument.AppendChild($Declaration)          | out-null   
                [System.XML.XMLElement]$oXMLRoot=$oXMLDocument.CreateElement("NSG")

                $oXMLRoot.SetAttribute("ID",$NSGName)
                $oXMLRoot.SetAttribute("OMSWorkspace",$workspacename)
                $oXMLRoot.SetAttribute("OMSResourceGroup",$workspaceresourcegroup)
                $oXMLDocument.appendChild($oXMLRoot)
                ForEach ($NSGRule in $TemplateNSGRules)
                {
                    Write-Host "Processing rule n°$Processing/$($TemplateNSGRules.count)."
                    [System.XML.XMLElement]$oXMLSystem=$oXMLRoot.appendChild($oXMLDocument.CreateElement("Rule"))
                    $oXMLSystem.SetAttribute("Name",$NSGRule.name)
                    $oXMLSystem.SetAttribute("Priority",$NSGRule.Priority)
                    $oXMLSystem.SetAttribute("Description",$NSGRule.Description)
                    $oXMLSystem.SetAttribute("Access",$NSGRule.Access)
                    $oXMLSystem.SetAttribute("Protocol",$NSGRule.Protocol)
                    $oXMLSystem.SetAttribute("Direction",$NSGRule.Direction)
                    $oXMLSystem.SetAttribute("SourceAddressPrefix",$NSGRule.SourceAddressPrefix)
                    $oXMLSystem.SetAttribute("SourcePortRange",$NSGRule.SourcePortRange)
                    $oXMLSystem.SetAttribute("DestinationAddressPrefix",$NSGRule.DestinationAddressPrefix)
                    $oXMLSystem.SetAttribute("DestinationPortRange",$NSGRule.DestinationPortRange) 
                    $Processing +=1
                }
                $oXMLDocument.Save($XMLFile)  
                Write-Host "Network Security Group configuration $NSGName saved into $XMLFile file."
            }
            Else
            {
                Write-Warning "Network Security group object $NSGName does not exists in Resource Group $ResourceGroupName."
            }     
        }
        Else
        {
            #
            # Resource Group does not exists
            #
            Write-Warning "Unable to locate Resource Group $ResourceGroupName in subscription $($CheckContext.Subscription.Name)"
        }
    }
    Else
    {
        #
        # Not connected to an Azure Subscription
        #
        Write-Warning "No context available for an Azure subscription."
    }
}
Else
{
    #
    # XML file does not exists
    #
    Write-Warning "$XMLFile file alredady exists."
}