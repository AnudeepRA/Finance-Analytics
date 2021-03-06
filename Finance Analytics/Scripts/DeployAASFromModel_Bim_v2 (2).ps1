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
 
 




 Import-Module $PSScriptRoot\ImportPowershellModules\Az.Accounts
Import-Module $PSScriptRoot\ImportPowershellModules\DeployAASFromModel_Bim
Import-Module $PSScriptRoot\ImportPowershellModules\Az.KeyVault

Import-Module $PSScriptRoot\ImportPowershellModules\Az.AnalysisServices



  
#$azContext = Get-AzureRmContext
#get DevOPs Variables  Reads the varibles from DevOps
$ModelName =      $Env:ModelName
$Modelbim =       $Env:Modelbim
$ModelbimPath =   $Env:ModelbimPath
$KVSecrets   =    $env:KVSecrets
subscriptionName = $Env:SubscriptionName
#$KVSecrets    =    $env:azr-adw-dai-entdl-300
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
Write-host "Download KV:" $KVSecrets 
Write-Host "DBKeyVaultID ."  $DBKeyVaultID 
Write-Host "Model Path."  $ModelbimPath
Write-Host "Model Name."  $ModelName
Write-Host "DB Admin."    $dwhadmin
Write-Host "DS"           $Database_Source





# Read the Model.BIM 

# Get AAS credentals so the IP can be injected into the firewal 

write-host " KV-Secrets:" $KVSecrets

$currentAzureContext = Get-AzContext
$tenantId = '855b093e-7340-45c7-9f0c-96150415893e'
$spnpwd= ConvertTo-SecureString $spnpwd -AsPlainText -Force
$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($spn, $spnpwd)
$pscredential = New-Object System.Management.Automation.PSCredential($spn, $spnpwd)
Connect-AzAccount -Credential $pscredential -Tenant $tenantId -ServicePrincipal
$azContext = Get-AzContext

