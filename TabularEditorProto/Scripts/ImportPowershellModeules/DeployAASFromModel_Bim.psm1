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
 




function ReadModel($ModelFile) {
    if ([string]::IsNullOrWhitespace($ModelFile) -eq $false `
                -and $ModelFile -ne $env:SYSTEM_DEFAULTWORKINGDIRECTORY `
                -and $ModelFile -ne [String]::Concat($env:SYSTEM_DEFAULTWORKINGDIRECTORY, "\")) {
        try {
            return Get-Content $ModelFile -Encoding UTF8 | ConvertFrom-Json
        } catch {
            $errMsg = $_.exception.message
            throw "Not a valid model file (.asdatabase/.bim) provided. ($errMsg)"
        }
    } else {
        $errMsg = $_.exception.message
        throw "No model file (.asdatabase/.bim) provided. ($errMsg)"
    }
}



function ReadDeployJSON{($DeployJSONfile) 
try {
            return Get-Content $DeployJSONfile  -Encoding UTF8 | ConvertFrom-Json
        } catch {
            $errMsg = $_.exception.message
            throw "1) Not a valid DB Deploy Json file  provided. ($errMsg)"
        }
    
   
 } 
    

  




function RemoveSecurityIds($Model) {
    $roles = $Model.model.roles
    foreach($role in $roles) {
        if ($role.members) {
            $role.members = @(($role.members | Select-Object -Property * -ExcludeProperty memberId))
        }
    }
    return $Model
}

function ProcessMessages($result) {
    $return = 0
    $resultXml = [Xml]$result
    $messages = $resultXml.return.root.Messages
    
    foreach($message in $messages) {
        $err = $message.Error
        if ($err) {
            $return = -1
            $errCode = $err.errorcode
            $errMsg = $err.Description
            Write-Host "##vso[task.logissue type=error;]Error: $errMsg (ErrorCode: $errCode)"
        }
        $warn = $message.Warning
        if ($warn) {
            if ($return -eq 0) {
                $return = 1
            }
            $warnCode = $warn.WarningCode
            $warnMsg = $warn.Description
            Write-Host "##vso[task.logissue type=warning;]Warning: $warnMsg (WarnCode: $warnCode)"
        }
    }

    return $return
}


function RenameModel($Model, $NewName) {
    if ([string]::IsNullOrWhitespace($NewName) -eq $false `
        -and [string]::IsNullOrEmpty($NewName) -eq $false) {
        $Model.name = $NewName
        $Model = ($Model | Select-Object -Property * -ExcludeProperty id) # Remove not needed Id property
        return $Model
    } else {
        return $Model
    }
}

#model -Server $DatabaseSource -Database $Database -UserName $dwhadmin -Password $dwhpwd
#function ApplySQLSecurity($Model, $Database_Source, $Database, $dwhadmin, $dwhpwd, $dwhpath) {
 function ApplySQLSecurity($model, $KVDatabaseSource, $KVDatabase, $KVdwhadmin, $KVDBPassword, $KVKind, $KVAuthenKindm, $KVdwhpath) {
     
    
    <#$connectionDetails = ConvertFrom-Json '{"connectionDetails":{"protocol":"tds","address":{"server":"server","database":"database"}}}'
    $credential = ConvertFrom-Json '{"credential":{"AuthenticationKind":"UsernamePassword","kind":"kind","path":"path","Username":"user","Password":"pass","EncryptConnection":true}}'
    $dataSources = $Model.model.dataSources
	write-host "dS in function" , $Database_Source
	write-host "db" , $Database
	write-host "path" , $dwhpath

    foreach($dataSource in $dataSources) {
        if ($dataSource.type) {
            $connectionDetails.connectionDetails.protocol = $dataSource.connectionDetails.protocol
            $connectionDetails.connectionDetails.address.server = $Database_Source 
            $connectionDetails.connectionDetails.address.database = $Database
            $dataSource.connectionDetails = $connectionDetails.connectionDetails
            $credential.credential.kind = $dataSource.credential.kind
            $credential.credential.EncryptConnection = $dataSource.credential.EncryptConnection
            $credential.credential.AuthenticationKind = $dataSource.credential.AuthenticationKind
            
			$credential.credential.path = $dwhpath
            
            $credential.credential.Password = $dwhpwd
			$credential.credential.Username = $dwhadmin
            
            $dataSource.credential = $credential.credential
			
        }
    } #>
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
         $Model.model.dataSources = $dataSources
         #Update the Data Base Source Name
     $Model.model.dataSources.name -replace $model.model.dataSources.name, $KVDatabaseSourceName 
     #Update Partions to the Proper Datasouce connectionDetails
     $Model.model.tables.partitions.source.expression -replace $model.model.dataSources.name, $KVDatabaseSourceName 
    # $write-host  $Model.model.tables.partitions.source.expression
    
    return $Model
}


function AddCurrentServerToASFirewall{($aasServer, $Credentials, $AzContext, $IpDetectionMethod,  $StartIPAddress, $EndIPAddress) 
    Write-host "AZCOnext in side of Function"   $AzContext   
   $qry = "<Discover xmlns='urn:schemas-microsoft-com:xml-analysis'><RequestType>DISCOVER_PROPERTIES</RequestType><Restrictions/><Properties/></Discover>"
   $aasServerName = $aasServer.Split('/')[3];
	$aasServerNameWithoutRW, $notneeded =  $aasServerName.Split(':')
	write-host " without RW: " $aasServerNameWithoutRW
    $added = $false

    switch ($IpDetectionMethod) {
        "ipAddressRange" {
            $startIP = $StartIPAddress
            $endIP = $EndIPAddress
        }
        "autoDetect" {
            try {
                if ($Credentials -eq $null) {
                    $result = Invoke-ASCmd -Server $aasServer -Query $qry
                } else {
				    Write-Host " Try: " , $aasServer , " cred:" $Credentials
                    $result = Invoke-ASCmd -Server $aasServer -Query $qry -Credential $Credentials
                }
            } catch {
                $errMsg = $_.exception.message
                $start = $errMsg.IndexOf("Client with IP Address '") + 24
                $length = $errMsg.IndexOf("' is not allowed to access the server.") - $start
                if (($start -gt 24) -and ($length -ge 7)) {
                    $startIP = $errMsg.SubString($start, $length)
                    $endIP = $startIP
					Write-host "Deteccted IP " $startip, $endIP
                } else {
                    Write-Host "##vso[task.logissue type=error;]Error during adding automatic firewall rule ($errMsg)"
                    throw
                }
            }
        }
    }
   # if (($null -ne $startIP) -and ($null -ne $endIP)) {
        try {
            $added = $true
            Write-Verbose "Remove firewall rule: ts-release-aas-rule if it was left over from a failed run"
            RemoveCurrentServerFromASFirewall -Server $aasServer -AzContext $azContext
             Write-Host " Try: " , $aasServer , " cred:" $Credentials " Servername: "  $aasServerNameWithoutRW   
			$currentConfig = (Get-AzAnalysisServicesServer -Name $aasServerNameWithoutRW -DefaultProfile $AzContext)[0].FirewallConfig
            $currentFirewallRules = $currentConfig.FirewallRules
            $firewallRule = New-AzAnalysisServicesFirewallRule -FirewallRuleName 'vsts-release-aas-rule' -RangeStart $startIP -RangeEnd $endIP -DefaultProfile $AzContext
           
            $currentFirewallRules.Add($firewallRule)
            if ($currentConfig.EnablePowerBIService) {
                $firewallConfig = New-AzAnalysisServicesFirewallConfig -FirewallRule $currentFirewallRules -EnablePowerBIService -DefaultProfile $AzContext
            } else {
                $firewallConfig = New-AzAnalysisServicesFirewallConfig -FirewallRule $currentFirewallRules -DefaultProfile $AzContext
            }
            write-host " I think we are going to add a new FW rule"
			$result = Set-AzAnalysisServicesServer -Name $aasServerNameWithoutRW -FirewallConfig $firewallConfig -DefaultProfile $AzContext
        } catch {
            $errMsg = $_.exception.message
            Write-Host "##vso[task.logissue type=error;]Error during adding firewall rule ($errMsg)"
            throw
        }
    #}
	$addedFirewallRule = $added
    return $added
}
 
 
function RemoveCurrentServerFromASFirewall {($aasServer, $AzContext) 
    $aasServerName = $aasServer.Split('/')[3];
	$aasServerNameWithoutRW, $notneeded =  $aasServerName.Split(':')
	 write-host " Removing Client Firewall Rule Started" 
	
    <#try {
        $currentConfig = (Get-AzAnalysisServicesServer -Name $aasServerNameWithoutRW -DefaultProfile $AzContext)[0].FirewallConfig
        $newFirewallRules = $currentConfig.FirewallRules
        $newFirewallRules.RemoveAll({ $args[0].FirewallRuleName -eq "vsts-release-aas-rule" })
				if ($currentConfig.EnablePowerBIService) {
					$firewallConfig = New-AzAnalysisServicesFirewallConfig -FirewallRule $newFirewallRules -EnablePowerBIService -DefaultProfile $AzContext
					write-host " Removing Client Firewall Rule Completed 1" 
				}
				else {
					$firewallConfig = New-AzAnalysisServicesFirewallConfig -FirewallRule $newFirewallRules -DefaultProfile $AzContext
					write-host " Removing Client Firewall Rule Completed 2" 
				}
        {$result = Set-AzAnalysisServicesServer -Name $aasServerNameWithoutRW -FirewallConfig $firewallConfig -DefaultProfile $AzContext
        write-host " Removing Client Firewall Rule Completed 3" 
			}
		} catch {
        $errMsg = $_.exception.message
		Write-Host " hitting here also 1"
        Write-Host "##vso[task.logissue type=error;]Error during removing firewall rule ($errMsg)"
        throw 
    }#>


    try {
        $currentConfig = (Get-AzAnalysisServicesServer -Name $aasServerNameWithoutRW -DefaultProfile $AzContext)[0].FirewallConfig
        $newFirewallRules = $currentConfig.FirewallRules
        $newFirewallRules.RemoveAll({ $args[0].FirewallRuleName -eq "vsts-release-aas-rule" })
        if ($currentConfig.EnablePowerBIService) {
            $firewallConfig = New-AzAnalysisServicesFirewallConfig -FirewallRule $newFirewallRules -EnablePowerBIService -DefaultProfile $AzContext
            write-host " Removing Client Firewall Rule Completed" 
		}
		else {
            $firewallConfig = New-AzAnalysisServicesFirewallConfig -FirewallRule $newFirewallRules -DefaultProfile $AzContext
			#write-host " Removing Client Firewall Rule Completed" 
        }
        $result = Set-AzAnalysisServicesServer -Name $aasServerNameWithoutRW -FirewallConfig $firewallConfig -DefaultProfile $AzContext
        write-host " Removing Client Firewall Rule Completed" 
			} catch {
        $errMsg = $_.exception.message
        Write-Host "##vso[task.logissue type=error;]Error during removing firewall rule ($errMsg)"
        throw
    }


}


#Deploy Model function
	function DeployModel($Server, $Command, $LoginType, $Credentials) {
    try {
        switch ($LoginType) {
            "user" {
                $result = Invoke-ASCmd -Server $Server -Query $Command -Credential $Credentials
            }
            "spn" {
                $result = Invoke-ASCmd -Server $Server -Query $Command
            }
        }
        return ProcessMessages($result)
    } catch {
        $errMsg = $_.exception.message
        throw "Error during deploying the model ($errMsg)"
    }
}

function GetKeyVault{($DBKeyVaultID) 
     try
        {
        # Read Key Valut 
		     #$DBKeyVaultID = 'azr-adw-dai-entdl-700'
             $GetKVInfo =(Get-AzureKeyVaultSecret -Name $DBKeyVaultID  -VaultName kv-devops-aas-db).SecretValueText 
             $AuthenticationKind,$Database,$DatabaseSource,$dwhadmin,$dwhpwd,$dwhpath = $GetKVInfo.split("|")
             
             Write-Host " Secrets Retreived For: " $Database
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
		write-Host "from function kv Path:" $dwhpath
		write-Host "from function kv admin:" $dwhadmin
        Return ($AuthenticationKind,$Database,$DatabaseSource,$dwhadmin,$dwhpwd,$dwhpath)
		
        #ProcessMessages($result)

}


