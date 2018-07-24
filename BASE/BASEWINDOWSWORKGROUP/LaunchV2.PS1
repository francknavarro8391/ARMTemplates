#
# Azure ARM Template Launcher with GUI
#
# Version 1.0 : Benoît SAUTIERE - Initial Release 
#

Param(

[Parameter(Mandatory=$false)]
[String]$ResourceGroupName,

[Parameter(Mandatory=$false)]
[ValidateSet("PRODUCTION","HORSPRODUCTION")]
[String]$Environment,


[Parameter(Mandatory=$True)]
[String]$VMNAME,

[Parameter(Mandatory=$True)]
[String]$Application,


[Parameter(Mandatory=$True)]
[String]$CostCenter,

[Parameter(Mandatory=$True)]
[String]$Module,

[Parameter(Mandatory=$True)]
[String]$Expiration,

[Parameter(Mandatory=$True)]
[ValidateSet(1,2,3)]
[Int]$AzureZone,

[Parameter(Mandatory=$True)]
[ValidateSet("2016-Datacenter","2012-R2-Datacenter")]
[String]$windowsOSVersion,

[Parameter(Mandatory=$True)]
[ValidateSet("BackendSubnet","FrontEndSubnet","DMZSubnet")]
[String]$SubnetName,

[Parameter(Mandatory=$True)]
[ValidateSet("Standard_A2_v2","Standard_D4_v3","Standard_D8_v3", "Standard_A2_v2", "Standard_D16_v3", "Standard_D2_v3")]
[String]$vmsize,


[Parameter(Mandatory=$True)]
[ValidateSet("Standard_LRS","Premium_LRS")]
[String]$DiskType,


[Parameter(Mandatory=$True)]
[ValidateSet("true","false")]
[String]$EnableAcceleratedNetworking

)
$testAzureContext = Get-AzureRmContext
#
# Variables to customize for each usage
#
$TemplateFile = ".\BASEWINDOWSWORKGROUP.JSON"
$ParameterFile = ".\PARAMETERS.JSON"
$Random = Get-Random -Minimum 0 -Maximum 100
$DeploymentName = "BASEWINDOWSWORKGROUP" + $Random

