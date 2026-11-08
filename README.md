# ps-disk-tools

A small PowerShell module with the disk helpers I kept rewriting in one-off
scripts. Read-only by default, no dependencies, no telemetry.

| Function | What it does |
| --- | --- |
| `Get-FolderSize` | total size of the files inside a folder, recursively |
| `Get-LargeFile` | files above a size threshold, biggest first |
| `Remove-EmptyFolder` | removes empty folders; supports `-WhatIf` |
| `Format-ByteSize` | `1572864` -> `1.5 MiB` |

## Install

```powershell
Import-Module ./DiskTools/DiskTools.psd1
```

There is no gallery package yet; clone the repository and import the manifest.

## Usage

```powershell
# How big is this tree?
Get-FolderSize -Path C:\Windows\Logs

# Same, in bytes for a script
(Get-FolderSize -Path C:\Windows\Logs -AsBytes) -gt 1GB

# What eats the space?
Get-LargeFile -Path C:\Users -MinMB 500

# Clean up empty folders, first as a dry run
Remove-EmptyFolder -Path .\build -WhatIf
Remove-EmptyFolder -Path .\build -Confirm:$false
```

Example output:

```text
PS> Get-LargeFile -Path . -MinMB 100

FullName                          SizeMB
--------                          ------
C:\data\backup-2026-10.zip           812
C:\data\video.mp4                    340
```

## Notes

- Sizes are binary units (`KiB`, `MiB`, `GiB`), formatted with the invariant
  culture, so the output does not change with the system locale.
- `Remove-EmptyFolder` only deletes folders that are already empty, and only
  when you pass `-Confirm:$false`; the default is a dry run.
- Access denied on individual files is ignored, so one locked folder does not
  abort the whole scan.

## Tests

```powershell
pwsh -File tests/DiskTools.Tests.ps1
```

The tests build a temporary tree, check the arithmetic and the dry-run
behaviour, and exit non-zero on the first failing check. CI runs the same
script on `windows-latest`.

## Requirements

- PowerShell 7.0 or newer
- Windows (the module uses no Unix specific code, but it is only tested there)

## License

MIT
