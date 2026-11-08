$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../DiskTools/DiskTools.psd1') -Force

$script:Failed = 0

function Assert-Equal($Expected, $Actual, [string]$Name) {
    if ($Expected -eq $Actual) {
        Write-Host "ok   $Name"
        return
    }
    Write-Host "FAIL $Name (expected [$Expected], got [$Actual])"
    $script:Failed++
}

function Assert-True([bool]$Condition, [string]$Name) {
    if ($Condition) {
        Write-Host "ok   $Name"
        return
    }
    Write-Host "FAIL $Name"
    $script:Failed++
}

Assert-Equal '0 B' (Format-ByteSize 0) 'zero bytes'
Assert-Equal '1023 B' (Format-ByteSize 1023) 'bytes stay bytes'
Assert-Equal '1.0 KiB' (Format-ByteSize 1024) 'one kibibyte'
Assert-Equal '1.5 MiB' (Format-ByteSize (1024 * 1024 * 1.5)) 'one and a half MiB'

$workRoot = Join-Path $PSScriptRoot '.test-work'
New-Item -ItemType Directory -Path $workRoot -Force | Out-Null
$work = Join-Path $workRoot ([guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null

try {
    New-Item -ItemType Directory -Path (Join-Path $work 'nested') | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $work 'empty-leaf') | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $work 'small.txt'), [byte[]]::new(512))
    [IO.File]::WriteAllBytes((Join-Path $work 'nested/big.bin'), [byte[]]::new(2MB))
    [IO.File]::WriteAllBytes((Join-Path $work 'nested/medium.bin'), [byte[]]::new(1MB))

    Assert-Equal 3146240 (Get-FolderSize -Path $work -AsBytes) 'folder size in bytes'
    Assert-True ((Get-FolderSize -Path $work) -match 'MiB$') 'folder size is human readable'

    $large = @(Get-LargeFile -Path $work -MinMB 1)
    Assert-Equal 2 $large.Count 'large file filter'
    Assert-Equal 'big.bin' ([IO.Path]::GetFileName($large[0].FullName)) 'biggest file comes first'

    Remove-EmptyFolder -Path $work -WhatIf | Out-Null
    Assert-True (Test-Path (Join-Path $work 'empty-leaf')) 'WhatIf keeps folders'

    Remove-EmptyFolder -Path $work -Confirm:$false | Out-Null
    Assert-True (-not (Test-Path (Join-Path $work 'empty-leaf'))) 'empty folder removed'
    Assert-True (Test-Path (Join-Path $work 'nested')) 'non empty folder kept'

    $threw = $false
    try { Get-FolderSize -Path (Join-Path $work 'missing') | Out-Null } catch { $threw = $true }
    Assert-True $threw 'missing folder throws'
}
finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

if ($script:Failed -gt 0) {
    Write-Host "$($script:Failed) check(s) failed"
    exit 1
}
Write-Host 'all checks passed'
exit 0
