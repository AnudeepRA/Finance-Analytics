﻿<#
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

  [cmdletbinding()]
 Param(
      [string]$AuthenticationKind,
      [string]$Username,
      [string]$DBPassword,
      [string]$DBDeployJSONfile
)

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
$DBPassword1      = "'" +  $ENV:DBPassword + "'"
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
Write-host " Using  Context"



 ######################################################################
# Set firewall and SP context
        Write-host "SubscriptionName "   $subscriptionName
        $azContext = Set-AzContext -Subscription $subscriptionName
         
        #$azContext = set-AzContext 'az2i-0056-Analytics Internal Quality Assurance-HQTRS-055'
                                         #az2i-0056-Analytics Internal Quality Assurance-HQTRS-055
         $ipDetectionMethod = "autoDetect"
		$startIPAddress =""
		$endIPAddress = ""
        Write-Verbose "Set firewall"
		$environment = $aasServer.Split('/')[2];
		Write-host " Env: " $environment
      # $result = Add-AzAnalysisServicesAccount -Credential $pscredential -ServicePrincipal -TenantId $TenantId -RolloutEnvironment $environment
       $addedFirewallRule = AddCurrentServerToASFirewall -Server $aasServer -Credentials $pscredential -AzContext $azContext -IpDetectionMethod $ipDetectionMethod -StartIPAddress $startIPAddress -EndIPAddress $endIPAddress
        
       write-output "Did we get pass here 0" 
       write-host " azcontext " $SubscriptionName

# Read .asdatabase/.bim file as model
$model = ReadModel -ModelFile $ModelbimPath

 write-output "Did we get pass here 01"
   $DBDeployJSON =  Get-Content $DBDeployJSONfile -Encoding UTF8 | ConvertFrom-Json
    #Get-Content "Deploy_SFA_Des_Prod__credential.json"  #-Encoding UTF8 | ConvertFrom-Json


# Rename model name
# Rename model name
$model = RenameModel -Model $model -NewName $modelName





	

#Main Processing 


$connectionDetails = $DBDeployJSON
#$connectionDetails.createOrReplace.dataSource
 #$connectionDetails = ConvertFrom-Json $DBDeployJSON
 # $UpdatePasswordTMSL = $connectionDetails | ConvertTo-Json
 #$connectionDetails.createOrReplace.object.database =   $ModelName
#$connectionDetails.createOrReplace.dataSource.credential.AuthenticationKind = "UsernamePassword"
#$connectionDetails.createOrReplace.dataSource.credential.Username = $Username
$connectionDetails.createOrReplace.dataSource.Password =  $DBPassword  
#$connectionDetails.createOrReplace.dataSource.credential.Password = $DBPassword
#$connectionDetails.createOrReplace.dataSource.credential.EncryptConnection = true
$tsml =  $connectionDetails 


$jsondata = ConvertTo-Json $tsml -Depth 100 -Compress


# Process Password
 
 
 
try {
        $result = Invoke-ASCmd -Server $aasServer -Query $jsondata -Credential $pscredential -Tenant $tenantId -ServicePrincipal 
        
}     
Catch {         
        $errMsg = $_.exception.message
        $start = $errMsg.IndexOf("Client with IP Address '") + 24
        $length = $errMsg.IndexOf("' is not allowed to access the server.") - $start
        if (($start -gt 24) -and ($length -ge 7)) {
            $startIPAddress = $errMsg.SubString($start, $length)
            $endIPAddress = $startIP
			Write-output "Deteccted IP " $startip, $endIP
        } else {
            Write-Host "##vso[task.logissue type=error;]Error during adding automatic firewall rule ($errMsg)"
            throw
        }
        Write-Output $StartIPAddress
        Write-Output $EndIPAddress
        RemoveCurrentServerFromASFirewall -Server $aasServer -AzContext $azContext -Credential $pscredential -Tenant $tenantId -ServicePrincipal 
	    $addedFirewallRule = AddCurrentServerToASFirewall -Server $aasServer -Credentials $pscredential -AzContext $azContext -StartIPAddress $startIPAddress -EndIPAddress $endIPAddress -FirewallRuleName $rule_name
        $result = Invoke-ASCmd -Server $aasServer -Query $jsondata -Credential $pscredential -Tenant $tenantId -ServicePrincipal 
 

      }
    
# Remove security Ids

 
 # Remove firewall rule
    Write-Verbose "Remove firewall rule"   
    RemoveCurrentServerFromASFirewall -Server $aasServer -AzContext $azContext
	