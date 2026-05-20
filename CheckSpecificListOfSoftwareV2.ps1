$allApplications = Get-WmiObject -Class Win32_Product | select -expandproperty Name 
$applicationListNeeded = @("Camtasia", "Zoom", "Amazon") 
$Spacing = "-------------------------------------------------------------------" 
$Counter = 0
$NumberOfSoftware = 3
$CurrentApplication = @()

#For each application in the list of applications needed    
foreach($application in $applicationListNeeded) 
    { 
    foreach($software in $allApplications) 
    { 
    #Set software Name 
    $SoftwareName = $software
    
    #Set variable for Application name 
    $applicationName = $application 
    $SoftwareName | 
    ForEach-Object {
            if ($SoftwareName -match $applicationName){ 
            $CurrentApplication = $SoftwareName
            $Counter++
            Write-Output "Current Software Check: $CurrentApplication" 
            Write-Host "$Counter of $NumberOfSoftware Software installed.$SoftwareName matches NEEDED Software $applicationName"
            Write-Output $Spacing 
    }
}
}
}
