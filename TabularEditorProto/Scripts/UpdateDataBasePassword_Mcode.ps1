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
        
       
       write-host " azcontext " $SubscriptionName

# Read .asdatabase/.bim file as model
$model = ReadModel -ModelFile $ModelbimPath


try {      
            $DBDeployJSON = Get-Content $DBDeployJSONfile -Encoding UTF8 | ConvertFrom-Json
           # return Get-Content 'Deploy_db_azr-adw-dai-entdl-300_credential.json' -Encoding UTF8 | ConvertFrom-Json
        } catch {
            $errMsg = $_.exception.message
            throw "1) Not a valid DB Deploy Json file  provided. ($errMsg)"
        }



# Rename model name
# Rename model name
$model = RenameModel -Model $model -NewName $modelName




write-output "JSON file:" $DBDeployJSON
	

#Main Processing 
# New Update DB Passowrd Logic

 
$connectionDetails = $DBDeployJSON
 #$connectionDetails = ConvertFrom-Json $DBDeployJSON
 # $UpdatePasswordTMSL = $connectionDetails | ConvertTo-Json
 $connectionDetails.createOrReplace.object.database =   $ModelName
$connectionDetails.createOrReplace.dataSource.credential.AuthenticationKind = "UsernamePassword"
$connectionDetails.createOrReplace.dataSource.credential.Username = $Username
$connectionDetails.createOrReplace.dataSource.credential.Password = $DBPassword
#$connectionDetails.createOrReplace.dataSource.credential.EncryptConnection = true
$tsml =  $connectionDetails 
write-output $connectionDetails.createOrReplace.dataSource.credential.AuthenticationKind  
Write-output $connectionDetails.createOrReplace.dataSource.credential.Username  
 
#$tsml = $updateTsml
$jsondata = ConvertTo-Json $tsml -Depth 100 -Compress
#$jsondata  = $tsml
write-Output " json USerName " $tsml.createOrReplace.dataSource.credential.Username
write-Output " json AuthKind " $tsml.createOrReplace.dataSource.credential.AuthenticationKind
$lookatJson = ConvertFrom-json $jsondata 

write-output "JSON lookat "  "$lookatJson" 
# Process Password

  
try {
        $result = Invoke-ASCmd -Server $aasServer -Query $jsondata -Credential $pscredential -Tenant $tenantId -ServicePrincipal 
        write-output "Process DB Credentials"  
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
         write-output "Process DB Credentials after Catch" 
 

      }
    
# Remove security Ids

 
 # Remove firewall rule
    Write-Verbose "Remove firewall rule"
    RemoveCurrentServerFromASFirewall -Server $aasServer -AzContext $azContext
	