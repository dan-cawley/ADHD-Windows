$ErrorActionPreference = 'Stop'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { throw 'The Windows .NET Framework C# compiler is required.' }
$output = Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Path $output -Force | Out-Null
$sources = @((Join-Path $PSScriptRoot 'src\Core.cs'), (Join-Path $PSScriptRoot 'src\App.cs'), (Join-Path $PSScriptRoot 'tests\Tests.cs'))
& $compiler /nologo /target:winexe /platform:anycpu /optimize+ "/out:$output\ADHD Warrior.exe" /reference:System.dll /reference:System.Core.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll /reference:System.Web.Extensions.dll $sources
if ($LASTEXITCODE -ne 0) { throw 'Compilation failed.' }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'src\App.config') -Destination (Join-Path $output 'ADHD Warrior.exe.config') -Force
$assets = Join-Path $PSScriptRoot 'assets'
if (Test-Path -LiteralPath $assets) { Copy-Item -LiteralPath $assets -Destination $output -Recurse -Force }
Write-Output "Built: $output\ADHD Warrior.exe"
