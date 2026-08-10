# Makefile — Solum-Demo local lifecycle

.PHONY: help up down reset up-h3 down-h3 smoke-stage1 smoke-consent smoke-h3 smoke-profile smoke-all

help:
	@echo "Solum-Demo"
	@echo "  make up              Stage-1 interactive stack (SOLUM_DEMO_PORT, default 8080)"
	@echo "  make down / reset    Stop / wipe volumes"
	@echo "  make smoke-stage1    Authz + audit tamper (requires up)"
	@echo "  make smoke-consent   Consent grant/revoke (requires up)"
	@echo "  make up-h3           EHRbase + Track B sidecar (:8787; needs ../Solum)"
	@echo "  make smoke-h3        CDR/FHIR/AQL/dual-write/subject-link (soft-skip)"
	@echo "  make smoke-profile   kenya-dpa/eu-ehds refuse via ../Solum (soft-skip)"
	@echo "  make smoke-all       stage1 + consent (+ soft h3/profile)"

# SOLUM_DEMO_PORT — host port for Stage-1 dashboard (default 8080).
# SOLUM_DEMO_BASE_URL — override for smoke scripts (default http://127.0.0.1:$$SOLUM_DEMO_PORT).

up:
	docker compose up --build -d

down:
	docker compose down

reset:
	docker compose down -v

up-h3:
	docker compose -f docker-compose.ehrbase.yml -f docker-compose.ehrbase-sidecar.yml \
		--profile h3-sidecar up --build -d

down-h3:
	docker compose -f docker-compose.ehrbase.yml -f docker-compose.ehrbase-sidecar.yml \
		--profile h3-sidecar down -v

smoke-stage1:
	@chmod +x scripts/smoke-stage1.sh
	SOLUM_DEMO_BASE_URL="$${SOLUM_DEMO_BASE_URL:-http://127.0.0.1:$${SOLUM_DEMO_PORT:-8080}}" ./scripts/smoke-stage1.sh

smoke-consent:
	@chmod +x scripts/smoke-consent.sh
	SOLUM_DEMO_BASE_URL="$${SOLUM_DEMO_BASE_URL:-http://127.0.0.1:$${SOLUM_DEMO_PORT:-8080}}" ./scripts/smoke-consent.sh

smoke-h3:
	@chmod +x scripts/smoke-h3.sh
	./scripts/smoke-h3.sh

smoke-profile:
	@chmod +x scripts/smoke-profile-refuse.sh
	./scripts/smoke-profile-refuse.sh

smoke-all: smoke-stage1 smoke-consent smoke-h3 smoke-profile
