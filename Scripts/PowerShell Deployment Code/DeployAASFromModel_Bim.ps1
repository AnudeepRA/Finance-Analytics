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
 



 Import-Module $PSScriptRoot\ImportPowershellModules\Az.Accounts
Import-Module $PSScriptRoot\ImportPowershellModules\DeployAASFromModel_Bim
#Import-Module $PSScriptRoot\ImportPowershellModules\Az.profile
#Import-Module $PSScriptRoot\ImportPowershellModules\Azure.AnalysisServices
#Import-Module $PSScriptRoot\ImportPowershellModules\Az.AnalysisServices
Import-Module $PSScriptRoot\ImportPowershellModules\Az.KeyVault

Import-Module $PSScriptRoot\ImportPowershellModules\Az.AnalysisServices


  
#$azContext = Get-AzContext
#get DevOPs Variables  Reads the varibles from DevOps
$ModelName =      $Env:ModelName
$Modelbim =       $Env:Modelbim
$ModelbimPath =   $Env:ModelbimPath
$KVSecrets   =   $Env:KVSQLSecrets
$subscriptionName = $Env:SubscriptionName
#$dwhpath =        $env:dwhpath
#$dwhadmin =       $Env:dwhadmin
#$dwhpwd =         $Env:dwhpwd
#$Database_Source = $Env:DatabaseSource
$spn =            $env:SPN_AzureAnalysisServicesAdmin
$spnpwd =         $env:SPN_AzureAnalysisServicesAdmin_PWD
#$Database =       $Env:Database
$aasServer =      $env:Server
$DBKeyVaultID =   $env:DWHKeyVault
$AASKeyVaultID =  $env:ASKeyVaultID
Write-Host "DBKeyVaultID ."  $DBKeyVaultID 
Write-Host "Model Path."  $ModelbimPath
Write-Host "Model Name."  $ModelName
Write-Host "DB Admin."    $dwhadmin
Write-Host "DS"           $Database_Source
Write-Host "Subscription" $subscriptionName

 


# Read the Model.BIM 

# Get AAS credentals so the IP can be injected into the firewal 

write-host " KV-Secrets:" $KVSecrets

#$currentAzureContext = Get-AzContext
$tenantId = '855b093e-7340-45c7-9f0c-96150415893e'
$spnpwd= ConvertTo-SecureString $spnpwd -AsPlainText -Force
$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($spn, $spnpwd)
$pscredential = New-Object System.Management.Automation.PSCredential($spn, $spnpwd)
#Connect-AzAccount -Credential $pscredential -Tenant $tenantId -ServicePrincipal
Connect-AzAccount -Credential $pscredential -Tenant $tenantId   -ServicePrincipal
Write-host " Using  Context"

try
        {
        # Read Key Vault Secret for Azure Analysis Services 
		     Set-AzContext -Subscription "az2i-0022-Analytics Internal Development-HQTRS-055"
             $GetKVInfo =(Get-AzKeyVaultSecret -Name $AASKeyVaultID  -VaultName kv-devops-aas-db).SecretValueText 
             $KVASSSPNAdmin,$KVAASSPNPassword ,$KVTenantid = $GetKVInfo.split("|")
            
             Write-Host " Secrets Retreived For: " $KVDatabaseSourceName
        }
        catch [System.Net.WebException]
        {
           Write-Host "Catch  KeyValut Error "
        }
        catch
        {
          Write-Host "Catch Catch"  $GetKVInfo.SecretValueText
          Write-Host "An error occurred that could not be resolved."
        }  


		#$GetKVInfo =(Get-AzureKeyVaultSecret -Name $DBKeyVaultID  -VaultName kv-devops-aas-db).SecretValueText 
		write-Host "from function kv Path:" $KVASSSPNAdmin
		 


$FieldName_KVASSSPNAdmin ,$KVASSSPNAdmin                         =      $KVASSSPNAdmin.split(":")
$FieldName_KVAASSPNPassword,$KVAASSPNPassword                     =     $KVAASSPNPassword.split(":")
$spn                                                              =     $KVASSSPNAdmin
$spnpwd                                                           =     $KVAASSPNPassword




try
        {
        # Read Key Vault for Database
		     #$DBKeyVaultID = 'azr-adw-dai-entdl-700'
             $GetKVInfo =(Get-AzureKeyVaultSecret -Name $DBKeyVaultID  -VaultName kv-devops-aas-db).SecretValueText 
             $AuthenticationKind,$Database,$DatabaseSource,$dwhadmin,$dwhpwd,$dwhpath,$kind,$DatabaseSourceName = $GetKVInfo.split("|")
              # Read Key Valut 
            # $GetKVInfo =(Get-AzKeyVaultSecret -Name $DBKeyVaultID  -VaultName kv-devops-aas-db).SecretValueText 
            # $KVAuthenKind,$KVDatabase,$KVDatabaseSource,$KVdwhadmin,$KVDBPassword,$KVdwhpath,$KVkind,$KVDatabaseSourceName = $GetKVInfo.split("|")
          
             Write-Host " Secrets Retreived For: " $KVDatabaseSourceName
        }
        catch [System.Net.WebException]
        {
           Write-Host "Catch  KeyValut Error "
        }
        catch
        {
          Write-Host "Catch Catch"  $GetKVInfo.SecretValueText
          Write-Host "An error occurred that could not be resolved."
        }  


		#$GetKVInfo =(Get-AzureKeyVaultSecret -Name $DBKeyVaultID  -VaultName kv-devops-aas-db).SecretValueText 
		write-Host "from function kv Path:" $KVdwhpath
		write-Host "from function kv admin:" $KVdwhadmin


