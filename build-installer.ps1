$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'build.ps1')
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$version = '0.20.1'
$appOutput = Join-Path $PSScriptRoot "dist\$version"
$work = Join-Path $env:TEMP "adhd-warrior-installer-$([Guid]::NewGuid().ToString('N'))"
$release = Join-Path $PSScriptRoot "release\$version"
try {
 New-Item -ItemType Directory -Path $work,$release -Force | Out-Null
 Copy-Item -LiteralPath (Join-Path $appOutput 'ADHD Warrior.exe'),(Join-Path $appOutput 'ADHD Warrior.exe.config'),(Join-Path $appOutput 'assets') -Destination $work -Recurse -Force
 $payload = Join-Path $env:TEMP "adhd-warrior-payload-$([Guid]::NewGuid().ToString('N')).zip"
 Compress-Archive -Path (Join-Path $work '*') -DestinationPath $payload -CompressionLevel Optimal
 $setup = Join-Path $release "ADHD Warrior Setup $version.exe"
 & $compiler /nologo /target:winexe /platform:anycpu /optimize+ "/win32icon:$PSScriptRoot\assets\adhd-warrior.ico" "/out:$setup" "/resource:$payload,payload.zip" /reference:System.dll /reference:System.Core.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll /reference:System.IO.Compression.dll /reference:System.IO.Compression.FileSystem.dll (Join-Path $PSScriptRoot 'installer\Installer.cs')
 if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed.' }
 Write-Output "Built installer: $setup"
} finally {
 if (Test-Path $work) { Remove-Item $work -Recurse -Force }
 if ($payload -and (Test-Path $payload)) { Remove-Item $payload -Force }
}