try
        {
        # Read Key Vault Secret for Azure Analysis Services 
		     
             $GetKVInfo =(Get-AzureKeyVaultSecret -Name $AASKeyVaultID  -VaultName kv-devops-aas-db).SecretValueText 
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
		$ipDetectionMethod = "autoDetect"
		$startIPAddress =""
		$endIPAddress = ""
        Write-Verbose "Set firewall"
		$environment = $aasServer.Split('/')[2];
		Write-host " Env: " $environment

        
         
        $result = Add-AzureAnalysisServicesAccount -Credential $pscredential -ServicePrincipal -TenantId $TenantId -RolloutEnvironment $environment
        
        # Remove firewall rule when the previous run ended if failure 
        #Write-Verbose "Remove firewall rule"
        #RemoveCurrentServerFromASFirewall -Server $aasServer -AzContext $azContext
        # add firewall rule
        $addedFirewallRule = AddCurrentServerToASFirewall -Server $aasServer -Credentials $pscredential -AzContext $azContext -IpDetectionMethod $ipDetectionMethod -StartIPAddress $startIPAddress -EndIPAddress $endIPAddress
        #write-host " result from Add-azureAnalysis " $result

# Read .asdatabase/.bim file as model
$model = ReadModel -ModelFile $ModelbimPath


# Rename model name
$model = RenameModel -Model $model -NewName $modelName
#$Model.model.dataSources.name -replace $model.model.dataSources.name, $KVDatabaseSourceName 

# Changing Datasource name and modifing partitions
$model.model.dataSources | Select-Object -Property name
$Results = $model.model.dataSources | Add-Member -NotePropertyName "name" $KVDatabaseSourceName  -force


$Model.model.tables.partitions.source | Select-Object -Property expression
$ModifyExpression = $Model.model.tables.partitions.source.expression
#$ModifyExpression = $ModifyExpression -replace $model.model.dataSources.name, $KVDatabaseSourceName 
$ChangeCount = 0
<# hold for now
foreach($ModifyExpression in $ModifyExpression) {
         #$ModifyExpression
         
        #If($ModifyExpression -like  "*SQL*") {
              $ModifyExpression = $ModifyExpression -replace $OLD_Partion_DB, $New_Partion_DB
              $ModifyExpression
              $ChangeCount = $ChangeCount + 1
            #}
            $Results = $Model.model.tables.partitions.source| Add-Member -NotePropertyName "expression"  $ModifyExpression -force
         }
$ChangeCount 





#$ModifyExpression  #>








#Apply DataSource Account Passowrd.  injecting a Sql Auth Account/Password 
  
 $connectionDetails = ConvertFrom-Json '{"connectionDetails":{"protocol":"tds","address":{"server":"server","database":"database"}}}'
 $credential = ConvertFrom-Json '{"credential":{"AuthenticationKind":"UsernamePassword","kind":"","path":"path","Username":"user","Password":"pass","EncryptConnection":true}}'
  $dataSources = $Model.model.dataSources
  #$dataSources.name -replace $model.model.dataSources.name, $KVDatabaseSourceNam
  $dataSources.name -replace $dataSources.name, "SQL/azr-sql-dai-entdl-300 database windows net;azr-adw-dai-entdl-300"
#$Model.model.tables.partitions.source.expression -replace $model.model.dataSources.name, $KVDatabaseSourceName 
  Write-host "datasources.name:" $dataSources.name
   foreach($dataSource in $dataSources) {
      if ($dataSource.type) {
          $connectionDetails.connectionDetails.protocol = $dataSource.connectionDetails.protocol
          $connectionDetails.connectionDetails.address.server = $KVDatabaseSource 
          $connectionDetails.connectionDetails.address.database = $KVDatabase
          $dataSource.credential = $credential.credential
          $dataSource.connectionDetails = $connectionDetails.connectionDetails
          $credential.credential.AuthenticationKind  = $KVAuthenKind
          $credential.credential.kind = $KVKind
          $credential.credential.path = $KVdwhpath
          $credential.credential.Password = $KVDBPassword
          $credential.credential.Username = $KVdwhadmin
          #$credential.credential.Username = "LXD"
          $dataSource.credential = $credential.credential
			
        }
     }








#$Model.model.dataSources.name = $name
Write-Host "print:" $model.model.dataSources.name
# Remove security Ids
$model = RemoveSecurityIds -Model $model
# Prepare Model for Deploymnet 
$Overwrite = "true"     
#$Server = "asazure://centralus.asazure.windows.net/azraasdaientdlfn300:rw"
           
$Server =$aasServer.Trim()
write-host "aasServer:" $Server
#$Server = "asazure://centralus.asazure.windows.net/azraasdaientdlfn300:rw"
#write-host "aasServer:" $Server
$createTsml = '{"create":{"database":{"name":"emptyModel"}}}' | ConvertFrom-Json
$updateTsml = '{"createOrReplace":{"object":{"database":"existingModel"},"database":{"name":"emptyModel"}}}' | ConvertFrom-Json

    if ($Overwrite -eq "true") {
        $tsml = $updateTsml
               $tsml.createOrReplace.object.database = $ModelName
        # $model.model.dataSources.name -replace $model.model.dataSources.name, $KVDatabaseSourceNam 
        $tsml.createOrReplace.database = $Model 
        Write-host $Model.model.tables.partitions.source.expression
    } else {
        $tsml = $createTsml
        #$model.model.dataSources.name -replace $model.model.dataSources.name, $KVDatabaseSourceNam
        $tsml.create.database = $Model
        
    }
$jsondata = ConvertTo-Json $tsml -Depth 100 -Compress

<#
$updateTsml = '{"createOrReplace":{"dataSource":{"name":"existingModel"}}}' | ConvertFrom-Json
Write-host " changed DS name:"  $tsml
$tsml = $updateTsml
# $tsml.createOrReplace.dataSources.name = $KVDatabaseSourceName
Write-host " changed DS name:"  $tsml.DatabaseSource.name
#>
# Process Model 
try {
            Write-Host "Model Path."  $Server
			
            $result = Invoke-ASCmd -Server $Server -Query $jsondata 
			} catch {        
			$errMsg = $_.exception.message   
			throw "Error during deploying the model ($errMsg)"     } 
  


	Write-Verbose "Remove model" 
    Write-Host "Results:"  $result
 
 # Remove firewall rule
    Write-Verbose "Remove firewall rule"
    RemoveCurrentServerFromASFirewall -Server $aasServer -AzContext $azContext
	