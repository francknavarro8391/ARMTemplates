#
# Import XML description of a Network Security group into an Azure Security Group Object
# Version 1.1 - Benoît SAUTIERE
#               Include randomize in NSG backup name
#               Exlude Log Analytics configuration from the XML file
#               
Param(
[Parameter(Mandatory = $true)]
[String]$XMLFile,
[Parameter(Mandatory = $true)]
[String]$NSGName,
[Parameter(Mandatory = $true)]
[String]$ResourceGroupName,
[Parameter(Mandatory = $true)]
[String]$OMSWorkspace
)
$NSGBackupSuffix = "_BACKUP"
$OMSWorkspace = $OMSWorkspace.Trim()
$ResourceGroupName = $ResourceGroupName.Trim()
$XMLFile = $XMLFile.Trim()
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
            # Check if log analytics resource group exists
            #
            $CheckOMSWorkspace = Get-AzureRmOperationalInsightsWorkspace | where {$_.name -eq $omsworkspace}
            If ($CheckOMSWorkspace -eq $null)
            {
                #
                # Unable to locate log Analytics workspace
                #
                Write-Warning "Log Analytics Workspace $omsworkspace does not exists in your subscription."
                Exit
            }
            Else
            {
                #
                # Log Analytics Workspace exists
                #
                Write-host "Log Analytics Workspace $omsworkspace found in your subscription."
            }
            #
            # Backup Object is already exists by copying object
            #
            If ($UpdateMode -Eq $True)
            {
                #
                # Create Copy NSG to a new object NSGNAME_BACKUP
                #
                $Random = Get-Random -Minimum 0 -Maximum 10000
                Write-host "Backing up Network Security Groupe object $NSGName into $($NSGName + $NSGBackupSuffix + "_" + $Random)."
                Try
                {
                    $TemplateNSGRules =  Get-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName | Get-AzureRmNetworkSecurityRuleConfig
                    $BackupNSG = New-AzureRmNetworkSecurityGroup -Name $($NSGName + $NSGBackupSuffix + "_" + $Random) -ResourceGroupName $ResourceGroupName -Location $($checkResourceGroup.Location) -SecurityRules $TemplateNSGRules -Tag $TagArray -Force -WarningAction SilentlyContinue 
                    #
                    # Configure Logging to OMS with information from XML file
                    #
                    Try
                    {
                        Set-AzureRmDiagnosticSetting -ResourceId $BackupNSG.Id -WorkspaceId $CheckOMSWorkspace.ResourceId -Enabled $true | Out-Null
                        Write-Host "Log Analytics logging successfully configured for Network Security Group $NSGName."
                    }
                    Catch
                    {
                        Write-Warning "Unable to configure Log Analytics Logging for Network Security Group $NSGName."
                    }                    
                }
                Catch
                {
                    Write-Warning "Error while backing up Network Security Groupe object $NSGName into $($NSGName + $NSGBackupSuffix + "_" + $Random)."
                    exit
                }
            }
            #
            # Parsing XML File to load rules
            #
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
                    $NewNSG = New-AzureRmNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -Location $($checkResourceGroup.Location) -SecurityRules $Rules -Tag $TagArray -Force -WarningAction SilentlyContinue
                }
                Catch
                {
                    Write-Warning "Error while creating Network Security Group $NSGName."
                    #
                    # Inform user that a backup version of the object exists in Azure
                    # 
                    If ($UpdateMode -Eq $True)
                    {
                        Write-Warning "Backup version of Network Security Group was created : $($NSGName + $NSGBackupSuffix + "_" + $Random). Object is located into the $ResourceGroupName Resource Group."
                    }
                    Exit
                }
                #
                # Configure Logging to OMS 
                #
                Try
                {
                    Set-AzureRmDiagnosticSetting   -ResourceId $NewNSG.Id -WorkspaceId $CheckOMSWorkspace.ResourceId -Enabled $true  | Out-Null
                    Write-Host "Log Analytics logging successfully configured for Network Security Group $NSGName."
                }
                Catch
                {
                    Write-Warning "Enable to configure Log Analytics Logging for Network Security Group $NSGName."
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
                    Write-Warning "Backup version of Network Security Group was created : $($NSGName + $NSGBackupSuffix + "_" + $Random). Object is located into the $ResourceGroupName Resource Group."
                }
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