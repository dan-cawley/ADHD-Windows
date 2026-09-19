param([string]$Thumbprint=$env:ADHD_WARRIOR_CERT_THUMBPRINT)
$ErrorActionPreference='Stop'
if ([string]::IsNullOrWhiteSpace($Thumbprint)) { throw 'Set ADHD_WARRIOR_CERT_THUMBPRINT to the code-signing certificate thumbprint.' }
$signtool=(Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin" -Filter signtool.exe -Recurse -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1).FullName
if (-not $signtool) { throw 'signtool.exe was not found. Install the Windows SDK signing tools.' }
$version='0.24.0'
$app=Join-Path $PSScriptRoot "dist\$version\ADHD Warrior.exe"
if(-not (Test-Path -LiteralPath $app)){throw "Build artifact missing: $app"}
& $signtool sign /sha1 $Thumbprint /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $app
if($LASTEXITCODE -ne 0){throw 'Application signing failed.'}
& (Join-Path $PSScriptRoot 'build-installer.ps1') -SkipBuild
$setup=Join-Path $PSScriptRoot "release\$version\ADHD Warrior Setup $version.exe"
& $signtool sign /sha1 $Thumbprint /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $setup
if($LASTEXITCODE -ne 0){throw 'Installer signing failed.'}
foreach($file in @($app,$setup)){& $signtool verify /pa /v $file;if($LASTEXITCODE -ne 0){throw "Signature verification failed: $file"}}
$release=Join-Path $PSScriptRoot "release\$version";$portable=Join-Path $release "ADHD Warrior Portable $version.zip";if(Test-Path -LiteralPath $portable){Remove-Item -LiteralPath $portable -Force};Compress-Archive -Path (Join-Path $PSScriptRoot "dist\$version\*") -DestinationPath $portable -CompressionLevel Optimal
$checksums=Get-ChildItem -LiteralPath $release -File|Where-Object{$_.Name -ne 'SHA256SUMS.txt'}|Sort-Object Name|ForEach-Object{"$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant())  $($_.Name)"};Set-Content -LiteralPath (Join-Path $release 'SHA256SUMS.txt') -Value $checksums -Encoding ascii
Write-Output 'Signed and verified the application and installer, then rebuilt the portable package and checksums.'
