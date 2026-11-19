# Test Results

Executed locally on 18 November 2026 using Windows 11, Docker Desktop Linux Engine, Git Bash, and Python 3.12 containers. These results describe this local run, not a GitHub Actions run.

| Validation | Status | Evidence / limitation |
|---|---|---|
| Repository inspection | PASSED | Existing repository had one initial commit and README; work is on the feature branch. |
| Python lint | PASSED | `ruff check .`: all checks passed. |
| Python tests | PASSED | `pytest -q`: 7 passed; one upstream deprecation warning. Tests use isolated in-memory SQLite. |
| Docker Compose config | PASSED | `docker compose config --quiet` exited 0. |
| Docker image build | PASSED | `docker compose up -d --build --wait` built `three-tier-portal:local`. |
| Three-tier health and API smoke | PASSED | DB and app healthy, migration exited 0, proxy healthy; `scripts/smoke-test.sh` passed via `127.0.0.1:8080`. |
| Nginx configuration | PASSED | `docker compose exec -T proxy nginx -t` successful. |
| PostgreSQL persistence | PASSED | Two records remained after DB and app restart. |
| Backup and restore | PASSED | Backed up three records, deleted one, restored, and verified API and database counts returned to three. |
| Bash syntax | PASSED | Git Bash `bash -n scripts/*.sh lab.sh` exited 0. |
| ShellCheck | PASSED | Containerized ShellCheck exited 0. |
| Ansible syntax | PASSED | `ansible-playbook site.yml --syntax-check` with ansible-core 2.21.6 and community.docker 4.8.9. No VM was contacted. |
| Ansible lint | PASSED | ansible-lint 26.11.0: 0 failures, 0 warnings. |
| Trivy image scan | PASSED | Trivy 0.67.2, HIGH/CRITICAL, `--ignore-unfixed`: 0 findings after remediation. Initial scan found four fixed HIGH findings in zlib and Starlette. |
| Disposable Ubuntu VM deployment and idempotency | NOT RUN | No disposable VM was supplied. |
| GitHub Actions jobs | PASSED | PR #1 run `44498151281` on commit `37a2511`: `validate` and `ansible` both succeeded. Initial run failed at job setup because Trivy Action tag lacked the `v` prefix; fixed in commit `37a2511`. |
| GHCR publication | NOT RUN | Runs only after a future approved merge to `main`. |

Trivy is a vulnerability database snapshot; findings may change. No cloud deployment is part of this project.
