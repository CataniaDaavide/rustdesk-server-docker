# Mostra lo stato dei container e gli ultimi log.

Set-Location $PSScriptRoot

docker compose ps
Write-Host ""
docker compose logs --tail 30
