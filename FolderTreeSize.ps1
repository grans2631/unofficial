[CmdletBinding()]
param(
    [string]$RootPath = "C:\",

    [int]$Depth = 2
)

Function Get-FolderSize {
    param (
        [String]$Path,
        [Int]$Depth = 1
    )

    $output = @()

    $folders = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue

    foreach ($folder in $folders) {

        $sizeBytes = (
            Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum
        ).Sum

        if (-not $sizeBytes) { $sizeBytes = 0 }
        $sizeGB = [Math]::Round($sizeBytes / 1GB, 2)

        $output += [PSCustomObject]@{
            Folder = $folder.FullName
            SizeGB = $sizeGB
        }

        if ($Depth -gt 1) {
            $output += Get-FolderSize -Path $folder.FullName -Depth ($Depth - 1)
        }
    }

    return $output
}

Write-Host "Folder Size Report for $RootPath (Largest → Smallest)" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------"

$results = Get-FolderSize -Path $RootPath -Depth $Depth

$sorted = $results | Sort-Object -Property SizeGB -Descending

foreach ($item in $sorted) {
    Write-Output ("{0} - {1} GB" -f $item.Folder, $item.SizeGB)
}
