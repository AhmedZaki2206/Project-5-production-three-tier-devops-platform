# Step-by-Step Guide — من Windows 11 إلى Platform شغالة

## 1. تجهيز الجهاز

**WHY:** WSL2 يوفر Linux shell، وDocker Desktop يشغل Linux containers، وGit يدير التاريخ.

افتح PowerShell كـAdministrator:

```powershell
wsl --install -d Ubuntu
wsl --update
```

ثبت Docker Desktop وGit وVS Code، ثم فعّل `Use WSL 2 based engine` وUbuntu integration. داخل Ubuntu:

```bash
git --version
docker version
docker compose version
python3 --version
```

**Expected:** client وserver ظاهرين. لو ظهر `Cannot connect to Docker daemon` افتح Docker Desktop وانتظر Engine؛ لا تغيّر Docker socket permissions عشوائيًا.

## 2. تنزيل المشروع وإعداد البيئة

### تثبيت الأدوات على Windows 11

من PowerShell كـAdministrator ثبّت الأدوات الأساسية بـ`winget`:

```powershell
winget install --id Git.Git -e
winget install --id Microsoft.VisualStudioCode -e
winget install --id Docker.DockerDesktop -e
wsl --install -d Ubuntu
```

اعمل restart، افتح Docker Desktop، ومن `Settings > Resources > WSL Integration` فعّل Ubuntu. جوه WSL ثبّت أدوات Linux المطلوبة:

```bash
sudo apt update
sudo apt install -y git python3 python3-venv curl make shellcheck
git --version
python3 --version
docker version
docker compose version
```

**Expected:** كل command يطبع version، و`docker version` يعرض `Client` و`Server`. لو الـClient ظاهر والـServer مش ظاهر، Docker Engine لسه مش جاهز أو WSL integration مش مفعلة. `Kind` و`kubectl` و`Helm` مش مطلوبين للمشروع ده؛ عدم تثبيتهم قرار مقصود لأن المشروع Docker Compose وAnsible فقط.

```bash
git clone https://github.com/AhmedZaki2206/Project-5-production-three-tier-devops-platform.git
cd Project-5-production-three-tier-devops-platform
cp .env.example .env
code .
```

غيّر `POSTGRES_PASSWORD` في `.env`. الملف ignored. تحقق بـ`git status --ignored` إنه مش staged.

## 3. فهم الملفات

- `app/`: API, model, schema, database session وhealth checks.
- `migrations/`: schema versions التي ينفذها Alembic.
- `docker-compose.yml`: tiers, networks, volumes, limits وstartup order.
- `nginx/nginx.conf`: upstream `app:8000` وproxy headers.
- `scripts/`: health, backup, restore, deploy, rollback وsmoke.
- `ansible/`: إعداد disposable Ubuntu VM وتشغيل Compose.
- `.github/workflows/`: PR validation وGHCR publication.
- `faults/` و`lab.sh`: faults محلية قابلة للreset.

## 4. Python tests من غير PostgreSQL خارجي

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
ruff check .
pytest
```

الاختبارات تستخدم SQLite in-memory مع dependency override، لذلك سريعة ومعزولة. Compose smoke test لاحقًا يغطي PostgreSQL الحقيقي. `422` يعني input validation، `404` missing asset، و`409` duplicate hostname.

## 5. Build وstartup

```bash
docker compose config --quiet
docker compose build
docker compose up -d --wait
docker compose ps
./scripts/health-check.sh
```

**HOW:** db يبدأ، healthcheck ينجح، migrate ينفذ schema، app readiness يختبر `SELECT 1`، ثم Nginx يبدأ. **Expected:** db/app healthy، migrate exited 0، proxy running و`127.0.0.1:8080` فقط.

لو migrate فشل:

```bash
docker compose logs migrate db
docker compose run --rm migrate alembic current
```

## 6. API demonstration

```bash
curl -s http://127.0.0.1:8080/health/live
curl -s http://127.0.0.1:8080/health/ready
curl -s -X POST http://127.0.0.1:8080/api/assets \
  -H 'Content-Type: application/json' \
  -d '{"hostname":"db-01.local","ip_address":"10.20.12.10","environment":"prod","description":"PostgreSQL node"}'
