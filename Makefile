.PHONY: install lint test build up down logs health backup verify deploy clean
install:
	python -m pip install -r requirements-dev.txt
lint:
	ruff check .
test:
	pytest
build:
	docker compose build
up:
	docker compose up -d
down:
	docker compose down --remove-orphans
logs:
	docker compose logs --tail=100
health:
	./scripts/health-check.sh
backup:
	./scripts/db-backup.sh
verify:
	./scripts/db-verify.sh
deploy:
	./scripts/deploy.sh
clean:
	docker compose down --remove-orphans
