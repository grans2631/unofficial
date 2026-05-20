<# 
    Comprehensive OneStart Removal Script

    This script performs the following cleanup tasks:
      1. Terminates any OneStart processes.
      2. Removes OneStart folders from all user profiles.
      3. Removes desktop, pinned (taskbar), and Start Menu shortcuts.
          3.1. Explicitly checks each user's Desktop folder (and Public Desktop) for OneStart shortcuts.
      4. Removes OneStart startup items from Registry Run keys and Startup folders.
      5. Removes scheduled tasks related to OneStart.
      6. Removes OneStart registry keys from HKCU, HKLM uninstall keys, MuiCache, and additional keys.
      7. Removes Installer and BAM keys that reference OneStart.
      
    IMPORTANT: Run this script as an Administrator. Test on a non‐critical system first.
#>

# ------------------------------
# Function: Remove-FolderWithRetry
# ------------------------------
function Remove-FolderWithRetry {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FolderPath,
        [int]$RetryCount = 3,
        [int]$DelaySeconds = 2
    )
    for ($i = 1; $i -le $RetryCount; $i++) {
        try {
            if (Test-Path $FolderPath) {
                Remove-Item -Path $FolderPath -Recurse -Force -ErrorAction Stop
            }
            if (-not (Test-Path $FolderPath)) {
                Write-Output "Deleted folder: $FolderPath"
                return $true
            }
        }
        catch {
            Write-Output "Attempt $i to delete '$FolderPath' failed: $($_.Exception.Message)"
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    # Fallback using CMD rd /s /q:
    if (Test-Path $FolderPath) {
        Write-Output "Using CMD fallback to remove $FolderPath"
        cmd.exe /c "rd /s /q `"$FolderPath`""
        Start-Sleep -Seconds 2
        if (-not (Test-Path $FolderPath)) {
            Write-Output "Deleted folder via CMD: $FolderPath"
            return $true
        } else {
            Write-Output "Failed to delete folder even with CMD fallback: $FolderPath"
            return $false
        }
    }
}

# ------------------------------
# 1. Terminate Running OneStart Processes
# ------------------------------
$validPathPattern = "C:\Users\*\AppData\Local\OneStart.ai\*"
$processNames = @("OneStart", "onestart")  # account for case variations
foreach ($procName in $processNames) {
    $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($procs) {
        foreach ($proc in $procs) {
            $procPath = $proc.Path
            if ($procPath -and ($procPath -like $validPathPattern)) {
                try {
                    Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                    Write-Output "Killed process '$($proc.Name)' (ID: $($proc.Id)) from '$procPath'."
                }
                catch {
                    Write-Output "Failed to kill process '$($proc.Name)' (ID: $($proc.Id)): $($_.Exception.Message)"
                }
            }
            else {
                Write-Output "Process '$($proc.Name)' with path '$procPath' does not match pattern; not stopped."
            }
        }
    }
    else {
        Write-Output "No processes found matching '$procName'."
    }
}

Start-Sleep -Seconds 5

# ------------------------------
# 2. Remove OneStart-Related Folders for Each User
# ------------------------------
$folderTargets = @(
    "\AppData\Local\OneStart.ai\",
    "\AppData\Roaming\OneStart\"
)
foreach ($user in Get-ChildItem -Path "C:\Users" -Directory) {
    foreach ($relPath in $folderTargets) {
        $fullPath = Join-Path -Path $user.FullName -ChildPath $relPath
        Write-Output "Checking folder: $fullPath"
        if (Test-Path $fullPath) {
            Remove-FolderWithRetry -FolderPath $fullPath -RetryCount 3 -DelaySeconds 3
        }
        else {
            Write-Output "Folder not found: $fullPath"
        }
    }
}

# ------------------------------
# 3. Remove Desktop & Pinned Shortcuts
# ------------------------------
$desktopLocations = @(
    "C:\Users\Public\Desktop",
    "C:\Users\*\Desktop"
)
foreach ($loc in $desktopLocations) {
    Write-Output "Searching for desktop shortcuts in $loc"
    Get-ChildItem -Path $loc -Filter "*OneStart*.lnk" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item $_.FullName -Force -ErrorAction Stop
            Write-Output "Removed desktop shortcut: $($_.FullName)"
        }
        catch {
            Write-Output "Failed to remove desktop shortcut: $($_.FullName) - $($_.Exception.Message)"
        }
    }
}

# Remove pinned taskbar shortcuts (if any)
$pinnedLocations = @(
    "C:\Users\*\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
)
foreach ($loc in $pinnedLocations) {
    Write-Output "Searching for pinned taskbar shortcuts in $loc"
    Get-ChildItem -Path $loc -Filter "*OneStart*.lnk" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item $_.FullName -Force -ErrorAction Stop
            Write-Output "Removed pinned shortcut: $($_.FullName)"
        }
        catch {
            Write-Output "Failed to remove pinned shortcut: $($_.FullName) - $($_.Exception.Message)"
        }
    }
}

# ------------------------------
# 3.1 Remove OneStart Shortcuts from All User Profile Desktops (Explicit Check)
# ------------------------------
$allUsers = Get-ChildItem -Path "C:\Users" -Directory
foreach ($user in $allUsers) {
    $desktopPath = Join-Path $user.FullName "Desktop"
    if (Test-Path $desktopPath) {
        Write-Output "Checking desktop folder: $desktopPath"
        Get-ChildItem -Path $desktopPath -Filter "*OneStart*.lnk" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-Item $_.FullName -Force -ErrorAction Stop
                Write-Output "Removed OneStart shortcut from $desktopPath : $($_.FullName)"
            }
            catch {
                Write-Output "Failed to remove OneStart shortcut from $desktopPath : $($_.Exception.Message)"
            }
        }
    }
}

# ------------------------------
# 4. Remove Start Menu Shortcuts
# ------------------------------
$startMenuLocations = @(
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs",
    "C:\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs"
)
foreach ($loc in $startMenuLocations) {
    Write-Output "Searching for Start Menu shortcuts in $loc"
    Get-ChildItem -Path $loc -Filter "*OneStart*.lnk" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item $_.FullName -Force -ErrorAction Stop
            Write-Output "Removed Start Menu shortcut: $($_.FullName)"
        }
        catch {
            Write-Output "Failed to remove Start Menu shortcut: $($_.FullName) - $($_.Exception.Message)"
        }
    }
}

# ------------------------------
# 5. Remove Startup Items
# ------------------------------
# (a) Remove OneStart entries from Registry Run keys in HKCU and HKLM.
$runRegistryPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($regPath in $runRegistryPaths) {
    if (Test-Path $regPath) {
        $runKey = Get-Item $regPath
        $valuesToRemove = $runKey.GetValueNames() | Where-Object { $_ -like "*OneStart*" }
        foreach ($val in $valuesToRemove) {
            try {
                Remove-ItemProperty -Path $regPath -Name $val -ErrorAction Stop
                Write-Output "Removed startup registry entry: $regPath\$val"
            }
            catch {
                Write-Output "Failed to remove startup registry entry $regPath\$val : $($_.Exception.Message)"
            }
        }
    }
}

# (b) Remove OneStart shortcuts from the Startup folders.
$startupFolders = @(
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup",
    "C:\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
)
foreach ($folder in $startupFolders) {
    Write-Output "Searching for Startup folder items in $folder"
    Get-ChildItem -Path $folder -Filter "*OneStart*.lnk" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            Remove-Item $_.FullName -Force -ErrorAction Stop
            Write-Output "Removed Startup folder shortcut: $($_.FullName)"
        }
        catch {
            Write-Output "Failed to remove Startup folder shortcut: $($_.FullName) - $($_.Exception.Message)"
        }
    }
}

# ------------------------------
# 6. Remove Scheduled Tasks Related to OneStart
# ------------------------------
$scheduledTaskNames = @("OneStart Chromium", "OneStart Updater")
foreach ($taskName in $scheduledTaskNames) {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        try {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
            Write-Output "Removed scheduled task: $taskName"
        }
        catch {
            Write-Output "Failed to remove scheduled task '$taskName': $($_.Exception.Message)"
        }
    }
    else {
        Write-Output "No scheduled task found with name '$taskName'."
    }
}

# ------------------------------
# 7. Remove Registry Keys and Related Entries
# ------------------------------
# (a) Remove HKCU keys
$hkcuTargets = @(
    "Software\OneStart.ai",
    "Software\Clients\StartMenuInternet\OneStart.*",  # using wildcard pattern
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\OneStart*"
)
foreach ($hive in Get-ChildItem Registry::HKEY_CURRENT_USER) {
    foreach ($target in $hkcuTargets) {
        $fullPath = $hive.PSPath + "\" + $target
        if (Test-Path $fullPath) {
            try {
                Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                Write-Output "Removed HKCU registry key: $fullPath"
            }
            catch {
                Write-Output "Failed to remove HKCU registry key $fullPath : $($_.Exception.Message)"
            }
        }
    }
}

# (b) Remove uninstall keys from HKLM (64-bit and WOW6432Node)
$uninstallRegPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)
foreach ($basePath in $uninstallRegPaths) {
    $keys = Get-ChildItem -Path $basePath -ErrorAction SilentlyContinue | Where-Object {
        try { $_.GetValue("DisplayName") -like "*OneStart*" } catch { $false }
    }
    foreach ($key in $keys) {
        try {
            Remove-Item -Path $key.PSPath -Recurse -Force -ErrorAction Stop
            Write-Output "Removed uninstall registry key: $($key.PSPath)"
        }
        catch {
            Write-Output "Failed to remove registry key: $($key.PSPath) - $($_.Exception.Message)"
        }
    }
}

# (c) Remove MuiCache entries that reference OneStart.ai from HKLM\SOFTWARE\Microsoft\Windows\Shell\MuiCache
$muiCachePath = "HKLM:\SOFTWARE\Microsoft\Windows\Shell\MuiCache"
if (Test-Path $muiCachePath) {
    $muiEntries = Get-ItemProperty -Path $muiCachePath -ErrorAction SilentlyContinue
    if ($muiEntries) {
        foreach ($property in $muiEntries.PSObject.Properties) {
            if ($property.Value -like "*OneStart.ai*") {
                try {
                    Remove-ItemProperty -Path $muiCachePath -Name $property.Name -ErrorAction SilentlyContinue
                    Write-Output "Removed MuiCache entry: $($property.Name)"
                }
                catch {
                    Write-Output "Failed to remove MuiCache entry $($property.Name): $($_.Exception.Message)"
                }
            }
        }
    }
}

# (d) Remove additional HKLM keys if present (e.g., Installer\Folders & BAM settings)
$installerFolderKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\Folders"
if (Test-Path $installerFolderKey) {
    try {
        $installerKeys = Get-ChildItem -Path $installerFolderKey -ErrorAction SilentlyContinue | Where-Object {
            $_.PSChildName -like "*OneStart.ai*"
        }
        foreach ($ikey in $installerKeys) {
            Remove-Item -Path $ikey.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            Write-Output "Removed Installer folder registry key: $($ikey.PSPath)"
        }
    }
    catch {
        Write-Output "Error removing Installer folder keys: $($_.Exception.Message)"
    }
}

$bamKey = "HKLM:\System\CurrentControlSet\Services\bam\State\UserSettings"
if (Test-Path $bamKey) {
    try {
        $bamUserKeys = Get-ChildItem -Path $bamKey -ErrorAction SilentlyContinue
        foreach ($userKey in $bamUserKeys) {
            $subKeys = Get-ChildItem -Path $userKey.PSPath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -like "*OneStart.ai*" }
            foreach ($subKey in $subKeys) {
                Remove-Item -Path $subKey.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                Write-Output "Removed BAM registry key: $($subKey.PSPath)"
            }
        }
    }
    catch {
        Write-Output "Error removing BAM keys: $($_.Exception.Message)"
    }
}

# ------------------------------
# 8. Final Message
# ------------------------------
Write-Output "OneStart removal process complete. Please restart your computer to finalize removal."
