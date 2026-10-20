# Installa e avvia il server RustDesk sulla VPS.
# Uso (PowerShell come amministratore, dentro questa cartella):
#   powershell -ExecutionPolicy Bypass -File .\1-installa.ps1

Set-Location $PSScriptRoot

function Fail($msg) {
    Write-Host $msg -ForegroundColor Red
    exit 1
}

# --- Amministratore ---
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Fail "Apri PowerShell come AMMINISTRATORE e rilancia lo script."
}

# --- Docker ---
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Fail "Docker non risponde: avvia Docker Desktop, aspetta che sia pronto e riprova."
}
Write-Host "[OK] Docker attivo" -ForegroundColor Green

# --- Porte libere (solo se RustDesk non e' gia' in esecuzione) ---
$running = docker ps --filter "name=rustdesk-" --format "{{.Names}}"
if (-not $running) {
    $busyTcp = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalPort -ge 21115 -and $_.LocalPort -le 21117 }
    $busyUdp = Get-NetUDPEndpoint -ErrorAction SilentlyContinue |
        Where-Object { $_.LocalPort -eq 21116 }
    if ($busyTcp -or $busyUdp) {
        Write-Host "Queste porte sono gia' usate da un altro programma:" -ForegroundColor Red
        foreach ($c in @($busyTcp) + @($busyUdp)) {
            if (-not $c) { continue }
            $proc = (Get-Process -Id $c.OwningProcess -ErrorAction SilentlyContinue).ProcessName
            Write-Host ("  porta {0}  ->  {1} (PID {2})" -f $c.LocalPort, $proc, $c.OwningProcess)
        }
        exit 1
    }
    Write-Host "[OK] Porte 21115-21117 libere" -ForegroundColor Green
} else {
    Write-Host "[OK] RustDesk e' gia' in esecuzione, verra' aggiornata la configurazione" -ForegroundColor Green
}

# --- IP pubblico della VPS (salvato nel file .env) ---
$ip = $null
if (Test-Path .env) {
    $m = Select-String -Path .env -Pattern '^IP_VPS=(.+)$'
    if ($m) { $ip = $m.Matches[0].Groups[1].Value.Trim() }
}
if (-not $ip) {
    $guess = $null
    try { $guess = (Invoke-RestMethod -Uri "https://api.ipify.org" -TimeoutSec 5).Trim() } catch {}
    if ($guess) {
        $answer = Read-Host "IP pubblico della VPS rilevato: $guess  (Invio per confermare, oppure scrivi IP/dominio)"
        if ($answer) { $ip = $answer.Trim() } else { $ip = $guess }
    } else {
        $ip = (Read-Host "Scrivi l'IP pubblico (o il dominio) della VPS").Trim()
    }
    if (-not $ip -or $ip -match '\s') { Fail "IP non valido." }
    Set-Content -Path .env -Value "IP_VPS=$ip" -Encoding Ascii
}
Write-Host "[OK] IP della VPS: $ip" -ForegroundColor Green

# --- Firewall di Windows ---
Get-NetFirewallRule -DisplayName "RustDesk TCP", "RustDesk UDP" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName "RustDesk TCP" -Direction Inbound -Protocol TCP -LocalPort 21115-21117 -Action Allow | Out-Null
New-NetFirewallRule -DisplayName "RustDesk UDP" -Direction Inbound -Protocol UDP -LocalPort 21116 -Action Allow | Out-Null
Write-Host "[OK] Firewall: aperte TCP 21115-21117 e UDP 21116" -ForegroundColor Green

# --- Avvio container ---
docker compose up -d
if ($LASTEXITCODE -ne 0) { Fail "docker compose non e' riuscito ad avviare i container." }
Write-Host "[OK] Container avviati" -ForegroundColor Green

# --- Chiave pubblica ---
$keyFile = Join-Path $PSScriptRoot "data\id_ed25519.pub"
for ($i = 0; $i -lt 30 -and -not (Test-Path $keyFile); $i++) { Start-Sleep -Seconds 1 }
if (-not (Test-Path $keyFile)) { Fail "La chiave non e' stata generata. Controlla i log con .\4-stato.ps1" }
$key = (Get-Content $keyFile -Raw).Trim()

Write-Host ""
Write-Host "================ DATI PER I CLIENT ================" -ForegroundColor Cyan
Write-Host "Server ID    : $ip"
Write-Host "Server relay : $ip"
Write-Host "Server API   : (lascia vuoto)"
Write-Host "Key          : $key"
if ($key -notmatch '[/\\]') {
    Write-Host ""
    Write-Host "Nome installer Windows auto-configurato:"
    Write-Host "  rustdesk-host=$ip,key=$key,.exe"
}
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ricorda di aprire le stesse porte anche nel firewall del pannello del provider, se ne ha uno."
