$ErrorActionPreference = 'Stop'
$version = '0.21.2'
& (Join-Path $PSScriptRoot 'build-installer.ps1')
$release = Join-Path $PSScriptRoot "release\$version"
$portable = Join-Path $release "ADHD Warrior Portable $version.zip"
if (Test-Path -LiteralPath $portable) { Remove-Item -LiteralPath $portable -Force }
Compress-Archive -Path (Join-Path $PSScriptRoot "dist\$version\*") -DestinationPath $portable -CompressionLevel Optimal
$artifacts = Get-ChildItem -LiteralPath $release -File | Where-Object { $_.Name -ne 'SHA256SUMS.txt' } | Sort-Object Name
$checksums = foreach ($artifact in $artifacts) {
  $hash = (Get-FileHash -LiteralPath $artifact.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
  "$hash  $($artifact.Name)"
}
Set-Content -LiteralPath (Join-Path $release 'SHA256SUMS.txt') -Value $checksums -Encoding ascii
Write-Output "Built release artifacts: $release"
$checksums
