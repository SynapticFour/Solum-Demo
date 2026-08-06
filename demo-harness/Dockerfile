# DEMO HARNESS — Solum-Demo only.
# This image is NOT Solum and must never be copied into the Solum product repo.
# It exists solely so Scenario 2 can mutate audit.jsonl on the shared volume
# without giving the sidecar a tamper HTTP endpoint (that would be a security
# anti-feature in the real product).

FROM python:3.12-slim

WORKDIR /app
COPY server.py /app/server.py

ENV AUDIT_PATH=/data/audit.jsonl \
    HARNESS_BIND=0.0.0.0:8790

EXPOSE 8790
CMD ["python", "-u", "/app/server.py"]
