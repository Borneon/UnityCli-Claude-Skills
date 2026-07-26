# Unity-MCP skill kurucu (Windows / PowerShell)
# Çalıştırmak icin: sag tikla > "PowerShell ile calistir"
#   ya da PowerShell'de:  ./install.ps1
# Engellenirse once:  Set-ExecutionPolicy -Scope Process Bypass

$ErrorActionPreference = "Stop"
$src  = Join-Path $PSScriptRoot "unity-mcp"
$dest = Join-Path $HOME ".claude\skills"

if (-not (Test-Path $src)) {
  Write-Error "Yaninda 'unity-mcp' klasoru yok. Zip'i tamamen actin mi?"
  exit 1
}

New-Item -ItemType Directory -Force -Path $dest | Out-Null

$target = Join-Path $dest "unity-mcp"
if (Test-Path $target) {
  Write-Host "Not: $target zaten var, uzerine yaziliyor."
  Remove-Item -Recurse -Force $target
}

Copy-Item -Recurse -Force $src $dest

Write-Host "OK: unity-mcp skill kuruldu -> $target"
Write-Host "Claude Code'u yeniden baslat, sonra 'unity-mcp' skill'i kullanilabilir olur."
