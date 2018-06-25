#
# Name of NSG to be created
# Resource Group where NSG must be created
# XML file to load

# BUG pour l'écrasement de l'objet
# Positionner les paramètres suivants dans le fichier XML
# OnPremisesDC1, OnPremisesDC2, AzureDC1, AzureDC2, KMS, ONPREMISES, ADMINZONE,GATEWAYSUBNET, 
# extraire ces infos DMZSUBNET, FRONTENDSUBNET, BACKENDSUBNET
# Manque les flux entrants ON-Premises pour les DC

Param(
[Parameter(Mandatory = $true)]
[String]$XMLFile,
[Parameter(Mandatory = $true)]
[String]$NSGName,
[Parameter(Mandatory = $true)]
[String]$ResourceGroupName
)
$NSGBackupSuffix = "_BACKUP"
$TagArray = @{DisplayName=$NSGName; "CostCenter" = "IT"; "Owner" = $CheckContext.Account.Id; "Application" = "Network"; "Module" = "Security"}
#
# Check if XML file exists
#
$CheckXMLPath = Test-Path -Path $XMLFile
If ($CheckXMLPath -Ne $Null)
{
    Write-Host "$XMLFile file found."
    #
    # Load XML File
    #
    Try
    {
        Write-Host "Loading $XMLFile file as XML File for parsing." 
        [xml]$xmldata = get-content $XMLFile
    }
    Catch
    {
        Write-Warning "Unable to load file $XMLFile as an XML File."
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
            If ($CheckNSG -eq $Null)
            { 
                $UpdateMode = $False
                Write-Host "Network Security group object $NSGName does not exists in Resource Group $ResourceGroupName. Object will be created."
            }
            Else
            {
                $UpdateMode = $True          
                Write-Host "Network Security group object $NSGName already exists in Resource Group $ResourceGroupName. Object will be updated after backup."
            }
                
            #
            # Backup Object is already exists by copying object
            #
            If ($UpdateMode -Eq $True)
            {
                # Create Copy NSG to a new object NSGNAME_BACKUP
                Write-host "Backing up Network Security Groupe object $NSGName into $($NSGName + $NSGBackupSuffix)."
                Try
                {
                    $TemplateNSGRules =  Get-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName | Get-AzureRmNetworkSecurityRuleConfig
                    $BackupNSG = New-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $checkResourceGroup.Location -Name $($NSGName + $NSGBackupSuffix) -Confirm $false
                    ForEach ($rule in $TemplateNSGRules) 
                    {
                        $BackupNSG | Add-AzureRmNetworkSecurityRuleConfig -Name $rule.Name -Direction $rule.Direction -Priority $rule.Priority -Access $rule.Access -SourceAddressPrefix $rule.SourceAddressPrefix -SourcePortRange $rule.SourcePortRange -DestinationAddressPrefix $rule.DestinationAddressPrefix -DestinationPortRange $rule.DestinationPortRange -Protocol $rule.Protocol  -Description $rule.Description | Out-Null
                        $BackupNSG | Set-AzureRmNetworkSecurityGroup  | Out-Null
                    }
                }
                Catch
                {
                    Write-Warning "Error while backing up Network Security Groupe object $NSGName into $($NSGName + $NSGBackupSuffix)."
                }

            }
            #
            # Parsing XML File to load rules
            #
            If (($xmldata.NSG.ID.ToUpper()) -eq ($NSGName.ToUpper()))
            {
                #
                # NSG Name Match Rule name in XML File
                #
                Write-Host "XML file rule name match with NSG name."
                $ProcessingRule = 1
                $Errorflag = $False
                $rules = @()
                ForEach($XMLNode in $xmldata.NSG.Rule)
                {
                    #
                    # Processing each rule described into the XML File
                    #
                    Write-Host "Processing Rule $($XMLNode.Name) n°$ProcessingRule/$($xmldata.NSG.Rule.count)" 
                    Try
                    {
                        $rules += New-AzureRmNetworkSecurityRuleConfig -Name $($XMLNode.Name) -Description $($XMLNode.Description) -Access $($XMLNode.Access) -Protocol $($XMLNode.Protocol) -Direction $($XMLNode.Direction) -Priority $($XMLNode.Priority) -SourceAddressPrefix $($XMLNode.SourceAddressPrefix) -SourcePortRange $($XMLNode.SourcePortRange) -DestinationAddressPrefix $($XMLNode.DestinationAddressPrefix) -DestinationPortRange $($XMLNode.DestinationPortRange)
                        $ProcessingRule += 1
                    }
                    Catch
                    {
                        Write-Warning "Error while creating NSG Rule $($XMLNode.Name)"
                        $Errorflag = $true
                    }
                }
                If ($Errorflag -Eq $False)
                {
                    #
                    # Creating Network Security Group Object
                    #
                    Write-Host "Creating Network Security Group Object $NSGName in Resource Group name $ResourceGroupName in Azure Region $($checkResourceGroup.Location)"    
                    Try
                    {
                        $NewNSG = New-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -Location $($checkResourceGroup.Location) -SecurityRules $Rules -Tag $TagArray -Force 
                    }
                    Catch
                    {
                        Write-Warning "Error while creating Network Security Group $NSGName."
                        #
                        # Inform user that a backup version of the object exists in Azure
                        # 
                        If ($UpdateMode -Eq $True)
                        {
                            Write-Warning "Backup version of Network Security Group was created : $($NSGName + $NSGBackupSuffix). Object is located into the $ResourceGroupName Resource Group."
                        }
                        Exit
                    }
                    #
                    # Configure Logging to OMS with information from XML file
                    #
                    $OmsInstance=Get-AzureRmOperationalInsightsWorkspace  -ResourceGroupName $xmldata.NSG.OMSResourceGroup -Name $xmldata.NSG.OMSWorkspace

                    If ($OmsInstance -ne $Null)
                    {
                        Write-Host "OMS Workspace $($xmldata.NSG.OMSWorkspace) found in Resource Group $($xmldata.NSG.OMSResourceGroup)."
                        Try
                        {
                        Set-AzureRmDiagnosticSetting   -ResourceId $NewNSG.Id -WorkspaceId $OmsInstance.ResourceId -Enabled $true | Out-Null
                        Write-Host "Log Analytics logging successfully configured for Network Security Group $NSGName."
                        }
                        Catch
                        {
                            Write-Warning "Enable to configure Log Analytics Logging for Network Security Group $NSGName."
                        }
                    }
                    Else
                    {
                        Write-Warning "Unable to locate OMS Workspace $($xmldata.NSG.OMSWorkspace) in Resource Group $($xmldata.NSG.OMSResourceGroup)."
                    }
                }
                Else
                {
                    Write-Warning "One or more errors while creating the Network Security Group object."
                    #
                    # Inform user that a backup version of the object exists in Azure
                    # 
                    If ($UpdateMode -Eq $True)
                    {
                        Write-Warning "Backup version of Network Security Group was created : $($NSGName + $NSGBackupSuffix). Object is located into the $ResourceGroupName Resource Group."
                    }
                }
            }
            Else
            {
                #
                # Rule name in XML file does not match rule name parameter
                #
                Write-Warning "XML file rule name does not match with NSG name."
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
    Write-Warning "$XMLFile file not found."
}