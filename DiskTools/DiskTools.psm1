function Format-ByteSize {
    <#
    .SYNOPSIS
        Turn a byte count into a short human readable string.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [long]$Bytes
    )

    $units = 'B', 'KiB', 'MiB', 'GiB', 'TiB'
    $value = [double]$Bytes
    $index = 0
    while ($value -ge 1024 -and $index -lt $units.Count - 1) {
        $value = $value / 1024
        $index++
    }

    if ($index -eq 0) {
        return [string]::Format([cultureinfo]::InvariantCulture, '{0} {1}', [long]$value, $units[$index])
    }
    return [string]::Format([cultureinfo]::InvariantCulture, '{0:N1} {1}', $value, $units[$index])
}

function Get-FolderSize {
    <#
    .SYNOPSIS
        Total size of the files inside a folder, recursively.
    .EXAMPLE
        Get-FolderSize -Path C:\Windows\Logs
        Get-FolderSize -Path . -AsBytes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        [switch]$AsBytes
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Folder not found: $Path"
    }

    $sum = Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue |
        Measure-Object -Property Length -Sum
    $bytes = if ($null -eq $sum.Sum) { 0 } else { [long]$sum.Sum }

    if ($AsBytes) {
        return $bytes
    }
    return Format-ByteSize $bytes
}

function Get-LargeFile {
    <#
    .SYNOPSIS
        Files above a size threshold, biggest first.
    .EXAMPLE
        Get-LargeFile -Path C:\Users -MinMB 500
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        [ValidateRange(1, [int]::MaxValue)]
        [int]$MinMB = 100
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Folder not found: $Path"
    }

    $limit = [long]$MinMB * 1MB
    Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Length -ge $limit } |
        Sort-Object Length -Descending |
        Select-Object FullName, @{ Name = 'SizeMB'; Expression = { [math]::Round($_.Length / 1MB, 1) } }
}

function Remove-EmptyFolder {
    <#
    .SYNOPSIS
        Remove empty folders below a path. Dry run unless -Confirm:$false is used.
    .EXAMPLE
        Remove-EmptyFolder -Path .\build -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw "Folder not found: $Path"
    }

    $empties = Get-ChildItem -LiteralPath $Path -Recurse -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            -not (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue)
        } |
        Sort-Object { $_.FullName.Length } -Descending

    foreach ($folder in $empties) {
        if ($PSCmdlet.ShouldProcess($folder.FullName, 'Remove empty folder')) {
            Remove-Item -LiteralPath $folder.FullName -Force
        }
    }
}

Export-ModuleMember -Function Format-ByteSize, Get-FolderSize, Get-LargeFile, Remove-EmptyFolder
