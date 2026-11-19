# Junior DevOps Interview Preparation

## 60-second explanation

**Arabic:** بنيت personal three-tier platform: Nginx يستقبل على loopback، FastAPI يقدم asset CRUD، وPostgreSQL يحتفظ بالبيانات على volume. قسمت frontend/backend networks، أضفت Alembic migrations وhealthchecks وbackup/restore وdeploy/rollback. PR CI يشغل tests وlint وCompose وTrivy وintegration smoke، وmain ينشر SHA-tagged image إلى GHCR بدون automatic deployment. Ansible يجهز disposable Ubuntu VM. المشروع portfolio learning وليس employer production.

**English:** “I built a local three-tier Infrastructure Service Portal with Nginx, FastAPI, and PostgreSQL. I separated frontend and backend networks, added migrations, health checks, persistent storage, verified backup and restore, and image rollback. Pull requests run tests, image scanning, and a real Compose smoke test. Main publishes an immutable SHA-tagged image to GHCR, while deployment remains manual.”

## Five-minute explanation

ابدأ بالهدف والrequest path، ثم اشرح network segmentation وسبب عدم نشر app/db ports. اشرح readiness التي تنفذ `SELECT 1`، Alembic migrate service، named volume، backup/restore verification. بعد ذلك اشرح PR gates، Trivy وGHCR SHA tag. استخدم incident 502 كمثال symptom→evidence→root cause→fix→verification. اختم بالقيود: local HTTP، single host، secrets محلية، وعدم وجود production claim.

## 40 questions and answers

