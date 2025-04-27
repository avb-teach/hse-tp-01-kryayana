param (
    [string]$InputDir,
    [string]$OutputDir,
    [string]$MaxDepth
)

if (-not $InputDir -or -not $OutputDir) {
    Write-Output "Usage: .\collect_files.ps1 <InputDir> <OutputDir> [--max_depth N]"
    exit
}

if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

function Get-Files {
    param (
        [string]$Path,
        [int]$Depth
    )

    $results = @()
    function Recurse {
        param (
            [string]$CurrentPath,
            [int]$Level
        )

        if ($Depth -ne -1 -and $Level -gt $Depth) {
            return
        }

        Get-ChildItem -Path $CurrentPath -File | ForEach-Object {
            $results += $_
        }

        Get-ChildItem -Path $CurrentPath -Directory | ForEach-Object {
            Recurse -CurrentPath $_.FullName -Level ($Level + 1)
        }
    }

    Recurse -CurrentPath $Path -Level 1

    return $results
}

function Copy-AllFiles {
    param (
        [array]$Files,
        [string]$Destination
    )

    foreach ($file in $Files) {
        $filename = $file.Name
        $destPath = Join-Path -Path $Destination -ChildPath $filename

        if (Test-Path $destPath) {
            $nameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($filename)
            $ext = [System.IO.Path]::GetExtension($filename)
            $counter = 1
            do {
                $newFilename = "$nameWithoutExt$counter$ext"
                $destPath = Join-Path -Path $Destination -ChildPath $newFilename
                $counter++
            } while (Test-Path $destPath)
        }

        Copy-Item -Path $file.FullName -Destination $destPath
    }
}

$depthValue = -1

if ($MaxDepth -and $MaxDepth.StartsWith("--max_depth")) {
    $parts = $MaxDepth.Split(" ")
    if ($parts.Length -eq 2) {
        $depthValue = [int]$parts[1]
    }
}

$files = Get-Files -Path $InputDir -Depth $depthValue
Copy-AllFiles -Files $files -Destination $OutputDir
