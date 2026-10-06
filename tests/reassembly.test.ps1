$ErrorActionPreference='Stop'
$testRoot=Join-Path $PSScriptRoot '../.tools/reassembly-test'
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$testDirectory=Join-Path $testRoot ([Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testDirectory | Out-Null
$name='rift-os-0.2.0-alpha.1-amd64.iso'
$original=[Text.Encoding]::UTF8.GetBytes('RIFT ISO reassembly test: complete and verified.')
$sums=[Collections.Generic.List[string]]::new()
for($part=1;$part -le 3;$part++){
  $start=($part-1)*16
  $end=[Math]::Min($start+15,$original.Length-1)
  $partName='{0}.part-{1:D3}' -f $name,$part
  $partPath=Join-Path $testDirectory $partName
  [IO.File]::WriteAllBytes($partPath,[byte[]]$original[$start..$end])
  $sums.Add("$((Get-FileHash -LiteralPath $partPath).Hash.ToLowerInvariant())  $partName")
}
$originalPath=Join-Path $testDirectory 'expected.bin'
[IO.File]::WriteAllBytes($originalPath,$original)
$sums.Add("$((Get-FileHash -LiteralPath $originalPath).Hash.ToLowerInvariant())  $name")
[IO.File]::WriteAllLines((Join-Path $testDirectory 'SHA256SUMS'),$sums)
& "$PSScriptRoot/../release/Reassemble.ps1" -Directory $testDirectory
$resultPath=Join-Path $testDirectory $name
if((Get-FileHash -LiteralPath $resultPath).Hash -ne (Get-FileHash -LiteralPath $originalPath).Hash){throw 'Incorrect assembled output'}
$rejected=$false
try{& "$PSScriptRoot/../release/Reassemble.ps1" -Directory $testDirectory}catch{$rejected=$true}
if(-not $rejected){throw 'Existing image should not be overwritten'}
Write-Host 'PASS: part validation, reassembly, final SHA-256 and existing-output protection.'
