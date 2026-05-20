$allApplications = Get-WmiObject -Class Win32_Product | select -expandproperty Name 
$applicationListNeeded = @("Camtasia", "Zoom", "Amazon", "Logi Bolt", "Sophos AutoUpdate XG", "Sophos Endpoint Self Help") 
$Spacing = "-------------------------------------------------------------------" 
$Counter = 0
$Counter2 = $applicationListNeeded.Count
$NumberOfSoftware = $applicationListNeeded.count
$CurrentApplication = @()
$CurrentGroupInstalled = @()
$SoftwareLeft = $NumberOfSoftware

#For each application in the list of applications needed    
foreach($application in $applicationListNeeded) 
    { 
    $Counter2--
        foreach($software in $allApplications) 
            { 
            #Set software Name 
            $SoftwareName = $software
    
            #Set variable for Application name 
            $applicationName = $application 
            $SoftwareName | 
            ForEach-Object {
                    if ($SoftwareName -match $applicationName){ 
                    $CurrentApplication = $applicationName
                    $CurrentGroupInstalled += $CurrentApplication
                    $Counter++
                    $SoftwareLeft--
                                                              }
                            }
            }
        if($Counter -eq $NumberOfSoftware -and $Counter2 -eq 0)
        {
        Write-Output "All Software has Been INSTALLED`nThe Below has been Installed`n$CurrentGroupInstalled"
        }
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
