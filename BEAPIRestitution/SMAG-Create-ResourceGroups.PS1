

Function Create-SMAGResourceGroup{
Param(
[Parameter(Mandatory=$True)]
[String]$ResourceGroupName,

[Parameter(Mandatory=$True)]
[String]$ApplicationName,

[Parameter(Mandatory=$True)]
[String]$ApplicationZone,

[Parameter(Mandatory=$True)]
[String]$Environment

)

    $TagArray = @{DisplayName=$ResourceGroupName; "CostCenter" = $ApplicationName; "Owner" = $((Get-AzureRmContext).account.id); "Application" = $ApplicationName; "Module" = $ApplicationZone}
    $TestResourceGroup = Get-AzurermResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    If ($TestResourceGroup -eq $null)
    {
        Write-Host "Resource Group does not exists $ResourceGroupname. Will be created."
        New-AzureRmResourceGroup -Name $ResourceGroupname -Location $DefaultAzureRegion -Tag $TagArray
    }
    Else
    {
        Write-Warning "Resource Group Already exists $ResourceGroupname. Unable to create resource group."
    }
}

$DefaultAzureRegion = "FranceCentral"


#$TagArray = @{DisplayName=$ResourceGroupName; "CostCenter" = "IT"; "Owner" = $CheckContext.Account.Id; "Application" = "Network"; "Module" = "Security"}

#DisplayName : Pour permettre de réutiliser la charte de nommage en évitant les contraintes de nommage propre aux Resource Providers Azure. 
#CostCenter : Pour préparer la mise en place des codes d'imputation comptables et la refacturation entre les entités 
#Module : Pour identifier le rôle par les ressources contenues dans le groupe de ressources (Front-end, back-end, …) 
#Owner : Pour identifier les responsable des workloads en cas d'incident sécurité  
#Application : Pour permettre de regroupes tous les composants d'une même application car la charte de nommage du groupe de ressources inclus une segmentation par rôle 
#Expiration :date expiration 

               
#
# Search available suscription
#
$Listsubscriptions = Get-AzureRmSubscription -ErrorAction SilentlyContinue
If ($Listsubscriptions -ne $null)
{
    If (($Listsubscriptions.count) -gt 1)
    {
        Write-Host "More than one Azure subsscription, please select."
        $SelectedSubscription = $Listsubscriptions | Out-GridView -PassThru
    }
    Else
    {
        $SelectedSubscription = $Listsubscriptions
        Write-Host "Connected to Azure subscription $SelectedSubscription.name."
        #
        # BEAPI Restitution Dev
        #
        Create-SMAGResourceGroup -ResourceGroupName "BEAPIRestitution-IHM-Dev" -ApplicationName "BEAPIRestitution" -ApplicationZone "IHM" -Environment "DEV"
        Create-SMAGResourceGroup -ResourceGroupName "BEAPIRestitution-OPERATIONAL-Dev" -ApplicationName "BEAPIRestitution" -ApplicationZone "OPERATIONAL" -Environment "DEV"
        #
        # BEAPI Restitution Validation
        #
        Create-SMAGResourceGroup -ResourceGroupName "BEAPIRestitution-IHM-Validation" -ApplicationName "BEAPIRestitution" -ApplicationZone "IHM" -Environment "VALIDATION"
        Create-SMAGResourceGroup -ResourceGroupName "BEAPIRestitution-OPERATIONAL-Validation" -ApplicationName "BEAPIRestitution" -ApplicationZone "OPERATIONAL" -Environment "VALIDATION"
        #
        # BEAPI Restitution Préproduction
        #
        Create-SMAGResourceGroup -ResourceGroupName "BEAPIRestitution-IHM-Preproduction" -ApplicationName "BEAPIRestitution" -ApplicationZone "IHM" -Environment "PREPRODUCTION"
        Create-SMAGResourceGroup -ResourceGroupName "BEAPIRestitution-OPERATIONAL-Preproduction" -ApplicationName "BEAPIRestitution" -ApplicationZone "OPERATIONAL" -Environment "PREPRODUCTION"
        #
        # BEAPI Restitution Production
        #
        Create-SMAGResourceGroup -ResourceGroupName "BEAPIRestitution-IHM-Production" -ApplicationName "BEAPIRestitution" -ApplicationZone "IHM" -Environment "PRODUCTION"
        Create-SMAGResourceGroup -ResourceGroupName "BEAPIRestitution-OPERATIONAL-Production" -ApplicationName "BEAPIRestitution" -ApplicationZone "OPERATIONAL" -Environment "PRODUCTION"
        #
        # BEAPI all zones
        #
        Create-SMAGResourceGroup -ResourceGroupName "BEAPI-IHM-Dev" -ApplicationName "BEAPI" -ApplicationZone "IHM" -Environment "DEV"
        Create-SMAGResourceGroup -ResourceGroupName "BEAPI-IHM-Validation" -ApplicationName "BEAPI" -ApplicationZone "IHM" -Environment "VALIDATION"
        Create-SMAGResourceGroup -ResourceGroupName "BEAPI-IHM-Preproduction" -ApplicationName "BEAPI" -ApplicationZone "IHM" -Environment "PREPRODUCTION"
        Create-SMAGResourceGroup -ResourceGroupName "BEAPI-IHM-Production" -ApplicationName "BEAPI" -ApplicationZone "IHM" -Environment "PRODUCTION"
        #
        # Prod & Hors Prod
        #
        Create-SMAGResourceGroup -ResourceGroupName "SOCLEAPPLISMAG-PROD" -ApplicationName "SOCLEAPPLISMAG" -ApplicationZone "SOCLEAPPLI" -Environment "PRODUCTION"
        Create-SMAGResourceGroup -ResourceGroupName "SOCLEAPPLISMAG-HORSPROD" -ApplicationName "SOCLEAPPLISMAG" -ApplicationZone "SOCLEAPPLI" -Environment "HORSPRODUCTION"
    }
    If ($SelectedSubscription -ne $null)
    {
        Set-AzureRmContext -SubscriptionId $SelectedSubscription.SubscriptionId
        Write-Host "Connected to Azure subscription $SelectedSubscription.name."
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







