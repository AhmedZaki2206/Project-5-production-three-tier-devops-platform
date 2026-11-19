# Hands-on Labs

قبل كل incident شغّل baseline وتأكد من readiness. اجمع evidence قبل الحل. `./lab.sh reset ID` يعيد Compose الأساسي ولا يحذف database volume.

## Initial deployment and API

**Goal:** بناء المنصة وإنشاء/retrieve asset. **Setup:** `cp .env.example .env && docker compose up -d --build --wait`. **Commands:** health check ثم POST وGET من README. **Expected:** HTTP 201 ثم record في list. **Troubleshooting:** راجع migrate/app logs وvalidation body. **Verify:** `./scripts/smoke-test.sh`. **Cleanup:** احذف record التجريبي أو اتركه للbackup lab.

## Persistence and backup/restore

**Goal:** إثبات أن volume تحفظ data وأن backup قابلة للاسترجاع. أنشئ 3 assets، سجل IDs، نفذ backup، احذف record، restore، ثم قارن الـhostnames. **Pass:** البيانات الأصلية ترجع و`db-verify.sh` ينجح. **Common error:** اعتبار وجود الملف دليلًا كافيًا بدون restore.

## Ten troubleshooting exercises

### 01 — Nginx 502 Bad Gateway

- **Inject:** `./lab.sh start 01` يوجه upstream إلى `app:9999`.
- **Symptoms:** HTTP 502 و`connect() failed` في Nginx log.
- **Diagnose:** `docker compose logs proxy`; `docker compose exec proxy nginx -T`; اختبر `app:8000` من network.
- **Hint:** `./lab.sh hint 01`.
- **Fix:** أعد config الأساسية واختبر `nginx -t` قبل recreate.
- **Verify/reset:** readiness 200، ثم `./lab.sh reset 01`.
- **Root cause:** upstream port خاطئ، وليس database failure.

### 02 — FastAPI restart loop

- **Inject:** `./lab.sh start 02` يستبدل command بخروج code 42.
- **Diagnose:** `docker compose ps`; `docker inspect ... --format '{{.RestartCount}}'`; logs.
- **Fix:** أزل override وأعد app بالصورة الصحيحة.
- **Verify/reset:** restart count ثابت وreadiness 200؛ `./lab.sh reset 02`.

### 03 — PostgreSQL unavailable

- **Inject:** `./lab.sh start 03` يوقف db container فقط.
- **Symptoms:** readiness 503 وCRUD fails بينما liveness قد يظل 200.
- **Diagnose:** `compose ps`, `pg_isready`, app logs, DNS ثم TCP.
- **Fix:** `docker compose start db` وانتظر health.
- **Verify/reset:** `SELECT 1`/readiness؛ reset.

### 04 — Incorrect DB credentials

- **Inject:** `./lab.sh start 04` يعيد app بـpassword خاطئ.
- **Diagnose:** inspect environment بحذر، authentication failure في logs، تأكد أن db healthy.
- **Fix:** صحح secret source وأعد app. لا تطبع password في issue أو screenshot.
- **Verify/reset:** readiness 200؛ reset.

### 05 — Docker network isolation problem

- **Inject:** `./lab.sh start 05` يفصل app عن backend network.
- **Diagnose:** `docker inspect` للـnetworks و`getent hosts db` من app.
- **Fix:** app لازم يكون على frontend وbackend؛ db على backend فقط.
- **Verify/reset:** DNS و5432 ثم readiness؛ reset.

### 06 — Persistent volume/data issue

- **Inject:** `./lab.sh start 06` يشغل db مع bind mount read-only تجريبي.
- **Symptoms:** PostgreSQL لا يبدأ وlogs تعرض permission/data directory errors.
- **Diagnose:** `docker inspect` mounts وdb logs. لا تحذف named volume الأصلية.
- **Fix:** أزل override واستخدم `three-tier-postgres-data`.
- **Verify/reset:** assets الأصلية ما زالت موجودة بعد reset.

### 07 — Readiness fails

- **Inject:** `./lab.sh start 07` يستخدم DB port 5999.
- **Diagnose:** قارن `/health/live` مع `/health/ready`، افحص `DATABASE_URL` و`ss/nc`.
- **Fix:** port الداخلي الصحيح 5432.
- **Verify/reset:** liveness وreadiness 200؛ reset.

### 08 — CI fails بسبب broken test

- **Inject:** `./lab.sh start 08` يحفظ test file ثم يضيف assertion فاشلة محليًا.
- **Diagnose:** `pytest -x -vv` واقرأ test name والassertion diff.
- **Fix:** افهم هل bug في code أم expectation. في lab الحل reset لإرجاع الملف المحفوظ.
- **Verify/reset:** `./lab.sh reset 08 && pytest`.

### 09 — Wrong image tag

- **Inject:** بعد `./lab.sh start 09` نفذ `docker pull ghcr.io/example/three-tier-portal:does-not-exist`.
- **Diagnose:** فرق بين unauthorized وmanifest unknown، وافحص registry/repository/tag.
- **Fix:** استخدم full SHA tag موجود وموثق.
- **Verify/reset:** deploy tag صالح وreadiness؛ reset.

### 10 — Failed backup restore

- **Inject:** `./lab.sh start 10` ينشئ `.lab-state/corrupt.sql.gz` غير صالح.
- **Diagnose:** `gzip -t .lab-state/corrupt.sql.gz` يجب أن يفشل قبل restore.
- **Fix:** اختر backup صحيحة، تحقق من timestamp/hash ثم restore مع confirmation.
- **Verify/reset:** `db-verify.sh` وعدد records؛ reset.

## Rollback exercise

ابنِ tag `portal:v1` وشغله، ثم tag `portal:v2` مع version جديدة. استخدم deploy لكل tag، تأكد أن `previous-image` يحتوي v1، ثم rollback. Evidence: version endpoint، current/previous files، readiness وlogs. لا تنفذ schema downgrade تلقائيًا.

## Final Junior DevOps assessment

| Task | Expected outcome | Pass criteria and evidence | Common mistake |
|---|---|---|---|
| 1 Deploy from scratch | Three tiers healthy | Compose ps + readiness 200 | تجاهل migrate failure |
| 2 CRUD records | Create/get/delete works | HTTP codes and JSON | عدم اختبار validation |
| 3 Backup/restore | Deleted row returns | backup name + before/after data | الاكتفاء بـgzip test |
| 4 Repair Nginx | 502 becomes 200 | error log + `nginx -t` | restart بلا evidence |
| 5 Investigate CI | failing step/root cause found | local command and fix | تغيير workflow لإخفاء failure |
| 6 Deploy image | exact immutable tag healthy | SHA tag + readiness | استخدام `latest` |
| 7 Rollback | previous image restored | version + health | خلط image/schema rollback |
| 8 Explain isolation | DB unreachable from host/frontend | diagram + network inspect | القول إن `expose` firewall |
| 9 Ansible idempotency | second run changed=0 | two recaps | تشغيله على workstation |
| 10 Explain in English | clear five-minute story | architecture, CI, recovery | ادعاء production usage |
