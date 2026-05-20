#This will display a list of all software installed on a machine 

$32bit_software = Get-ItemProperty HKLM:\Software\wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate  

$64bit_software = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate  

$all_software = $32bit_softwares + $64bit_softwares  

$searchterm = $all_software 

$uninstallers = get-childitem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall 

$founditems = $uninstallers | ? {(Get-ItemProperty -path ("HKLM:\"+$_.name) -name Displayname -erroraction silentlycontinue) -match $searchterm} 

write-host "Searched registry for uninstall information on $searchterm" 

Write-host "------------------------------------------------------------------------------------------------------------------------" 

if ($founditems -eq $null) {"None found"} else { 

write-host "Found "($founditems | measure-object).count" item(s):" 

Write-host "------------------------------------------------------------------------------------------------------------------------" 

Write-host "`n" 

$founditems | % { 

Write-host "Displayname: "$_.getvalue("Displayname") 

Write-host "Displayversion: "$_.getvalue("Displayversion") 

Write-host "InstallDate: "$_.getvalue("InstallDate") 

Write-host "InstallSource: "$_.getvalue("InstallSource") 

Write-host "UninstallString: "$_.getvalue("UninstallString") 

Write-host "`n" 

Write-host "------------------------------------------------------------------------------------------------------------------------" 

} 

} 
