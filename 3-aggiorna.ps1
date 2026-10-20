# Scarica l'ultima versione del server RustDesk e riavvia i container.
# La chiave (cartella data) resta la stessa: i client non vanno riconfigurati.

Set-Location $PSScriptRoot

docker compose pull
docker compose up -d
docker compose ps
