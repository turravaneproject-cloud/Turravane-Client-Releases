param(
    [Parameter(Mandatory=$true)][string]$ClientRoot,
    [ValidateSet('BeforePatch','AfterPatch','Full')][string]$Mode='AfterPatch'
)
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath $ClientRoot).Path.TrimEnd('\')
function Assert-ClientHash([string]$relative,[string]$expected) {
    $target=[IO.Path]::GetFullPath((Join-Path $root $relative))
    if (-not $target.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Path outside client root' }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $expected) { throw "Client mismatch: $relative" }
}
$manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'CLIENT_PATCH_MANIFEST.json') -Raw | ConvertFrom-Json
Assert-ClientHash 'Main.exe' $manifest.requiresMainSha256
if ($Mode -eq 'Full') {
    $files=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'CLIENT_FILE_MANIFEST.json') -Raw | ConvertFrom-Json
    foreach ($item in $files) { Assert-ClientHash $item.path $item.sha256 }
} else {
    $files=$manifest.files
    foreach ($item in $files) {
        $expected=if ($Mode -eq 'BeforePatch') {$item.beforeSha256} else {$item.sha256}
        Assert-ClientHash $item.path $expected
    }
}
[pscustomobject]@{Status='PASS';Mode=$Mode;FilesVerified=@($files).Count;ServerCompatibility='Requires matched server DLLCRC 964702844 and approved map matrix; verify server activation separately';Mutation='NONE'}
