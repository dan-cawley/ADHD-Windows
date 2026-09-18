$ErrorActionPreference = 'Stop'
$version = '0.22.3'
& (Join-Path $PSScriptRoot 'build-installer.ps1')
$app = Join-Path $PSScriptRoot "dist\$version\ADHD Warrior.exe"
$test = Start-Process -FilePath $app -ArgumentList '--self-test' -Wait -PassThru
if ($test.ExitCode -ne 0) { throw 'Automated assertions failed.' }
$render = Start-Process -FilePath $app -ArgumentList '--render-test' -Wait -PassThru
if ($render.ExitCode -ne 0) { throw 'Buffered redraw and responsive layout smoke test failed.' }
Write-Output 'Passed automated assertions and buffered redraw/layout smoke test.'
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
