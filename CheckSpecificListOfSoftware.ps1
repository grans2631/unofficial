function Get-InstalledApps {
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [string]$NameRegex = ''
    )
    
    foreach ($comp in $ComputerName) {
        $keys = '','\Wow6432Node'
        foreach ($key in $keys) {
            try {
                $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $comp)
                $apps = $reg.OpenSubKey("SOFTWARE$key\Microsoft\Windows\CurrentVersion\Uninstall").GetSubKeyNames()
            } catch {
                continue
            }

            foreach ($app in $apps) {
                $program = $reg.OpenSubKey("SOFTWARE$key\Microsoft\Windows\CurrentVersion\Uninstall\$app")
                $name = $program.GetValue('DisplayName')
                if ($name -and $name -match $NameRegex) {
                    [pscustomobject]@{
                        ComputerName = $comp
                        DisplayName = $name
                        DisplayVersion = $program.GetValue('DisplayVersion')
                        Publisher = $program.GetValue('Publisher')
                        InstallDate = $program.GetValue('InstallDate')
                        UninstallString = $program.GetValue('UninstallString')
                        Bits = $(if ($key -eq '\Wow6432Node') {'64'} else {'32'})
                        Path = $program.name
                    }
                }
            }
        }
    }
}
$allsoftware = Get-InstalledApps | Select-Object DisplayName
$applicationListNeeded = @("Sentinel Agent", "Google Chrome", "Firefox", "Adobe Acrobat") 
$Spacing = "-------------------------------------------------------------------" 
$Counter = 0
$Counter2 = $applicationListNeeded.Count
$NumberOfSoftware = $applicationListNeeded.count
$CurrentApplication = @()
$CurrentGroupInstalled = @()
$SoftwareLeft = $NumberOfSoftware

#For each application in the list of application List Needed    
foreach($application in $applicationListNeeded) 
    { 
    #Decrement counter for number of applications in the applicationsListNeeded
    $Counter2--
        #For Each Software found in the Get-WmiObject command to return software on the machine
        foreach($software in $allSoftware) 
            { 
            #Set variable for current application name 
            $applicationName = $application 
            
            #Each time software in the All Applications list matches software in the Applications List Needed.  Set the Variables, increment(Counter) and decrement counters(SoftwareLeft)
            $software | 
            ForEach-Object {
                    if ($software -match $applicationName){ 
                    $CurrentApplication = $applicationName
                    $CurrentGroupInstalled += $CurrentApplication
                    $Counter++
                    $SoftwareLeft--
                                                              }
                            }
            }
        #If all the counter equals the number of software and the Second counter(Applications Needed List count) equals 0.  
        if($Counter -eq $NumberOfSoftware -and $Counter2 -eq 0)
        {
        Write-Output "All Software has BEEN INSTALLED"
        }
        #If Counter does not equal the number of software and the Second counter equals 0
        if($Counter -ne $NumberOfSoftware -and $Counter2 -eq 0)
        {
        $applicationListNeeded | ForEach-Object {
            if ($CurrentGroupInstalled -notcontains $_) {
                Write-Output "$_"
                                                        }
                                                }
        }   
    }
