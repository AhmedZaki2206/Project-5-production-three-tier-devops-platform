# Operations Runbook

## Start, stop and status

```bash
docker compose config --quiet
docker compose up -d --wait
docker compose ps
docker compose down --remove-orphans
```

Healthy order: `db` → `migrate` exit 0 → `app` → `proxy`. Do not use `down --volumes` during normal operations.

## Health and logs

```bash
./scripts/health-check.sh
curl -i http://127.0.0.1:8080/health/live
curl -i http://127.0.0.1:8080/health/ready
docker compose logs --since=10m --tail=200 proxy app db migrate
docker compose exec proxy nginx -t
docker compose exec db pg_isready
```

Liveness answers whether the process runs. Readiness includes database access and determines whether the request path can serve real work.

## Incident triage

1. Record time, impact and exact status code.
2. Run `docker compose ps` and collect logs before restarting.
3. Test each hop: host→proxy, proxy→app, app→db.
4. Check recent image/config/migration changes.
5. Apply the smallest reversible correction.
6. Verify readiness and one CRUD request; document root cause.

`502` usually means Nginx cannot get a valid upstream response. `503` can be explicit unavailability or failed dependency readiness. Connection refused differs from timeout: refused normally reaches the target but finds no listener.

## Backup and restore

```bash
./scripts/db-backup.sh
gzip -t backups/portal-TIMESTAMP.sql.gz
./scripts/db-restore.sh backups/portal-TIMESTAMP.sql.gz
./scripts/db-verify.sh
```

Before restore, confirm project, file timestamp and impact. Stop write traffic for a consistent recovery exercise. Preserve the failed database and logs until root cause is understood.

## Deployment and rollback

```bash
./scripts/deploy.sh IMAGE_TAG
cat .deployment/current-image
cat .deployment/previous-image
./scripts/rollback.sh
```

If readiness fails, inspect logs and decide whether the failure is image, configuration or schema related. Roll back only when the recorded image is compatible with the current schema.

## Emergency recovery and escalation

Escalate when data integrity is uncertain, restore verification fails, migrations are partially applied, secrets may be exposed, or the blast radius is unclear. Provide timeline, commands, relevant log excerpts, image SHA, migration revision and backup filename. Do not hide failed attempts.
