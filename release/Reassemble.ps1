param([string]$Directory = $PSScriptRoot)
$ErrorActionPreference = 'Stop'
$releaseDirectory = (Resolve-Path -LiteralPath $Directory).Path
$firstParts = @(Get-ChildItem -LiteralPath $releaseDirectory -File | Where-Object { $_.Name -match '^rift-os-[0-9A-Za-z.-]+-amd64\.iso\.part-001$' })
if ($firstParts.Count -ne 1) { throw 'Place the parts for exactly one RIFT OS version in this folder.' }
$imageName = $firstParts[0].Name -replace '\.part-001$', ''
$partFiles = @(Get-ChildItem -LiteralPath $releaseDirectory -File | Where-Object { $_.Name.StartsWith("$imageName.part-") -and $_.Name -match '\.part-\d{3}$' } | Sort-Object Name)
$checksumPath = Join-Path $releaseDirectory 'SHA256SUMS'
$checks = @{}
foreach ($line in [IO.File]::ReadAllLines($checksumPath)) {
    if ($line -match '^([0-9a-fA-F]{64})\s+\*?([^/\\]+)$') { $checks[$Matches[2]] = $Matches[1].ToLowerInvariant() }
}
$expectedNames = @($checks.Keys | Where-Object { $_.StartsWith("$imageName.part-") } | Sort-Object)
if ($expectedNames.Count -ne $partFiles.Count -or $partFiles.Count -lt 1 -or -not $checks.ContainsKey($imageName)) { throw 'Missing parts or invalid checksum manifest.' }
for ($index=0; $index -lt $partFiles.Count; $index++) {
    if ($partFiles[$index].Name -ne $expectedNames[$index] -or $partFiles[$index].Name -ne ('{0}.part-{1:D3}' -f $imageName,($index+1))) { throw 'Parts must form a complete sequence.' }
    if ((Get-FileHash -LiteralPath $partFiles[$index].FullName -Algorithm SHA256).Hash.ToLowerInvariant() -ne $checks[$partFiles[$index].Name]) { throw "Damaged part: $($partFiles[$index].Name)" }
}
$imagePath = Join-Path $releaseDirectory $imageName
if (Test-Path -LiteralPath $imagePath) { throw 'Output ISO already exists; move it before reassembling.' }
$temporaryPath = "$imagePath.partial"
$outputStream = [IO.File]::Open($temporaryPath,[IO.FileMode]::CreateNew)
try {
    foreach ($part in $partFiles) {
        Write-Host "Joining $($part.Name)"
        $inputStream = [IO.File]::OpenRead($part.FullName)
        try { $inputStream.CopyTo($outputStream) } finally { $inputStream.Dispose() }
    }
} finally { $outputStream.Dispose() }
if ((Get-FileHash -LiteralPath $temporaryPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $checks[$imageName]) { throw 'ISO checksum mismatch. The partial file was preserved for inspection.' }
Move-Item -LiteralPath $temporaryPath -Destination $imagePath
Write-Host "Verified ISO ready: $imagePath"
