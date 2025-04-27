$InputDir = $args[0]
$OutputDir = $args[1]
$MaxDepth = -1

if ($args.Count -ge 4 -and $args[2] -eq "--max_depth") {
    $MaxDepth = [int]$args[3]
}

if (-not (Test-Path -Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
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
