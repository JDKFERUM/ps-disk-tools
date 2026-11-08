@{
    RootModule        = 'DiskTools.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'd4f5a3f2-6c1b-4f8e-9c2a-5b7d1e0a9f33'
    Author            = 'JDKFERUM'
    Description       = 'Small read-only helpers for disk usage on Windows.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Format-ByteSize', 'Get-FolderSize', 'Get-LargeFile', 'Remove-EmptyFolder')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
