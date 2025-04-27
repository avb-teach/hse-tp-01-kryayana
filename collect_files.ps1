param (
    [string]$InputDir,
    [string]$OutputDir,
    [string]$MaxDepthParam
)

if (-not $InputDir -or -not $OutputDir) {
    Write-Output "Usage: .\collect_files.ps1 <InputDir> <OutputDir> [--max_depth N]"
    exit
}

if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$MaxDepth = -1

if ($MaxDepthParam -and $MaxDepthParam.StartsWith("--max_depth")) {
    $split = $MaxDepthParam.Split(" ")
    if ($split.Length -eq 2) {
        $MaxDepth = [int]$split[1]
    }
}

function Copy-FilesWithDepth {
    param (
        [string]$Source,
        [string]$Destination,
        [int]$CurrentDepth,
        [int]$MaxAllowedDepth
    )

    if ($MaxAllowedDepth -ne -1 -and $CurrentDepth -gt $MaxAllowedDepth) {
        return
    }

    Get-ChildItem -Path $Source -File | ForEach-Object {
        $filename = $_.Name
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

        Copy-Item -Path $_.FullName -Destination $destPath
    }

    Get-ChildItem -Path $Source -Directory | ForEach-Object {
        Copy-FilesWithDepth -Source $_.FullName -Destination $Destination -CurrentDepth ($CurrentDepth + 1) -MaxAllowedDepth $MaxAllowedDepth
    }
}

Copy-FilesWithDepth -Source $InputDir -Destination $OutputDir -CurrentDepth 1 -MaxAllowedDepth $MaxDepth