1. **What is a three-tier architecture?** Short: presentation, application and data tiers. Arabic: هنا Nginx ثم FastAPI ثم PostgreSQL، وكل hop له responsibility وnetwork access. English: “Each tier has a focused role and communicates through a defined interface.” Example: db لا ينضم إلى frontend.
2. **Why Nginx?** Short: reverse proxy. Arabic: يخفي app topology ويضيف headers/logging/timeouts. English: “Nginx provides a stable entry point and forwards traffic to the API.” Example: `portal_api` upstream.
3. **What is an upstream?** Short: backend target group. Arabic: Nginx يحل `app` عبر Docker DNS ويرسل إلى 8000. English: “An upstream defines where proxied requests are sent.” Example: wrong 9999 creates lab 01.
4. **What causes 502?** Short: invalid/unreachable upstream response. Arabic: افحص Nginx error log ثم app DNS/port/process. English: “A 502 points to a gateway-to-upstream failure.” Example: bad upstream override.
5. **What causes 503?** Short: service unavailable. Arabic: readiness failure أو explicit maintenance response. English: “A 503 means the service cannot currently accept work.” Example: database readiness returns 503.
6. **Liveness vs readiness?** Short: process alive vs able to serve. Arabic: liveness لا تعتمد على db؛ readiness تعمل `SELECT 1`. English: “Liveness detects a dead process; readiness includes dependencies.” Example: db stopped keeps live but fails ready.
7. **Why FastAPI?** Short: typed validation and simple APIs. Arabic: Pydantic يولد 422 للinput الخاطئ وOpenAPI docs. English: “FastAPI gives typed contracts and clear validation.” Example: invalid IP test.
8. **Why SQLAlchemy?** Short: explicit database sessions and models. Arabic: يفصل Python domain عن SQL driver مع transaction control. English: “SQLAlchemy provides predictable ORM and transaction boundaries.” Example: rollback on duplicate hostname.
9. **Why Alembic?** Short: versioned schema changes. Arabic: container image وحدها لا تدير schema history. English: “Alembic makes database changes reviewable and repeatable.” Example: migrate service runs before app.
10. **Is every migration reversible?** Short: no. Arabic: downgrade قد يفقد data؛ لازم review/backup. English: “Migration rollback is a data decision, not an automatic image rollback.” Example: rollback script changes app only.
11. **Image vs container?** Short: artifact vs running instance. Arabic: نفس image ممكن تعمل منها containers متعددة. English: “An image is immutable input; a container is its runtime instance.” Example: SHA image deployed by Compose.
12. **Volume vs bind mount?** Short: Docker-managed data vs host path. Arabic: Postgres named volume؛ Nginx config bind mount. English: “Volumes suit managed persistence; bind mounts expose a specific host file.” Example: `postgres_data` and `nginx.conf`.
13. **Expose vs ports?** Short: internal metadata vs host publication. Arabic: `expose:8000` لا يفتح host. English: “Only ports publishes a host socket.” Example: proxy alone publishes 8080.
14. **Why two networks?** Short: reduce reachability. Arabic: proxy لا يرى db، وdb لا يوجد على frontend. English: “Network membership limits which services can resolve and connect.” Example: app bridges both.
15. **Does Docker network replace authentication?** Short: no. Arabic: segmentation يقلل reachability لكن credentials وleast privilege لازمين. English: “Network isolation complements database authentication.” Example: app DB user/password.
16. **How does Docker DNS work?** Short: service names resolve on shared networks. Arabic: `app` و`db` names stable حتى IP يتغير. English: “Compose service discovery resolves names within a shared network.” Example: Nginx uses `app:8000`.
17. **Why non-root app?** Short: reduce impact. Arabic: لو app اتخترقت، attacker لا يبدأ UID 0. English: “A non-root runtime reduces container privileges.” Example: Dockerfile `USER app`.
18. **Why read-only filesystem?** Short: limit mutation. Arabic: app تكتب فقط في tmpfs المحددة. English: “Read-only root filesystems reduce persistence opportunities.” Example: `/tmp:size=32m`.
19. **What is no-new-privileges?** Short: blocks privilege gain. Arabic: يمنع exec من اكتساب privileges إضافية. English: “It prevents processes from gaining new privileges.” Example: all services set security option.
20. **What is a healthcheck?** Short: repeatable runtime assertion. Arabic: startup ordering يعتمد على db/app health. English: “A health check turns service state into a machine-readable signal.” Example: `pg_isready` and HTTP ready.
21. **What is persistence testing?** Short: recreate container and confirm data. Arabic: volume لازم تظل بعد `down` بدون `--volumes`. English: “I replace containers and verify records remain.” Example: persistence lab.
22. **What makes a backup valid?** Short: successful restore verification. Arabic: وجود gzip لا يكفي. English: “A backup is credible after integrity and restore checks.” Example: restore then `db-verify.sh`.
23. **Why timestamp backups?** Short: traceable recovery points. Arabic: يسهل اختيار point-in-time وincident timeline. English: “Timestamps make recovery artifacts identifiable.” Example: UTC filename.
24. **Why restore confirmation?** Short: overwrite risk. Arabic: يمنع command accidental؛ `--yes` للexercise controlled فقط. English: “Explicit confirmation protects destructive recovery operations.” Example: type RESTORE.
25. **What is CI?** Short: automated validation of change. Arabic: PR يشغل lint/tests/build/scan/smoke. English: “CI gives fast evidence that a proposed change is safe to merge.” Example: `ci.yml`.
26. **What is CD here?** Short: artifact publication. Arabic: main ينشر image لكن لا deploy server. English: “The pipeline delivers an immutable image; deployment is manual.” Example: GHCR workflow.
27. **Why SHA tags?** Short: immutable traceability. Arabic: تعرف image مرتبطة بأي commit وتعمل rollback دقيق. English: “A full Git SHA creates an auditable deployment reference.” Example: GHCR tag.
28. **Why avoid latest?** Short: mutable and ambiguous. Arabic: rollback وincident comparison يصبحوا غير موثوقين. English: “Latest does not identify exact content.” Example: wrong-image lab.
29. **What does Trivy add?** Short: image vulnerability scan. Arabic: CI يفشل على fixed high/critical findings حسب policy. English: “Trivy checks OS and application packages before publication.” Example: PR gate.
30. **Least privilege in Actions?** Short: minimum token permissions. Arabic: PR `contents:read`، publish فقط يضيف `packages:write`. English: “Each workflow receives only the permissions it needs.” Example: separate workflows.
31. **How do you troubleshoot CI?** Short: first failed step locally. Arabic: اقرأ exit code/command، reproduce، أصلح root cause. English: “I reproduce the first meaningful failure with the same command.” Example: broken pytest lab.
32. **What is idempotent Ansible?** Short: repeated run converges without changes. Arabic: modules تصف desired state. English: “The second run should report no change when state already matches.” Example: package/file/Compose tasks.
33. **Why handlers?** Short: restart only after change. Arabic: config copy/template notify handler. English: “Handlers avoid unnecessary restarts.” Example: stack restart handler.
34. **How are Ansible secrets handled?** Short: Vault, not Git plaintext. Arabic: template يأخذ `vault_portal_db_password`. English: “I inject encrypted variables at run time.” Example: vault file ignored/not committed.
35. **How does deploy fail safely?** Short: validate, pull/build, update, health gate. Arabic: لا يسجل current tag إلا بعد readiness. English: “The deployment is recorded only after readiness succeeds.” Example: `deploy.sh`.
36. **How does rollback work?** Short: explicit previous image. Arabic: state files تحت `.deployment` وتحقيق health بعد update. English: “Rollback selects a recorded working tag and revalidates service health.” Example: `rollback.sh`.
37. **Connection refused vs timeout?** Short: no listener/reject vs no timely response. Arabic: refusal غالبًا path وصل target؛ timeout قد يكون routing/filtering/latency. English: “They point to different layers of failure.” Example: test app:8000 with `nc`.
38. **How do you protect secrets in logs?** Short: avoid echo and use `no_log`. Arabic: لا تطبع DATABASE_URL كاملة ولا screenshots. English: “I redact credentials and prevent secret-bearing tasks from logging.” Example: Ansible template `no_log`.
39. **What are project limitations?** Short: local single-host HTTP lab. Arabic: لا HA/TLS/managed secrets أو production SLO. English: “It demonstrates operational patterns locally, not production scale.” Example: loopback Nginx.
40. **What would you improve next?** Short: trusted TLS, secret manager, stronger DB roles and restore drills. Arabic: أضيفهم عند وجود environment حقيقي بدون إدخال Kubernetes هنا. English: “I would strengthen secret lifecycle, TLS, privilege separation, and recovery testing.” Example: split migration/runtime DB users.

## Follow-ups and mistakes to avoid

استعد لأسئلة: ماذا يحدث لو migration تفشل؟ لماذا app على شبكتين؟ كيف تثبت backup؟ ماذا تفعل لو old image غير متوافق مع schema؟ تجنب قول “production deployed”، “zero downtime”، أو “backup succeeded” بدون evidence. اشرح trade-off بوضوح واذكر commands فعلية من المشروع.
