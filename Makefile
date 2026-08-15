# Makefile — Solum-Demo local lifecycle

.PHONY: help up up-sibling down reset up-h3 down-h3 check \
	smoke-stage1 smoke-consent smoke-h3 smoke-profile \
	smoke-fhir-ips smoke-migration smoke-claims-proof smoke-all smoke-ci

SOLUM_REF := $(shell sed -n 's/^Solum-ref=//p' PINNED_VERSIONS.txt)

help:
	@echo "Solum-Demo  (Solum-ref=$(SOLUM_REF))"
	@echo "  make up                 Stage-1 stack from PINNED_VERSIONS.txt Solum-ref"
	@echo "  make up-sibling         Stage-1 stack built from ../Solum (dev alignment)"
	@echo "  make down / reset       Stop / wipe volumes"
	@echo "  make smoke-stage1       Authz deny + HELIOS envelope + audit tamper (needs up)"
	@echo "  make smoke-consent      Consent + Deny B decrypt-after-revoke (needs up)"
	@echo "  make up-h3 / smoke-h3   Track B EHRbase evidence (REQUIRE=1 fails if down)"
	@echo "  make smoke-profile      kenya/eu refuse + transfer unit (../Solum)"
	@echo "  make smoke-fhir-ips     solum fhir export-ips + structural (../Solum)"
	@echo "  make smoke-migration    Prefer/Cut-over dry rehearsal (../Solum)"
	@echo "  make smoke-claims-proof Solum ./scripts/demo-claims-proof.sh (../Solum)"
	@echo "  make smoke-ci           consent + stage1 (tamper last; what GitHub Actions runs)"
	@echo "  make smoke-all          all smokes; sibling/H3 skips are failures"
	@echo "  make check              pin drift, LICENSE, bash -n, harness unit tests"

# SOLUM_DEMO_PORT — host port for Stage-1 dashboard (default 8080, loopback).
# SOLUM_DEMO_BASE_URL — override for smoke scripts (default http://127.0.0.1:$$SOLUM_DEMO_PORT).

up:
	@test -n "$(SOLUM_REF)" || (echo "PINNED_VERSIONS.txt missing Solum-ref"; exit 1)
	SOLUM_REF="$(SOLUM_REF)" docker compose up --build -d || { docker compose logs sidecar --tail=80; exit 1; }

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

check:
	@pin=$$(sed -n 's/^Solum-ref=//p' PINNED_VERSIONS.txt); \
	  test -n "$$pin"; \
	  grep -F "$$pin" Dockerfile >/dev/null; \
	  grep -F "$$pin" docker-compose.yml >/dev/null; \
	  test -f LICENSE; test -f NOTICE
	bash -n scripts/lib-smoke.sh
	bash -n scripts/smoke-stage1.sh
	bash -n scripts/smoke-consent.sh
	bash -n scripts/smoke-h3.sh
	bash -n scripts/smoke-profile-refuse.sh
	bash -n scripts/smoke-fhir-ips.sh
	bash -n scripts/smoke-migration-rehearsal.sh
	bash -n scripts/smoke-claims-proof.sh
	python3 -m unittest discover -s demo-harness -p 'test_*.py' -v

smoke-stage1:
	SOLUM_DEMO_BASE_URL="$${SOLUM_DEMO_BASE_URL:-http://127.0.0.1:$${SOLUM_DEMO_PORT:-8080}}" ./scripts/smoke-stage1.sh

smoke-consent:
	SOLUM_DEMO_BASE_URL="$${SOLUM_DEMO_BASE_URL:-http://127.0.0.1:$${SOLUM_DEMO_PORT:-8080}}" ./scripts/smoke-consent.sh

smoke-h3:
	./scripts/smoke-h3.sh

smoke-profile:
	./scripts/smoke-profile-refuse.sh

smoke-fhir-ips:
	./scripts/smoke-fhir-ips.sh

smoke-migration:
	./scripts/smoke-migration-rehearsal.sh

smoke-claims-proof:
	./scripts/smoke-claims-proof.sh

smoke-ci: smoke-consent smoke-stage1

# Full proof set: missing sibling / H3 is a failure, not a skip.
smoke-all:
	SOLUM_DEMO_H3_REQUIRE=1 SOLUM_DEMO_PROFILE_REQUIRE=1 SOLUM_DEMO_FHIR_REQUIRE=1 \
	SOLUM_DEMO_MIGRATION_REQUIRE=1 SOLUM_DEMO_CLAIMS_REQUIRE=1 \
	$(MAKE) smoke-consent smoke-stage1 smoke-h3 smoke-profile smoke-fhir-ips smoke-migration smoke-claims-proof
