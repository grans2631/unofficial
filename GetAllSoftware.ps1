##Command below will get all 32 Bit software and store it in the variable $32bit_software
$32bit_software = Get-ItemProperty HKLM:\Software\wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

##Command below will get all 64 Bit software and store it in the variable $64bit_software
$64bit_software = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

##Command below will list both the 32 and 64 bit software
$all_software = $32bit_softwares + $64bit_softwares

##Find if a certain software exists in the list
$all_softwares.DisplayName -like '*winrar*'
