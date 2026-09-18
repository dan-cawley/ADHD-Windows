$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { throw 'The Windows .NET Framework C# compiler is required.' }
$output = Join-Path $PSScriptRoot 'dist\0.22.1'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$sources = @((Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'src') -Filter *.cs).FullName) + @((Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'tests') -Filter *.cs).FullName)
& $compiler /nologo /target:winexe /platform:anycpu /optimize+ "/win32icon:$PSScriptRoot\assets\adhd-warrior.ico" "/win32manifest:$PSScriptRoot\src\app.manifest" "/out:$output\ADHD Warrior.exe" /reference:System.dll /reference:System.Core.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll /reference:System.Web.Extensions.dll /reference:System.Security.dll $sources
if ($LASTEXITCODE -ne 0) { throw 'Compilation failed.' }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'src\App.config') -Destination (Join-Path $output 'ADHD Warrior.exe.config') -Force
$assets = Join-Path $PSScriptRoot 'assets'
if (Test-Path -LiteralPath $assets) { Copy-Item -LiteralPath $assets -Destination $output -Recurse -Force }
Write-Output "Built: $output\ADHD Warrior.exe"
