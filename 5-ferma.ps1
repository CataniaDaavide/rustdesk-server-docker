# Ferma e rimuove i container RustDesk.
# La cartella data (con la chiave) NON viene cancellata: con .\1-installa.ps1 riparte tutto uguale.

Set-Location $PSScriptRoot

docker compose down
