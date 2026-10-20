# RustDesk Server – Docker su VPS Windows

Server RustDesk self-hosted (ID + relay) per sostituire AnyDesk/TeamViewer: niente limiti di tempo, niente licenze, connessioni cifrate con la chiave del proprio server.

## Contenuto

| File | A cosa serve |
|---|---|
| `docker-compose.yml` | Container `rustdesk-id-server` (hbbs) e `rustdesk-relay-server` (hbbr) |
| `1-installa.ps1` | Prima installazione: controlli, IP, firewall, avvio, stampa la chiave |
| `2-mostra-chiave.ps1` | Rimostra i dati da inserire nei client |
| `3-aggiorna.ps1` | Aggiorna il server all'ultima versione |
| `4-stato.ps1` | Stato dei container e ultimi log |
| `5-ferma.ps1` | Ferma il server (la chiave resta) |

Generati dall'installazione e **esclusi dal repository**:

- `.env` contiene l'IP della VPS.
- `data/` contiene la chiave del server. Fanne un backup e non condividerla.

## Requisiti

- VPS Windows con Docker Desktop avviato
- Porte aperte (anche nel firewall del provider): **TCP 21115-21117**, **UDP 21116**

## Installazione

PowerShell **come amministratore** sulla VPS:

```powershell
git clone <URL-REPO> C:\rustdesk
cd C:\rustdesk
powershell -ExecutionPolicy Bypass -File .\1-installa.ps1
```

Lo script stampa alla fine i dati per i client.

## Configurazione client

In RustDesk vai su **Impostazioni → Rete → Server ID/Relay** e compila:

| Campo | Valore |
|---|---|
| Server ID | IP della VPS |
| Server relay | IP della VPS |
| Server API | vuoto |
| Key | chiave mostrata dallo script |

**Trucco Windows:** se rinomini l'installer in `rustdesk-host=IP,key=CHIAVE,.exe`, si configura da solo.

## Aggiornamento

### Nuova versione di RustDesk Server

Le versioni escono su [github.com/rustdesk/rustdesk-server/releases](https://github.com/rustdesk/rustdesk-server/releases).

```powershell
cd C:\rustdesk
powershell -ExecutionPolicy Bypass -File .\3-aggiorna.ps1
powershell -ExecutionPolicy Bypass -File .\4-stato.ps1   # verifica che sia tutto ok
```

La chiave non cambia, quindi i client non vanno riconfigurati.

### Nuova versione degli script di questo repository

```powershell
cd C:\rustdesk
git pull
docker compose up -d
```

### Client

Aggiorna i client dall'app RustDesk oppure scarica la nuova versione da [rustdesk.com](https://rustdesk.com). La configurazione resta.

## Riavvio della VPS

Docker Desktop parte solo dopo l'accesso a Windows. Per farlo ripartire da solo dopo un riavvio:

1. In Docker Desktop vai su **Settings → General** e attiva **Start Docker Desktop when you sign in**.
2. Premi `Win+R`, lancia `netplwiz` e togli la spunta da **Gli utenti devono immettere nome utente e password**.

## Problemi comuni

- **Client su "Non pronto":** controlla le porte nel firewall del provider e i log con `4-stato.ps1`.
- **IP della VPS cambiato:** cancella `.env` e rilancia `1-installa.ps1`.