curl -s http://127.0.0.1:8080/api/assets
```

افحص logs: `docker compose logs --tail=50 proxy app db`. اختبر Nginx قبل reload: `docker compose exec proxy nginx -t`.

## 7. Persistence, backup and restore exercise

أنشئ ثلاثة records، ثم:

```bash
./scripts/db-verify.sh
./scripts/db-backup.sh
curl -X DELETE http://127.0.0.1:8080/api/assets/1
./scripts/db-restore.sh backups/portal-TIMESTAMP.sql.gz
curl http://127.0.0.1:8080/api/assets
```

**VERIFICATION:** العدد والـhostnames قبل الحذف يرجعوا بعد restore. `gzip -t` يثبت سلامة الضغط فقط؛ `db-verify.sh` يثبت schema access. احتفظ بالـtimestamps في incident report.

## 8. Deploy وrollback

```bash
./scripts/deploy.sh three-tier-portal:local
./scripts/deploy.sh ghcr.io/ahmedzaki2206/three-tier-portal:FULL_SHA
./scripts/rollback.sh
```

لو image tag غير موجود، deploy يتوقف قبل تغيير current state. بعد update، readiness gate لازم تنجح. Database rollback منفصل ويحتاج migration review.

## 9. Ansible داخل VM فقط

جهز Ubuntu VM private/NAT، SSH key تجريبي، وعدّل inventory. خزّن password:

```bash
cd ansible
ansible-vault create group_vars/all/vault.yml
# vault_portal_db_password: a-strong-lab-password
ansible-galaxy collection install -r requirements.yml
ansible all -m ping
ansible-playbook site.yml --syntax-check
ansible-playbook site.yml --ask-vault-pass
ansible-playbook site.yml --ask-vault-pass
```

في run الثانية تتوقع `changed=0` إذا لا يوجد تغيير. لا تستخدم inventory على workstation أو server حقيقي.

### كل Ansible task بتعمل إيه؟

| Task | الهدف وطريقة العمل | التحقق والمشاكل الشائعة |
|---|---|---|
| `Install Docker Engine...` | تستخدم `ansible.builtin.apt` لتثبيت `docker.io` و`docker-compose-v2` من Ubuntu repositories. | لو package غير موجود اعمل `apt-cache policy docker-compose-v2` وتأكد إن نسخة Ubuntu مدعومة. |
| `Enable and start Docker` | تستخدم `service` عشان Docker يبدأ الآن ومع boot. | `systemctl status docker`; فشلها غالبًا VM مش بتستخدم systemd. |
| `Create application directory` | تنشئ `/opt/three-tier-platform` بصلاحيات `0750` وملكية `root`. | `sudo stat /opt/three-tier-platform`. |
| `Copy project files...` | تنقل source الحالي للـVM؛ أي تغيير يرسل notification للـhandler. | راجع `project_source` وdisk space لو ظهرت `file not found`. |
| `Render local environment file` | تعمل `.env` من `env.j2` وتدخل password من Ansible Vault؛ `no_log` يمنع ظهوره في logs. | `sudo stat .env` لازم mode يكون `0600`. لا تستخدم `cat` في screenshot. |
| `Apply configuration-change handlers...` | ينفذ rebuild المطلوب بعد تغيير source أو `.env` وقبل health verification. | يمنع إن الـplaybook يعلن health ثم يعمل restart متأخر في نهاية الـplay. |
| `Start application stack` | `community.docker.docker_compose_v2` يضمن إن الـdesired Compose state شغالة؛ `build: policy` يتجنب rebuild بلا سبب. | `sudo docker compose ps` و`logs migrate`. ثبّت collection لو module غير معروف. |
| `Verify local application readiness` | `uri` يجرب `/health/ready` لحد 15 مرة؛ النجاح يثبت إن Nginx وFastAPI وPostgreSQL متصلين. | لو انتهت retries افحص `docker compose logs proxy app db`. |
| `Rebuild application stack` handler | يعمل build/start فقط لما copy أو template يتغير، بدل rebuild في كل run. | في run من غير تغييرات المفروض handler ما يشتغلش. |

`--syntax-check` يراجع تركيب playbook فقط ولا يتصل بالـVM. أول run فعلي لازم يغير النظام؛ في ثاني run راجع `changed=0` قدر الإمكان. بعض Docker build metadata قد تسبب change حسب نسخة Compose، ودي limitation لازم تذكرها بدل ادعاء idempotency كامل.

## 10. Troubleshooting وcleanup

```bash
./lab.sh list
./lab.sh start 01
docker compose logs proxy
./lab.sh hint 01
./lab.sh reset 01
docker compose down --remove-orphans
```

لحذف البيانات عمدًا فقط: `docker volume rm three-tier-postgres-data`. قبلها خذ backup واكتب اسم volume كامل. الصور والـvolumes الأخرى على الجهاز لا يلمسها المشروع.
