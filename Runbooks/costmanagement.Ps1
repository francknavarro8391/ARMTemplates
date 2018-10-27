Param
(
    [Parameter(Mandatory=$true)]
    [ValidateRange(1,365)]
    [Int]$DateRangeInDays
)
#$connectionName = "AzureRunAsConnection"
#try
#{
#    # Get the connection "AzureRunAsConnection "
#    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
#
#    "Logging in to Azure..."
#    Add-AzureRmAccount `
#        -ServicePrincipal `
#        -TenantId $servicePrincipalConnection.TenantId `
#        -ApplicationId $servicePrincipalConnection.ApplicationId `
#        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
#}
#catch {
#    if (!$servicePrincipalConnection)
#    {
#        $ErrorMessage = "Connection $connectionName not found."
#        throw $ErrorMessage
#    } else{
#        Write-Error -Message $_.Exception
#        throw $_.Exception
#    }
#}
#
# Retriving Azure Automation variables & credentials
#
$SubscriptionId = Get-AzureRmAutomationVariable -ResourceGroupName "Management" -AutomationAccountName "SMAG-Automation" -Name "SubscriptionID"
$SendgridEmailFrom = (Get-AzureRmAutomationVariable -ResourceGroupName "Management" -AutomationAccountName "SMAG-Automation" -Name "SendgridEmailFrom").value
$SendGridAutomationSecret = (Get-AzureRmAutomationVariable -ResourceGroupName "Management" -AutomationAccountName "SMAG-Automation" -Name "SendGridAutomationSecret").value
$Password = ConvertTo-SecureString $SendGridAutomationSecret -AsPlainText -Force 
$credential = New-Object System.Management.Automation.PSCredential "apikey", $Password 
$SMTPServer = "smtp.sendgrid.net" 
$Subject = "[Azure Cost Management] - ResourceGroup consumption report" 
write-output "Getting all cost items for subscription $($SubscriptionId.value)."
$now = get-Date
$startDate = $($now.Date.AddDays(-$DateRangeInDays))
$endDate = $($now.Date)
write-output "Start Date :  $startDate  "
write-output "End Date :  $endDate "
$SubConsumptionUsage = Get-AzureRmConsumptionUsageDetail -StartDate $startDate  -EndDate $endDate
write-output "Finding all of the resource group names which existed during this billing period."
$SubIdPrefix = "/subscriptions/" + $($SubscriptionId.value)
$RgIdPrefix = $SubIdPrefix + "/resourceGroups/"
$resourceGroupName = @()
$resourceGroups = @()
#
# Parse all Consumption usage finding resource groups
#
foreach ($line in $SubConsumptionUsage) {
    if ($line.InstanceId -ne $null ) {
        #
        # Pour filtrer les resources sans mention du groupe de ressources
        # /subscriptions/62c1a715-33b8-4842-a100-addfd8b7759d/providers/microsoft.sql/locations/francecentral/longtermretentionservers/dev-apiconsumptionmonitor-data/longtermretentiondatabases/db-dev-apiconsumptionmonitor/longtermretentionbackups
        #
        If (($line.InstanceId).contains("resourceGroups") -eq $True) {
            $thisRgName = $($line.InstanceId.ToLower()).Replace($RgIdPrefix.ToLower(),"")
            $toAdd = $thisRgName.Split("/")[0] # bug ici
            $toAdd = $toAdd.ToString()
            $toAdd = $toAdd.ToLower()
            $toAdd = $toAdd.Trim()
            if ($resourceGroups.Name -notcontains $toAdd) {
                $resourceGroupName = [PSCustomObject]@{
                Name = $toAdd
                }
                $resourceGroups += $resourceGroupName
            }
        }
    }
}
Write-Output "Calculating the cost of each Resource Group, then flag ones that exceed NotifyCostLimit."
$currentResourceGroups = Get-AzureRmResourceGroup
$rgIndexId = 0
foreach ($rg in $resourceGroups) {
    #
    # Parse each resoufceGroup and check if tag NotifyCostLimit enforce a limit
    #
    $RgIdPrefix = $SubIdPrefix + "/resourceGroups/" + $rg.Name
    $ThisRgCost = $null
  #  $SubConsumptionUsage | ? { if ( $_.InstanceId -ne $null) { $($_.InstanceId.ToLower()).StartsWith($RgIdPrefix.ToLower()) } } |  ForEach-Object { $ThisRgCost += $_.PretaxCost   }
  $SubConsumptionUsage | Where-Object { if ( $_.InstanceId -ne $null) { $($_.InstanceId.ToLower()).StartsWith($RgIdPrefix.ToLower()) } } |  ForEach-Object { $ThisRgCost += $_.PretaxCost   }


    $toaddCost = [math]::Round($ThisRgCost,2)
    $resourceGroups[$rgIndexId] | Add-Member -MemberType NoteProperty -Name "Cost" -Value $toaddCost
    if ($currentResourceGroups.ResourceGroupName -contains $rg.Name) {
        $addingResourceGroup = Get-AzureRmResourceGroup -Name $($rg.Name)
        $resourceGroups[$rgIndexId] | Add-Member -MemberType NoteProperty -Name "NotifyCostLimit" -Value $($addingResourceGroup.tags.NotifyCostLimit)
    }
    $rgIndexId ++
}
Write-Output "Found $rgIndexId Resource Groups."
$resourceGroups | Format-Table 
#
# Formating HTML mail
#
$chaine += "Rapport de consommation Azure pour chaque groupe de ressources depuis <b>$DateRangeInDays</b> jours pour la souscription  $($SubscriptionId.value)  <br>" 
$chaine += "<table style=""width:50s%"">"
$chaine += "<th align=left> Resource Group Name</th> <th> Cost</th> <th>Cost limit</th> " + "<br>"
ForEach ($resourcegroupResult in $resourceGroups) {
    $chaine += "<tr>"
    $chaine += "<th align=left> " + $resourcegroupResult.Name + "</th> <th>" + $resourcegroupResult.Cost + "</th> <th>" + $resourcegroupResult.NotifyCostLimit + "</th> " + "<br>"
    $chaine += "</tr>"
}
$chaine += "</table>"
Send-MailMessage -smtpServer $SMTPServer -Credential $credential -Usessl -Port 587 -from $SendgridEmailFrom -to 'benoit.sautiere@cellenza.com' -subject $Subject -Body $chaine -BodyAsHtml 
Send-MailMessage -smtpServer $SMTPServer -Credential $credential -Usessl -Port 587 -from $SendgridEmailFrom -to $SendgridEmailFrom -subject $Subject -Body $body -BodyAsHtml 
