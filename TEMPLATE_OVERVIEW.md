# OpenSondage / Framadate — Self-Hosted Polls & Scheduling on Railway

One click deploys **Framadate (OpenSondage)** — the classic open-source tool for
date polls and classic polls — together with its **MariaDB** database, fully
configured and ready to share poll links.

> ⚠️ **Honest maintenance disclosure:** Framadate's upstream project is
> effectively unmaintained (final release 1.1.19, December 2021, pinned by
> digest in this template). It still works well for polls and scheduling, but
> expect no upstream security or bug fixes. If you need a maintained
> alternative, look at **Rallly** or **crab.fit** — both are actively
> developed and also self-hostable.

## Features

- **Date polls and classic polls** — the original "find a time that works for
  everyone" workflow, with public voting links and private admin links.
- **One-click MariaDB included** — all polls, votes and comments live in
  MariaDB on a persistent volume; the app itself is stateless.
- **Zero deploy-form inputs** — admin password, database credentials and
  hostnames are generated automatically during provisioning.
- **Auto schema migration** — the container bootstraps the full database
  schema at boot (idempotent, re-run safe), so a fresh deploy is immediately
  poll-creating.
- **Email-ready (optional)** — set `USE_SMTP=true` plus your `SMTP_*` values
  after deploy to mail poll links and notifications; everything else works
  with email disabled.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/opensondage-template)

# Deploy and Host

Deploying provisions two services:

| Service | Image | Role |
|---|---|---|
| `framadate` | `xgaia/framadate:1.1.19` (digest-pinned) | PHP/Apache app on port 80, public domain auto-provisioned |
| `mariadb` | `mariadb:10.11` (digest-pinned) | Database with a persistent volume at `/var/lib/mysql` |

On first boot the app container waits for Apache, generates the admin
credentials and configuration from its environment, and runs the database
schema migration through `/admin/migration.php` (idempotent — tracked in the
`fd_framadate_migration` table). Within a minute of clicking deploy the poll
home page is live on your Railway domain.

## About Hosting

Hosting Framadate yourself means your polls, voter names and schedules live in
your own database — no third-party tracking, no poll expiry imposed by a
hosting company, and no feature gating. This template keeps the footprint
small: one stateless PHP container and one MariaDB container with a volume,
typically **$3–5/month** on Railway's Hobby plan.

What is provisioned and configured for you:

- `framadate` service — public domain on port 80; `SERVERNAME` follows your
  Railway domain automatically; admin panel at `/admin` protected by HTTP
  Basic Auth with a generated `ADMIN_PASSWORD`.
- `mariadb` service — root and app passwords generated via
  `${{secret(24,"alnum")}}`; the app connects over Railway private networking
  (`DB_HOST=${{mariadb.RAILWAY_PRIVATE_DOMAIN}}`,
  `DB_PASSWORD=${{mariadb.MARIADB_PASSWORD}}`).
- A persistent volume on MariaDB — deleting/redeploying the app never loses
  polls; only deleting the volume does.

## Why Deploy

- **Manual deploy is fiddly** — Framadate needs Apache with mod_php, a MySQL
  schema migration through an admin panel, and a hand-written `config.php`.
  This template ships a boot wrapper that does all three on every start.
- **Railway fixes baked in** — the image pins the final upstream release,
  forces the correct Apache MPM (fixes the `AH00534` crash-loop seen on
  container platforms), defaults the UI to English, and ships with SMTP
  disabled so an unreachable mail relay can never break poll creation.
- **Data safety by design** — polls survive redeploys and restarts because
  persistence lives in the MariaDB volume, not the app container.

## Common Use Cases

- Team and community **scheduling** — meeting dates, game nights, events.
- **Classic polls** — text-choice polls for names, topics, logos, decisions.
- Self-hosted alternative to Doodle/StrawPoll for privacy-conscious groups.
- A simple, proven poll tool for clubs, classrooms and open-source projects.

## Dependencies for

The template is self-contained: no external database, cache or API keys are
required. Email delivery (optional) is the only external dependency.

### Deployment Dependencies

- **None required at deploy time** — no deploy-form inputs; secrets and
  hostnames are provisioned automatically.
- **Optional SMTP relay** — for email notifications set on the `framadate`
  service after deploy: `USE_SMTP=true`, `SMTP_HOST`, `SMTP_PORT` (587),
  `SMTP_SECURE` (`tls`/`ssl`), `SMTP_AUTH`, `SMTP_USERNAME`, `SMTP_PASSWORD`,
  and `EMAIL_ADRESS` (sender address your relay accepts).
- Railway private networking (built-in) — used for app→database traffic.

## Post-deploy steps

1. Open your Railway domain — the poll home page loads.
2. Open `/admin` — user `admin`, password from the `ADMIN_PASSWORD` variable
   on the `framadate` service (Variables tab).
3. Schema migration runs automatically at boot; if you ever need to re-run it,
   open `/admin/migration.php` and log in with the same credentials.
4. Create a poll from the home page and share the public link.

## Troubleshooting

- **DB errors right after deploy** — MariaDB may still be initializing; the
  app retries the migration for ~1 minute at boot, and you can re-run
  `/admin/migration.php` manually at any time (idempotent).
- **Poll creation errors mentioning SMTP** — `USE_SMTP` was enabled without a
  working relay; set it back to `false` or fix the `SMTP_*` variables.
- **Lost data** — polls live only in the MariaDB volume; deleting that volume
  deletes all polls.
