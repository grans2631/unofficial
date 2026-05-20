Function Write-POpsLog {
    <# 
    .SYNOPSIS 
       Write to a log file and to console if desired
 
    .DESCRIPTION 
       Write to a log file and to console if desired.
       Can write to regular text file or in CMTrace format.
 
    .EXAMPLE 
        Try{
            Get-Process -Name DoesnotExist -ea stop
        }
        Catch{
            Write-POpsLog -Logfile "C:\output\logfile.log" -Message $_ -MessageType Error
            Throw
        }
 
       This will write a line to the c:\output\logfile.log with error object details,
       and will also write back the error to the host.
       You will need to add a throw in the catch block if you want to rethrow the error.
 
    .EXAMPLE
        Set this preference at the top of your script:
        $POpsLogFile = "c:\output\logfile.log"
        $POpsWriteHost = $true
        
        Write-POpsLog -Message "This is a verbose message." 
        This example will write a verbose entry into the log file and also write back to the host. 
        If the -WriteHost switch is not specified, it will then just follow the value $VerbosePreference,
        and write the verbose message back to the host only if $VerbosePreference is set to 'Continue'.
    .EXAMPLE
        Set this preference at the top of your script:
        $POpsLogFile = "c:\output\logfile.log"
        $POpsWriteHost = $false
        
        Write-POpsLog -Message "This is a verbose message." 
        This example will write a verbose entry into the log file but will not write back to the host.
    .EXAMPLE
        Function Test{
            [cmdletbinding()]
            Param()
            Write-POpsLog -Message "This is a verbose message" -MessageType Verbose
        }
        Test -Verbose
        This example shows how to use Write-POpsLog inside a function and then call the function with the -verbose switch.
        The Write-POpsLog function will then print the verbose message on the host.
    
    .Parameter LogFile
        If LogFile is not specified, will then save the log file to "$Env:windir\Temp\Write-POpsLog" 
        
        You can specify $Script:POpsLogFile = "C:\Logs\YourLogFile.log" at the top of your main script,
        to avoid having to specify the LogFile parameter every time you call the function.
    .Parameter WriteHost       
        You can specify $Script:POpsWriteHost = $true or $false at the top of your main script,
        to avoid having to specify the -WriteHost switch parameter every time you call the function.
    .NOTES
        Author: Isaac D Sofer
   
#> 
    [CmdletBinding(SupportsShouldProcess = $false)] 
    Param(
        [parameter(Position = 0, Mandatory = $True)] 
        $Message,   
        
        [parameter(Mandatory = $false)]      
        [String]$LogFile = $Script:POpsLogFile,
        [parameter(Mandatory = $false)]
        [ValidateSet('Warning', 'Error', 'Verbose', 'Debug', 'Information', 'Output')] 
        [Alias('Type')]
        [String]$MessageType = 'Verbose',
        [parameter(Mandatory = $false)]
        [ValidateSet('Basic', 'CMTrace')] 
        [String]$LogFormat = 'Basic',
        #Write back to the console or just to the log file. 
        [parameter(Mandatory = $false)]
        [Alias('WriteBackToHost')]
        [switch]$WriteHost = $Script:POpsWriteHost
    )
    
    Try {
        If ($null -eq $WriteHost -or '' -eq $WriteHost -or $WriteHost -eq $false) {
            $WriteHost = $false
        }
        #Get preferences
        $CurWarningPref = $PSCmdlet.GetVariableValue('WarningPreference')
        $CurErrActPref = $PSCmdlet.GetVariableValue('ErrorActionPreference')
        $CurVbosPref = $PSCmdlet.GetVariableValue('VerbosePreference')
        $CurDbgPref = $PSCmdlet.GetVariableValue('DebugPreference')
        $CurInfoPref = $PSCmdlet.GetVariableValue('InformationPreference')
        #Get the info about the calling script, function etc
        $CallingInfo = (Get-PSCallStack)[1]
    
        #Set Source Information
        #$Source = (Get-PSCallStack)[1].Location
        $Source = "$($MyInvocation.ScriptName | Split-Path -Leaf -ErrorAction SilentlyContinue):$($MyInvocation.ScriptLineNumber)"
        $MessageType = $MessageType.ToUpper()
        #Set Component Information
        $Component = (Get-Process -Id $PID).ProcessName
        #Set PID Information
        $ProcessID = $PID
        #Obtain UTC offset 
        $UtcOffset = [timezone]::CurrentTimeZone.GetUtcOffset([datetime]::Now).TotalMinutes
        $CurTimeHostFormat = $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
        If ( $null -eq $LogFile -or $LogFile -eq '') {
            $LogDir = "$Env:windir\Temp\Write-POpsLog"
            $LogFile = $LogDir + '\Log_'
            If ( $null -eq $CallingInfo.Command -or $CallingInfo.Command -like '<*>') {
                $LogFile = ($LogFile + 'Console.log')
            }
            Else {
                $LogFile = ($LogFile + $($CallingInfo.Command) + '.log')
            }
        }
        $LogDir = Split-Path -Path $LogFile
        $LogPathExists = Test-Path -Path $LogDir
        If ( $LogPathExists -eq $false ) {
            $null = New-Item -Path $LogDir -Type Directory -Force -WhatIf:$false
        }
    
        $HostMessage = @"
$CurTimeHostFormat [$MessageType]: $Message
"@
        $CMTraceMessage = $Message
        Switch ($MessageType) {    
            'Warning' {
                $Severity = 2
                if ($WriteHost -eq $true) {
                    $WarningPreference = 'Continue'
                }
                Write-Warning -Message $HostMessage
                $WarningPreference = $CurWarningPref
            }
            'Error' {  
                $Severity = 3
                if ($null -ne $Message.Exception.Message) {
                    $ErrObj = [pscustomobject]@{
                        Time              = $CurTimeHostFormat
                        Category          = $Message.CategoryInfo.Category
                        Reason            = $Message.CategoryInfo.Reason
                        Activity          = $Message.CategoryInfo.Activity
                        TargetName        = $Message.CategoryInfo.TargetName
                        TargetMessageType = $Message.CategoryInfo.TargetMessageType
                        MyCommand         = $Message.InvocationInfo.MyCommand         
                        BoundParameters   = $Message.InvocationInfo.BoundParameters
                        UnboundArguments  = $Message.InvocationInfo.UnboundArguments
                        ScriptName        = $Message.InvocationInfo.ScriptName
                        ScriptLineNumber  = $Message.InvocationInfo.ScriptLineNumber
                        OffsetInLine      = $Message.InvocationInfo.OffsetInLine
                        InvocationName    = $Message.InvocationInfo.InvocationName
                        PSScriptRoot      = $Message.InvocationInfo.PSScriptRoot
                        PSCommandPath     = $Message.InvocationInfo.PSCommandPath
                        Thrown            = $Message.Exception.WasThrownFromThrowStatement
                        Message           = $Message.Exception.Message
                    }
                    $HostMessage = @"
$CurTimeHostFormat [$MessageType]: [$Source]: $Message `n$($ErrObj | Out-String)
"@ 
                    $CMTraceMessage = $Message.Exception.Message
                }
                Else {
                    $HostMessage = @"
$CurTimeHostFormat [$MessageType]: [$Source]: $Message
"@         
                }
                Write-Host $HostMessage -ForegroundColor Red -BackgroundColor Black
                break
            }
            'Verbose' {  
                $Severity = 4
                if ($WriteHost -eq $true) {
                    $VerbosePreference = 'Continue'
                }
                Write-Verbose -Message $($HostMessage)
                $VerbosePreference = $CurVbosPref   
                break                            
            }
            'Debug' {  
                $Severity = 5
                if ($WriteHost -eq $true) {
                    $DebugPreference = 'Continue'
                }
                Write-Debug -Message $($HostMessage)
                $DebugPreference = $CurDbgPref
                break          
            }      
            'Information' {  
                $Severity = 6
                if ($WriteHost -eq $true) {
                    $InformationPreference = 'Continue'
                }
                Write-Information -Message "$($HostMessage)"
                $InformationPreference = $CurInfoPref
                break
            }
            'Output' {
                $Severity = 6
                $HostMessage = @"
$CurTimeHostFormat [$MessageType]: $($Message | Out-String) 
"@ 
                $CMTraceMessage = $($Message | Format-List | Out-String)
                Write-Output -InputObject $Message
                break
            }
            Default {}
        }#EndSwitch
        If ($LogFormat -eq 'CMTrace') {
            $LogLine = @"
<![LOG[$($MessageType.ToUpper()): $CMTraceMessage]LOG]!>
<time="$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)" 
date="$(Get-Date -Format MM-dd-yyyy)" 
component="$Component" 
context="$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" 
MessageType="$severity" 
thread="$processid" 
file="$source"> 
"@
            $LogLine = $LogLine.Replace("$([environment]::NewLine)", "")
        }
    
        Else {
            $LogLine = $HostMessage
        }
    
        Try {            
            $LogLine | Out-File -Append -Encoding utf8 -FilePath $LogFile -Force -ErrorAction Stop -WhatIf:$false
        }
        Catch {
            Write-Host ("Error saving log: [$($_.Exception.Message)]") -ForegroundColor Red -BackgroundColor Black
        }
    }
    Catch {
        Throw
    }
    Finally {
        # Always revert the preference variables 
        # back to original settings, even if Ctrl + C is pressed, or execution ends.
        $VerbosePreference = $CurVbosPref
        $WarningPreference = $CurWarningPref 
        $DebugPreference = $CurDbgPref
        $InformationPreference = $CurInfoPref
    }
    
}
Function Unzip {
    param(
        [string]$zipfile, 
        [string]$outpath
    )
    #Extract File powershell funtion
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Write-POpsLog -Message "Extracting [$($zipfile)] to [$($outpath)]"
    #$null = Remove-Item -Path $outpath -Recurse -Exclude $zipfile -Force -ErrorAction SilentlyContinue
    $null = [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}
Function Invoke-POpsDownload {
    <# 
    .SYNOPSIS 
       Downloads file with net
 
    .DESCRIPTION 
       Downloads file with net, creates destination directory if doesn't exist,
       "-SkipSsl" Skips certificate check which helps download issues with older versions of 
       net framework.
       Recommend to refrain use of switch -SkipSSL for security.
       "-ExpandArchive" extracts a zip file for you to the parent folder of the file path.
       "-Force" overwrites downloaded file if already exists, and if "-ExpandArchive" is specified will overwrite destination for expansion.
    .NOTES
       Author: Isaac D Sofer
   
#> 
 
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [uri]$Url,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Path')]
        [string]$FilePath,
        [Parameter(Mandatory = $false)]
        [Switch]$SkipSslCheck = $false,
        [Parameter(Mandatory = $false)]
        [switch]$ExpandArchive,
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    Begin {
        # Credit to https://stackoverflow.com/a/38729034 for code to ignore ssl certificate errors
        if ( !( [System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback'.Type ) -and $SkipSslCheck -eq $true) {
            $CertCallback = @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
            Try {
                Add-Type $CertCallback -ErrorAction Stop
                $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
                [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
                [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy -ErrorAction Stop              
                Write-POpsLog "Skipping Certificate Check"
            }
            Catch {
                Write-POpsLog "Error encountered when attempting to add CertCallBack class type" -Type Error
                Write-POpsLog -Message $_ -Type Error
                Write-POpsLog "Attempting to download without Skip SSL" -Type Warning
            }
        }
    }
    Process {
        $FileExists = Test-Path -Path $FilePath
        If ($FileExists -eq $true -and $Force -eq $false) {
            Write-POpsLog "File [$($FilePath)] already exists and '-Force' parameter was not specified." -Type Warning
            # Break results in script terminating, 
            # return results in function ending and script resuming.
            return
        }
        $FolderPath = Split-Path -Path $FilePath -Parent
        if ( !(Test-Path -Path $FolderPath) ) {
            Try {
                Write-POpsLog "Creating new folder: [$($FolderPath)]"
                $null = New-Item -Path $FolderPath -Type Directory -ErrorAction Stop;
            }
            Catch {
                Write-POpsLog "Error creating folder: [$($FolderPath)]" -Type Error
                Write-POpsLog -Message $_ -Type Error
                Throw 
            }
        }
        Try {
            $DlObj = New-Object System.Net.WebClient -ErrorAction Stop
            Write-POpsLog "Downloading file from url [$($Url)]"
            $DlObj.DownloadFile($Url, $FilePath)
        }
        Catch {
            Write-POpsLog -Message "Error downloading file" -Type Error
            Write-POpsLog -Message $_ -Type Error
            Throw
        }
        $DlSuccess = Test-Path -Path $FilePath
        If ($DlSuccess -eq $true) {
            Write-POpsLog "File downloaded successfully to: [$($FilePath)]"
            $CmdletExists = [bool](Get-Command -Name Unblock-File -ErrorAction SilentlyContinue)
            If ($CmdletExists -eq $true) {
                Write-POpsLog "Unblocking file: [$($FilePath)]"          
                Unblock-File -Path $FilePath
            }
        }
        Else {
            Write-POpsLog -Message "Unknown error downloading file" -Type Error
            Throw "Unknown error downloading file"
        }
        If ($ExpandArchive -eq $true) {
            $CmdletExists = $null
            $CmdletExists = Get-Command -Name Expand-Archive -ErrorAction SilentlyContinue
            
            If ($FilePath -like "*.zip") {
                $DestPath = $FilePath -replace '.zip', ''
                
                If ($CmdletExists) {
                    Try {               
                        Write-POpsLog -Message "Expanding file [$($FilePath)] to [$($DestPath)]"
                        $null = Expand-Archive -Path $FilePath -DestinationPath $DestPath -Force:$Force -ErrorAction Stop
                    }
                    Catch {
                        Write-POpsLog -Message "Error expanding archive" -Type Error
                        Write-POpsLog -Message $_ -Type Error
                        Throw
                    }
                }
                Else {
                    Write-POpsLog -Message "[Expand-Archive] cmdlet not found. Trying alternate function" -Type Warning
                    $null = Unzip -zipfile $FilePath -outpath $DestPath
                }
            }
            Else {
                Write-POpsLog -Message "File extension not .zip, cannot expand archive." -Type Warning
            }            
        }
    }
}
Function Validate-Variable {
    Param (
        [string[]]$Name,
        [switch]$AbortIfInvalid
    )
    $ObjResults = ForEach ($item in $Name) {
        $IsValid = $true
        Try {
            $VarInfo = Get-Variable -Name $item -ErrorAction Stop
        }
        Catch {
            #Write-Host "$($_ | Out-String)"
            $IsValid = $false
        }
        If ($IsValid -eq $true) {
            If ([string]::IsNullOrEmpty($VarInfo.Value) -eq $true) {
                $IsValid = $false
            }
        }
        $ObjProp = @{
            Name = $item
            Value = $VarInfo.Value
            IsValid = $IsValid
        }
        New-Object -TypeName PSCustomObject -Property $ObjProp
        If ($IsValid -eq $false -and $AbortIfInvalid -eq $true) {
            $Abort = $true
        }
    }
    Write-Output $ObjResults
    
    if ($Abort -eq $true) {
        $InvalidVars = ($ObjResults | Where-Object {$_.IsValid -eq $false}).Name -join ","
        Write-Error "Input variables [$($InvalidVars)] are invalid"
        Exit 1
    }
}
##########
# RMM INPUT
# InUrl
# InSavePath
# InForce (True | False)
# InEnableCompatibilityMode (True | False)
##########
Validate-Variable -Name InUrl,InSavePath,InForce,InEnableCompatibilityMode -AbortIfInvalid | FL
If ($InForce -eq 'True') {
    $InForce = $true
}
Else {
    $InForce = $false
}
If ($InEnableCompatibilityMode -eq 'True') {
    $InEnableCompatibilityMode = $true
}
Else {
    $InEnableCompatibilityMode = $false
}
Invoke-POpsDownload -Url $InUrl -FilePath $InSavePath -Force:$InForce -SkipSslCheck:$InEnableCompatibilityMode -Verbose