If (($vmsize -match "Standard_A2_v2") -and ($EnableAcceleratedNetworking -match "True"))
{
    #
    # Only case Accelerated Network is not available on A2V2.
    #
    Write-Warning "$vmsize is not compatible with Accelerated Networking feature."
    Break
}
$DisplayName = $VMNAME
$Owner = $((Get-AzureRmContext).Account.id)
#
# Check Azure Context
#
If (([string]::IsNullOrEmpty($testAzureContext) -eq $False))
{
    Write-Host "Authenticated with an Azure AD account : $((Get-AzureRmContext).Account.id)."
    $Listsubscriptions = Get-AzureRmSubscription -ErrorAction SilentlyContinue
    If (([string]::IsNullOrEmpty($Listsubscriptions) -eq $False))
    {
        #
        # Azure AD Account have access to one or more Azure subscriptions
        #OK
        If (($Listsubscriptions.count) -gt 1)
        {
            #
            # Azure AD user account have acecss to more than one subscription, selection is required
            # OK
            Write-Host "More than one Azure subsscription, please select."
            $SelectedSubscription = $Listsubscriptions | select Name, SubscriptionID | Out-GridView -PassThru -Title "Select an Azure subscription on witch ARM template must be deployed."
        }
        Else
        {
            #
            # user have access to a single subscription
            #
            $SelectedSubscription = $Listsubscriptions
        }
        If (([string]::IsNullOrEmpty($SelectedSubscription) -eq $False))
        {
            Set-AzureRmContext -SubscriptionId $SelectedSubscription.SubscriptionId
            Write-Host "Connected to Azure subscription $($SelectedSubscription.name)."
            #
            # Select resource Group where deployment should be performed
            # OK
            If (($ResourceGroupName.Length) -eq 0)
            {
                #
                # No resource group name provided, please select a resource group
                # OK
                $RG = Get-AzureRmResourceGroup | Select ResourceGroupName, Location | Out-GridView -PassThru -Title "Select a Resource Group to perform ARM template deployment."
                If (([string]::IsNullOrEmpty($RG) -eq $True))
                {
                    #
                    # No resource group selected, cancelling deployment
                    #
                    Write-Warning "No resource Group selected. Deployment cancelled."
                    Break
                }
                Else
                {
                    #
                    # A resource group was selected
                    # OK
                    $ResourceGroupName = $RG.ResourceGroupName
                    Write-Host "Azure ARM template deployment will be performed in the Resource Group named $ResourceGroupName."
                }
            }
            Else
            {
                #
                # Resource group name was provided as a parameter, check if really exists
                #
                $TestRG = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
                If (([string]::IsNullOrEmpty($TestRG) -eq $True))
                {
                    #
                    # Selected Resource Group does not exists in subscription
                    #
                    Write-Warning "Selected resource Group $ResourceGroupName does not exists in subscription $SelectedSubscription."
                    Break
                }
                Else
                {
                    #
                    # Selected resource Group exists in subscription
                    #
                    Write-Host "Selected resource Group $ResourceGroupName exists in subscription $($SelectedSubscription.Name)."               
                }
            }
            #
            # Check Environment Variable
            #
            If (($Environment.Length) -eq 0)
            {
                #
                # No parameter, will request to operator
                # OK
                $return = [System.Windows.MessageBox]::Show('Does this virtual machine will be production environment?','Virtual machine Backup','YesNoCancel','Information')
                Switch ($Return)
                {
                    "Yes"
                    {
                        Write-Host "Virtual machine will be considered as a production virtual machine."
                        $Environment = "PRODUCTION"
                    }
                    "No"
                    {
                        Write-Host "Virtual machine will be considered as a non-production virtual machine."
                        $Environment = "HORSPRODUCTION"
                    }
                    "Cancel"
                    {
                        Write-Warning "Virtual machine deployment was canceled by operator."
                        Break
                    }
                }
            }
            #
            # Search one or more Azure Recovery Vault instances with the Environment tag configured
            #
            $SearchASRInstances=@()
            $SearchASRInstances=Get-AzureRmResource -ResourceType 'Microsoft.RecoveryServices/vaults' -tag @{"Environnment"="$Environment"}
            $SearchASRInstances = $SearchASRInstances | select -Unique
            Switch($SearchASRInstances.count)
            {
                0
                {
                    #
                    # No Azure Site Recovery instance found with Environnment tag searched value
                    # OK
                    Write-warning "No Azure Recovery Vault instance found in subscription $($SelectedSubscription.Name) with Environnment tag matching $Environment."
                    Break
                }
                1
                {
                    #
                    # Single instance of ASR was found
                    # OK
                    $SelectedASRInstance = $SearchASRInstances 
                    Write-Host "Single Azure Site Recovery instance matching Environnment tag with value $Environment : $($SelectedASRInstance.Name)."
 
                }
                Default
                {
                    #
                    # Multiple instance of ASR was found please select
                    # OK
                    Write-Host "Multiple Azure Site Recovery instance matching Environnment tag with value $Environment : $($SelectedASRInstance.Name). Please select."
                    $SelectedASRInstance = $SearchASRInstances | Out-GridView -Title "Please select Azure Site Recovery instance to use." -PassThru
                    If (([string]::IsNullOrEmpty($SelectedASRInstance) -eq $False))
                    {
                        Write-Warning "No Azure Site Recovery instance selected. Virtual machine deployment cancelled."
                        Break
                    }

                }
            }
            If (([string]::IsNullOrEmpty($SelectedSubscription) -eq $False))
            {
                #
                # An Azure Site Recovery instance was selected
                #
                $VaultObject = Get-AzureRmRecoveryServicesVault -Name $SelectedASRInstance.name -ResourceGroupName $SelectedASRInstance.resourceGroupName
                Set-AzureRmRecoveryServicesVaultContext -Vault $VaultObject
                $ListPolicies  = Get-AzureRmRecoveryServicesBackupProtectionPolicy # attention au warning 
                Switch ($ListPolicies.count)
                {
                    0
                    {
                        #
                        # No backup Policy
                        #
                        Write-Warning "ASR instance $($SelectedASRInstance.name) does not have any backup policy."
                        Break
                    }
                    1
                    {
                        #
                        # Single Azure backup policy
                        # OK
                        Write-Host "ASR instance $($SelectedASRInstance.name) provide a single backup policy : $($ListPolicies.Name)."
                        $SelectedBackupPolicy = $ListPolicies 
                    }
                    Default
                    {
                        $SelectedBackupPolicy = $ListPolicies | Out-GridView -Title "Please select the backup policy to apply." -PassThru
                        If ($SelectedBackupPolicy -Eq $null)
                        {
                            Write-Warning "No backup policy selected. Deployment cancelled."
                            Break
                        }
                        Else
                        {
                            Write-Host "Selected backup Policy for virtual machine is $($SelectedBackupPolicy.name)."
                        }
                    }
                }
            }
            #
            # Search for Log Analytics
            #
            $LogAnalyticsList = Get-AzureRmResource -ResourceType 'Microsoft.OperationalInsights/workspaces' -tag @{"Environnment"="$Environment"}
            Switch ($LogAnalyticsList.Count)
            {
                0
                {
                    #
                    # So log analytics instance found
                    # OK
                    Write-Warning "No Log Analytics instance found with Environnement set to $Environment."
                    Break
                }
                1
                {
                    #
                    # Single instance of Log Analytics was found
                    # OK
                    Write-Host "A single instance of Log Analytics instance was found : $($LogAnalyticsList.Name)"
                    $SelectedLogAnalyticsinstance = $LogAnalyticsList
                }
                Default
                {
                    Write-Host "Multiple instance of Log Analytics instances were found, please select."
                    $SelectedLogAnalyticsinstance = $LogAnalyticsList | Out-GridView -Title "Please select log analytics instance to connect to ." -PassThru
                    If ($SelectedLogAnalyticsinstance -Eq $null)
                    {
                        Write-Warning "No Log Analytics instance selected. Deployment cancelled."
                        Break
                    }
                    Else
                    {
                        Write-Host "Selected Log analytics instance for virtual machine is $($SelectedLogAnalyticsinstance.name)."
                    }
                }

            }
            #
            # Search for Azure Automation instances
            #
            $Automationlist = Get-AzureRmResource -ResourceType 'Microsoft.Automation/automationAccounts' -tag @{"Environnment"="$Environment"} | select Name, ResourceGroupName, Tags, Location
            Switch($Automationlist.Count)
            {
                0
                {
                    # 
                    # Not a single instance of Automation match environnment tag criteria
                    #
                    Write-Warning "Not a single instance of Azure Automation have the Environnement configured with $Environment."
                    Break
                }
                1
                {
                    Write-Host "A single instance of Azure Automation have the Environnement configured with $Environment : $($Automationlist.Name)."
    
                }
                Default
                {
                    Write-Host "Multiple instances of Azure Automation match the Environnement tag with value $Environment. Please Select."
                    $SelectedAutomation = $Automationlist | Out-GridView -Title "Please select Azure Automation instance service to connect to." -PassThru
                    If ($SelectedAutomation -Eq $null)
                    {
                        Write-Warning "No Automation instance selected. Deployment cancelled."
                        Break
                    }
                    Else
                    {
                        Write-Host "Selected Automation instance for virtual machine is $($SelectedAutomation.name)."
                    }
                }
            }
            #
            # Everything is OK fir virtual machine deployment
            #
            Write-Host "Initiating ARM template deployment for $TemplateFile."
    #        $Deploymentstatus = New-AzureRmResourceGroupDeployment -Name $DeploymentName -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFile  -TemplateParameterFile $ParameterFile -VMNAME $VMNAME -windowsOSVersion $windowsOSVersion -SubnetName $SubnetName -vmsize $vmsize -DiskType $DiskType -EnableAcceleratedNetworking $EnableAcceleratedNetworking -AzureZone $AzureZone -DisplayName $DisplayName -CostCenter $CostCenter -Module $Module -Owner $Owner -Application $Application -Expiration $Expiration
    #        If ($Deploymentstatus.ProvisioningState -eq "Succeeded")
    #        {
    #            Write-Host "ARM template completed successfully."
    #        }
    #        Else
    #        {
    #            #
    #            # One or more errors during deployment
    #            #
    #            Write-Warning "One or more errors during ARM template deployment."
    #        }
             #
             # Register with Log analytics
             #
             $vmobject = Get-AzureRmVM -ResourceGroupName $ResourceGroupName  -Name $VMNAME
             Set-AzureRmDiagnosticSetting -ResourceId $vmobject.id -Enabled $True -WorkspaceId $SelectedLogAnalyticsinstance.resourceid | Out-Null
             #
             # Reste à faire pour automation
             #
        }
        Else
        {
            Write-Warning "No Azure subscription Selected."
        }
    }
    Else
    {
        Write-Warning "Unable to list available Azure Subscription."
    }
}
Else
{
    #
    # Not connected to Azure
    # OK
    Write-Warning "Not connected to Azure, Run Connect-AzureRmAccount"
}