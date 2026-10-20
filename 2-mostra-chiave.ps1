# Mostra i dati da inserire nei client RustDesk.

Set-Location $PSScriptRoot

$keyFile = Join-Path $PSScriptRoot "data\id_ed25519.pub"
if (-not (Test-Path $keyFile)) {
    Write-Host "Chiave non trovata: esegui prima .\1-installa.ps1" -ForegroundColor Red
    exit 1
}
$key = (Get-Content $keyFile -Raw).Trim()

$ip = "(IP della VPS)"
if (Test-Path .env) {
    $m = Select-String -Path .env -Pattern '^IP_VPS=(.+)$'
    if ($m) { $ip = $m.Matches[0].Groups[1].Value.Trim() }
}

Write-Host "Server ID    : $ip"
Write-Host "Server relay : $ip"
Write-Host "Server API   : (lascia vuoto)"
Write-Host "Key          : $key"
