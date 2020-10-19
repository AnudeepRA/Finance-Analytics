<#
.SYNOPSIS
    This Powershell will deploy an Analysis Services Model to Azure Analysis Services 

.DESCRIPTION
     






.EXAMPLE
    
 
.NOTES
    Author: Len Davis
    Last Update: Nov 2019
    Modified by: Len Davis
   #>
   <#
   
   This Powershell will modify the Username and Passowrd of a Database






  #>
<#
  [cmdletbinding()]
 Param(
      [string]$AuthenticationKind,
      [string]$Username,
      [string]$DBPassword,
      [string]$DBDeployJSONfile
)
$A = 'N'
if ($DBPassword -eq 'test') {$A = 'Y'}
write-output " Param" $A
write-output " Param" $Username
write-output "DBDeploy name" $DBDeployJSONfile


#>
Import-Module $PSScriptRoot\ImportPowershellModules\Az.Accounts
Import-Module $PSScriptRoot\ImportPowershellModules\DeployAASFromModel_Bim
Import-Module $PSScriptRoot\ImportPowershellModules\Az.KeyVault

Import-Module $PSScriptRoot\ImportPowershellModules\Az.AnalysisServices


  
#$azContext = Get-AzContext
#get DevOPs Variables  Reads the varibles from DevOps
$ModelName        =  $Env:ModelName
$Modelbim         =  $Env:Modelbim
$ModelbimPath     =  $Env:ModelbimPath
$KVSecrets        =  $Env:KVSQLSecrets
$subscriptionName =  $Env:SubscriptionName
$SubscriptionId   =  $Env:SubscriptionID
#$dwhpath =        $env:dwhpath
#$dwhadmin =       $Env:dwhadmin
#$dwhpwd =         $Env:dwhpwd
#$Database_Source = $Env:DatabaseSource
$spn              =  $env:SPN_AzureAnalysisServicesAdmin
$spnpwd           =  $env:SPN_AzureAnalysisServicesAdmin_PWD
#$Database =       $Env:Database
$aasServer        =  $env:Server
$Server           =  $Env:Server
$DBKeyVaultID     =  $env:DWHKeyVault
$AASKeyVaultID    =  $env:ASKeyVaultID
$DBPassword1      =  $ENV:DBPassword 
Write-Host "DBKeyVaultID ."  $DBKeyVaultID 
Write-Host "Model Path."  $ModelbimPath
Write-Host "Model Name."  $ModelName
Write-Host "DB Admin."    $dwhadmin
Write-Host "DS"           $Database_Source
Write-Host "Subscription" $SubscriptionId
Write-HOST "DBPassword1 " $DBPassword1

 


# Read the Model.BIM 

# Get AAS credentals so the IP can be injected into the firewal 

write-host " KV-Secrets:" $KVSecrets

$currentAzureContext = Get-AzContext
$tenantId = '855b093e-7340-45c7-9f0c-96150415893e'
$spnpwd= ConvertTo-SecureString $spnpwd -AsPlainText -Force
$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($spn, $spnpwd)
$pscredential = New-Object System.Management.Automation.PSCredential($spn, $spnpwd)
#Connect-AzAccount -Credential $pscredential -Tenant $tenantId -ServicePrincipal#
#set-AzContext -Subscription $SubscriptionId
Connect-AzAccount -Credential $pscredential -Tenant $tenantId   -ServicePrincipal

#Set firewall and SP context
        Write-host "SubscriptionName "   $subscriptionName
        $azContext = Set-AzContext -Subscription $subscriptionName
Write-host " Using  Context"



 ######################################################################
# 

# Remove security Ids

 
 # Remove firewall rule
    Write-Verbose "Remove firewall rule"
    RemoveCurrentServerFromASFirewall -Server $aasServer -AzContext $azContext
	