$FieldName_DBPassword ,$KVDBPassword                          =     $dwhpwd.split(":")
$FieldName_dwhpath,$KVdwhpath                                 =     $dwhpath.split(":")
$FieldName_dwhadmin,$KVdwhadmin                               =     $dwhadmin.split(":")
$FieldName_DatabaseSource,$KVDatabaseSource                   =     $DatabaseSource.split(":")
$FieldName_Databaase,$KVDatabase                              =     $Database.split(":")
$FieldName_AuthenticationKind,$KVAuthenKind                   =     $AuthenticationKind.split(":")
$FieldName_KVkind,$KVkind                                     =     $kind.split(":")
$FieldName_KVDatabaseSourceName,$KVDatabaseSourceName         =     $DatabaseSourceName.split(":")


 
#$KVAuthenKind                  =     "UsernamePassword"
Write-Host " Secrets Retreived  " $KVDatabase 
Write-Host "This is KVPath:"  $KVdwhpath
Write-Host "This is KVAdmin:" $KVdwhadmin
Write-Host "This is KVDS:" $KVDatabaseSource
Write-Host "This is KVDB:" $KVDatabase
Write-Host "This is KVauthenkind:" $KVAuthenKind
Write-Host "This is KVkind:" $KVKind
Write-Host "This is KVDSName:" $KVDatabaseSourceNAme

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
        $result = Add-AzAnalysisServicesAccount -Credential $pscredential -ServicePrincipal -TenantId $TenantId -RolloutEnvironment $environment
       #$addedFirewallRule = AddCurrentServerToASFirewall -Server $aasServer -Credentials $pscredential -AzContext $azContext -IpDetectionMethod $ipDetectionMethod -StartIPAddress $startIPAddress -EndIPAddress $endIPAddress
        
       
       write-host " azcontext " $SubscriptionName

# Read .asdatabase/.bim file as model
$model = ReadModel -ModelFile $ModelbimPath

# Rename model name
$model = RenameModel -Model $model -NewName $modelName





#Apply DataSource Account Passowrd.  injecting a Sql Auth Account/Password 
    
$connectionDetails = ConvertFrom-Json '{"connectionDetails":{"protocol":"tds","address":{"server":"server","database":"database"}}}'
 $credential = ConvertFrom-Json '{"credential":{"AuthenticationKind":"UsernamePassword","kind":"","path":"path","Username":"user","Password":"pass","EncryptConnection":true}}'
  $dataSources = $Model.model.dataSources
  $partition = $Model.model.Partition
    
	<#write-host "dS in function" , $Database_Source
	write-host "db" , $Database
	write-host "path" , $dwhpath
	write-host "dwhadmin" , $dwhadmin #>
#Write-host "display the model" $model.model.
	 
	#write-host "Paret"  $partition 
	
   foreach($dataSource in $dataSources) {
      if ($dataSource.type) {
          $connectionDetails.connectionDetails.protocol = $dataSource.connectionDetails.protocol
          $connectionDetails.connectionDetails.address.server = $KVDatabaseSource 
          $connectionDetails.connectionDetails.address.database = $KVDatabase
          $dataSource.connectionDetails = $connectionDetails.connectionDetails
          $credential.credential.AuthenticationKind  = $KVAuthenKind
          $credential.credential.kind = $KVKind
          $credential.credential.path = $KVdwhpath
          $credential.credential.Password = $KVDBPassword
          $credential.credential.Username = $KVdwhadmin
          $dataSource.credential = $credential.credential
			
        }
     }


	

#Main Processing 



# Remove security Ids
$model = RemoveSecurityIds -Model $model
# Prepare Model for Deploymnet 
$Overwrite = "true"     
$Server = "asazure://centralus.asazure.windows.net/azraasdaientdlfn300:rw"
$createTsml = '{"create":{"database":{"name":"emptyModel"}}}' | ConvertFrom-Json
$updateTsml = '{"createOrReplace":{"object":{"database":"existingModel"},"database":{"name":"emptyModel"}}}' | ConvertFrom-Json

    if ($Overwrite -eq "true") {
        $tsml = $updateTsml
        $tsml.createOrReplace.object.database = $ModelName
        $tsml.createOrReplace.database = $Model 
    } else {
        $tsml = $createTsml
        $tsml.create.database = $Model
        
    }
$jsondata = ConvertTo-Json $tsml -Depth 100 -Compress


# Process Model 
<#
try {
            Write-Host "Model Path."  $Server
			
            $result = Invoke-ASCmd -Server $Server -Query $jsondata 
			} catch {        
			$errMsg = $_.exception.message   
			throw "Error during deploying the model ($errMsg)"     } 
  

  #>
try {
        $result = Invoke-ASCmd -Server $Server -Query $jsondata -Credential $pscredential -Tenant $tenantId -ServicePrincipal 
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
        $result = Invoke-ASCmd -Server $Server -Query $jsondata -Credential $pscredential -Tenant $tenantId -ServicePrincipal 
 

      }

	Write-Verbose "Remove model" 
    Write-Host "Results:"  $result
 
 # Remove firewall rule
    Write-Verbose "Remove firewall rule"
    RemoveCurrentServerFromASFirewall -Server $aasServer -AzContext $azContext
	