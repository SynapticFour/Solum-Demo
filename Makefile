# Makefile — Solum-Demo local lifecycle

.PHONY: help up up-sibling down reset up-h3 down-h3 \
	smoke-stage1 smoke-consent smoke-h3 smoke-profile \
	smoke-fhir-ips smoke-migration smoke-claims-proof smoke-all

help:
	@echo "Solum-Demo"
	@echo "  make up                 Stage-1 stack from pinned Solum-ref (PINNED_VERSIONS.txt)"
	@echo "  make up-sibling         Stage-1 stack built from ../Solum (dev alignment)"
	@echo "  make down / reset       Stop / wipe volumes"
	@echo "  make smoke-stage1       Authz deny + HELIOS envelope + audit tamper (needs up)"
	@echo "  make smoke-consent      Consent + Deny B decrypt-after-revoke (needs up)"
	@echo "  make up-h3 / smoke-h3   Track B EHRbase evidence (soft-skip)"
	@echo "  make smoke-profile      kenya/eu refuse + transfer unit (../Solum, soft-skip)"
	@echo "  make smoke-fhir-ips     solum fhir export-ips + structural (../Solum, soft-skip)"
	@echo "  make smoke-migration    Prefer/Cut-over dry rehearsal (../Solum, soft-skip)"
	@echo "  make smoke-claims-proof Solum ./scripts/demo-claims-proof.sh (../Solum, soft-skip)"
	@echo "  make smoke-all          stage1 + consent + soft sibling smokes"

# SOLUM_DEMO_PORT — host port for Stage-1 dashboard (default 8080).
# SOLUM_DEMO_BASE_URL — override for smoke scripts (default http://127.0.0.1:$$SOLUM_DEMO_PORT).

up:
	docker compose up --build -d

up-sibling:
	docker compose -f docker-compose.yml -f docker-compose.sibling.yml up --build -d

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

smoke-fhir-ips:
	@chmod +x scripts/smoke-fhir-ips.sh
	./scripts/smoke-fhir-ips.sh

smoke-migration:
	@chmod +x scripts/smoke-migration-rehearsal.sh
	./scripts/smoke-migration-rehearsal.sh

smoke-claims-proof:
	@chmod +x scripts/smoke-claims-proof.sh
	./scripts/smoke-claims-proof.sh

smoke-all: smoke-stage1 smoke-consent smoke-h3 smoke-profile smoke-fhir-ips smoke-migration
