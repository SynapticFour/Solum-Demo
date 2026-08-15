# DEMO HARNESS — Solum-Demo only.
# This image is NOT Solum and must never be copied into the Solum product repo.
# uid 10001 matches the sidecar so rewriting audit.jsonl does not steal ownership.

FROM python:3.14-slim-bookworm

WORKDIR /app
COPY server.py /app/server.py

RUN useradd --system --uid 10001 --home /nonexistent --shell /usr/sbin/nologin solum \
    && mkdir -p /data \
    && chown solum:solum /data /app

ENV AUDIT_PATH=/data/audit.jsonl \
    HARNESS_BIND=0.0.0.0:8790

USER solum
EXPOSE 8790
CMD ["python", "-u", "/app/server.py"]
