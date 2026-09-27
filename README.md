# OpenSondage / Framadate — Railway Template

Classic self-hosted polls and scheduling (date + classic polls), deployable to
Railway in one click with a MariaDB backend.

> ⚠️ **Maintenance disclosure (read before deploying):** Framadate's upstream
> project ([framagit.org/framasoft/framadate](https://framagit.org/framasoft/framadate))
> is **effectively unmaintained** — the final release is 1.1.19 (2021-12-23),
> which this template pins. It still works well, but expect no upstream bug or
> security fixes. If you want a maintained alternative, consider deploying
> **[Rallly](https://github.com/lukevella/rallly)** or **[crab.fit](https://github.com/GRA0007/crab.fit)**
> instead — both are actively developed and also have self-hostable images.

## What gets deployed

| Service | Image | Notes |
|---|---|---|
| `framadate` | `xgaia/framadate:1.1.19` (digest-pinned) | Stateless PHP app (Apache, port 80). Serves the poll UI and the `/admin` panel. |
| `mariadb` | `mariadb:10.11` (digest-pinned) | **The only persistence.** All polls, votes and comments live in MariaDB on a volume mounted at `/var/lib/mysql`. |

The app is stateless — if you ever need to wipe data, the MariaDB volume is the
single source of truth.

## After deploying

1. **Open the app** at your Railway domain — the poll home page should load.
2. **Schema migration runs automatically.** On boot, the container waits for
   Apache, then calls `/admin/migration.php` (idempotent, tracked in the
   `fd_framadate_migration` table). On a fresh database this bootstraps the
   full schema. You normally never need to do anything.
   - Manual fallback: open `https://<your-domain>/admin/migration.php`
     (HTTP Basic Auth, user `admin`, password = `ADMIN_PASSWORD`).
3. **Admin panel** at `https://<your-domain>/admin` — log in with user
   `admin` and the generated `ADMIN_PASSWORD` (find it under the `framadate`
   service → Variables in Railway).
4. **Create a poll** from the home page ("Make a date poll" or "Make a classic
   poll"). You get an admin link (edit/manage) and a public link to share.
5. **Vote** via the public link.

## Variables

### framadate service

| Variable | Default | Purpose |
|---|---|---|
| `ADMIN_PASSWORD` | generated (`${{secret(24,"alnum")}}`) | Password for `/admin` (HTTP Basic Auth, user `admin`). |
| `APP_NAME` | `Framadate` | Application name shown in the UI. |
| `EMAIL_ADRESS` | `admin@example.org` | Admin/poll-creator email (mail sender identity). Yes, the spelling is the upstream image's. |
| `DB_HOST` | `${{mariadb.RAILWAY_PRIVATE_DOMAIN}}` | MariaDB hostname (private network). |
| `DB_NAME` / `DB_USER` / `DB_PASSWORD` | `framadate` / `framadate` / referenced from mariadb | Database credentials (referenced from the `mariadb` service). |
| `SERVERNAME` | Railway public domain | Apache vhost ServerName. |
| `USE_SMTP` | `false` | **Leave `false` until SMTP is configured** (see below). |
| `SMTP_HOST` / `SMTP_PORT` | `smtp.example.com` / `587` | SMTP relay host/port. |
| `SMTP_AUTH` / `SMTP_USERNAME` / `SMTP_PASSWORD` | `true` / `admin` / `admin` | SMTP credentials (only used when `SMTP_AUTH=true`). |
| `SMTP_SECURE` | `tls` | `tls`, `ssl`, or `false`. |
| `DEFAULT_POLL_DURATION` | `365` | Default poll lifetime in days. |

### mariadb service

| Variable | Default | Purpose |
|---|---|---|
| `MARIADB_ROOT_PASSWORD` | generated | Root password. |
| `MARIADB_PASSWORD` | generated | Password for the `framadate` app user (referenced by the app). |
| `MARIADB_DATABASE` / `MARIADB_USER` | `framadate` / `framadate` | Fixed by the Dockerfile. |

## Email (optional, post-deploy)

Framadate can mail poll links, notifications and the "forgot edit link" emails.
Railway has no built-in SMTP relay, so bring your own (Resend + SMTP bridge,
Gmail app password, Mailgun, your own relay, …):

1. Set `USE_SMTP=true` on the `framadate` service.
2. Fill `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, and (if the relay requires
   auth) `SMTP_AUTH=true`, `SMTP_USERNAME`, `SMTP_PASSWORD`.
3. Set `EMAIL_ADRESS` to the sender address your relay will accept.
4. Redeploy. **While `USE_SMTP=false`, everything else still works** — poll
   creation, sharing and voting just skip the email step.

## Cost

Roughly **$3–5/month** on Railway (Hobby): the PHP app runs on minimal
resources; the MariaDB instance with a small volume dominates the cost.

## Troubleshooting

- **"Migration did not complete" in the logs / polls error with DB messages:**
  MariaDB may still be initializing on first boot. The app keeps running;
  either redeploy the `framadate` service or open `/admin/migration.php`
  manually (user `admin`, `ADMIN_PASSWORD` variable). The migration is
  idempotent and safe to re-run any time.
- **Poll creation fails / page error mentioning SMTP:** `USE_SMTP` was set to
  `true` without a reachable relay. Set `USE_SMTP=false` or fix the `SMTP_*`
  variables and redeploy.
- **502 on the app but MariaDB healthy:** check the `framadate` deploy logs
  for the `AH00534` MPM error — the Dockerfile already disables extra MPMs;
  a custom Apache config could reintroduce it.
- **Lost data:** polls live only in MariaDB. Do not delete the `mariadb`
  volume; the app container itself holds nothing.

## Image provenance

- App image: [`xgaia/framadate:1.1.19`](https://hub.docker.com/r/xgaia/framadate)
  pinned to `sha256:edf6890dcd676b50adf7d3bdd82a2bd7c285ec7544adc9ac837de78b15e8c718`.
- Database image: [`mariadb:10.11`](https://hub.docker.com/_/mariadb) pinned to
  `sha256:7f22313fc130a377a44999965bcb0a08dd5b21e8502824c1b864f792f9bc66ab`.
- Local changes in the app image (see `framadate/Dockerfile`): MPM fix for
  Railway, `USE_SMTP` toggle (prevents fatal errors on unreachable relays),
  English as default UI language, `/health.php` liveness endpoint, and the
  auto-migration boot wrapper `railway-start.sh`.
