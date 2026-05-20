$32bit_software = Get-ItemProperty HKLM:\Software\wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName
$64bit_software = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName 
$allsoftware = $32bit_softwares + $64bit_software
$applicationListNeeded = @("Camtasia", "Zoom", "Amazon", "Logi Bolt", "Dell Update for Windows Universal", "Sophos AutoUpdate XG", "Sophos Endpoint Self Help") 
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
        Write-Output "SOFTWARE IS MISSING`n$Spacing"
        $applicationListNeeded | ForEach-Object {
            if ($CurrentGroupInstalled -notcontains $_) {
                Write-Output "$_"
                                                        }
                                                }
        }   
    }
