/* Solum-Demo UI — local developer walkthrough only.
 * Sidecar token is injected by nginx; this file must not contain it.
 * Body capability[] is client-asserted (dev-local). Not RBAC. Not a customer evaluation.
 */
(function () {
  const ACTOR = "practitioner/amina";
  const GET_CAPS = "solum:audit:export,solum:audit:verify,solum:consent:read";
  const CONSENT_SUBJECT = "patient/demo-ui";
  const CONSENT_PURPOSE = "care_provision";
  const KEY_REF = "ephemeral/demo-patient-summary";

  const PATIENT_SUMMARY = {
    resourceType: "Patient",
    id: "demo-42",
    name: [{ family: "Wanjiku", given: ["Grace"] }],
    birthDate: "1987-04-12",
    note: "Synthetic demo data — not a real patient.",
  };
  const PLAIN_B64 = btoa(unescape(encodeURIComponent(JSON.stringify(PATIENT_SUMMARY))));

  document.getElementById("patient-summary").textContent =
    JSON.stringify(PATIENT_SUMMARY, null, 2);

  function setResult(el, text, kind) {
    el.textContent = text;
    el.classList.remove("ok", "deny", "warn");
    if (kind) el.classList.add(kind);
  }

  function identityHeaders(extra) {
    const h = {
      "X-Solum-Actor": ACTOR,
      "X-Solum-Capability": GET_CAPS,
      "Content-Type": "application/json",
    };
    return Object.assign(h, extra || {});
  }

  let lastEncryptedField = null;

  async function consentCall(method, path, body) {
    const opts = { method, headers: identityHeaders() };
    if (body !== undefined) opts.body = JSON.stringify(body);
    const res = await fetch(path, opts);
    const text = await res.text();
    let parsed = {};
    try {
      parsed = text ? JSON.parse(text) : {};
    } catch (_) {
      parsed = { raw: text };
    }
    return { status: res.status, body: parsed };
  }

  async function ensureConsentGranted() {
    return consentCall("POST", "/v1/consent/grant", {
      actor: ACTOR,
      capability: ["solum:consent:grant"],
      subject: CONSENT_SUBJECT,
      purpose: CONSENT_PURPOSE,
      scope: ["patient_summary"],
    });
  }

  async function encryptAs(actor, capabilities) {
    const res = await fetch("/v1/crypto/encrypt", {
      method: "POST",
      headers: identityHeaders(),
      body: JSON.stringify({
        category: "patient_summary",
        subject: CONSENT_SUBJECT,
        purpose: CONSENT_PURPOSE,
        key_ref: KEY_REF,
        actor,
        capability: capabilities,
        plaintext_base64: PLAIN_B64,
      }),
    });
    const body = await res.json().catch(() => ({}));
    return { status: res.status, body };
  }

  async function decryptAs(actor, capabilities, field) {
    const res = await fetch("/v1/crypto/decrypt", {
      method: "POST",
      headers: identityHeaders(),
      body: JSON.stringify({
        subject: CONSENT_SUBJECT,
        purpose: CONSENT_PURPOSE,
        key_ref: KEY_REF,
        actor,
        capability: capabilities,
        field,
      }),
    });
    const body = await res.json().catch(() => ({}));
    return { status: res.status, body };
  }

  async function onEncrypt(actor, caps, label) {
    const out = document.getElementById("s1-result");
    setResult(out, `Ensuring consent, then /v1/crypto/encrypt as ${label}…`);
    try {
      if (caps && caps.length) {
        await ensureConsentGranted();
      }
      const { status, body } = await encryptAs(actor, caps);
      if (status === 200) {
        if (body.field) lastEncryptedField = body.field;
        const fieldPreview = body.field
          ? JSON.stringify(body.field).slice(0, 180) + "…"
          : "(no field)";
        setResult(
          out,
          `HTTP ${status} OK — encryption succeeded for ${label}.\n` +
            `field (truncated): ${fieldPreview}\n` +
            (body.warning ? `\nwarning: ${body.warning}` : "") +
            `\n\nHonesty: success means the JSON body included solum:crypto:encrypt.`,
          "ok"
        );
      } else if (status === 403) {
        setResult(
          out,
          `HTTP ${status} FORBIDDEN — empty capability[] denied.\n` +
            `error: ${body.error || "?"}\n` +
            `message: ${body.message || JSON.stringify(body)}\n` +
            `This is fail-closed on missing scopes, not intern vs physician RBAC.`,
          "deny"
        );
      } else {
        setResult(out, `HTTP ${status}\n${JSON.stringify(body, null, 2)}`, "warn");
      }
      await refreshAudit();
    } catch (err) {
      setResult(out, `Request failed: ${err}`, "warn");
    }
  }

  document.getElementById("btn-amina").addEventListener("click", () =>
    onEncrypt(ACTOR, ["solum:crypto:encrypt"], "body capability[] = encrypt")
  );
  document.getElementById("btn-intern").addEventListener("click", () =>
    onEncrypt("intern/x", [], "body capability[] = []")
  );

  document.getElementById("btn-tamper").addEventListener("click", async () => {
    const out = document.getElementById("s2-result");
    setResult(out, "Demo harness rewriting audit.jsonl on disk…");
    try {
      const res = await fetch("/demo/simulate-tampering", { method: "POST" });
      const body = await res.json();
      setResult(
        out,
        `Harness HTTP ${res.status}\n${JSON.stringify(body, null, 2)}`,
        body.ok ? "warn" : "deny"
      );
      await refreshAudit();
    } catch (err) {
      setResult(out, `Tamper harness failed: ${err}`, "deny");
    }
  });

  document.getElementById("btn-verify").addEventListener("click", async () => {
    const out = document.getElementById("s2-result");
    setResult(out, "GET /v1/audit/verify …");
    try {
      const res = await fetch("/v1/audit/verify", { headers: identityHeaders() });
      const body = await res.json();
      if (res.status === 200 && body.status === "ok") {
        setResult(out, `HTTP ${res.status}\n${JSON.stringify(body, null, 2)}\nChain intact.`, "ok");
      } else {
        setResult(
          out,
          `HTTP ${res.status} — chain broken / verify failed\n` +
            `error: ${body.error || "?"}\n` +
            `message: ${body.message || JSON.stringify(body)}`,
          "deny"
        );
      }
    } catch (err) {
      setResult(out, `Verify failed: ${err}`, "warn");
    }
  });

  document.getElementById("btn-refresh").addEventListener("click", () => refreshAudit());

  document.getElementById("btn-consent-grant").addEventListener("click", async () => {
    const out = document.getElementById("s3-result");
    setResult(out, "POST /v1/consent/grant …");
    try {
      const { status, body } = await consentCall("POST", "/v1/consent/grant", {
        actor: ACTOR,
        capability: ["solum:consent:grant"],
        subject: CONSENT_SUBJECT,
        purpose: CONSENT_PURPOSE,
        scope: ["patient_summary"],
      });
      setResult(
        out,
        `HTTP ${status}\n${JSON.stringify(body, null, 2)}`,
        status === 200 || status === 201 ? "ok" : "deny"
      );
      await refreshAudit();
    } catch (err) {
      setResult(out, `Grant failed: ${err}`, "warn");
    }
  });

  document.getElementById("btn-consent-status").addEventListener("click", async () => {
    const out = document.getElementById("s3-result");
    const q = `subject=${encodeURIComponent(CONSENT_SUBJECT)}&purpose=${encodeURIComponent(CONSENT_PURPOSE)}`;
    setResult(out, `GET /v1/consent/status?${q} …`);
    try {
      const { status, body } = await consentCall("GET", `/v1/consent/status?${q}`);
      const st = (body && body.status) || "?";
      const kind = st === "granted" ? "ok" : st === "revoked" || st === "unknown" ? "warn" : "deny";
      setResult(out, `HTTP ${status}\n${JSON.stringify(body, null, 2)}`, kind);
    } catch (err) {
      setResult(out, `Status failed: ${err}`, "warn");
    }
  });

  document.getElementById("btn-consent-revoke").addEventListener("click", async () => {
    const out = document.getElementById("s3-result");
    setResult(out, "POST /v1/consent/revoke …");
    try {
      const { status, body } = await consentCall("POST", "/v1/consent/revoke", {
        actor: ACTOR,
        capability: ["solum:consent:revoke"],
        subject: CONSENT_SUBJECT,
        purpose: CONSENT_PURPOSE,
      });
      setResult(
        out,
        `HTTP ${status}\n${JSON.stringify(body, null, 2)}`,
        status === 200 || status === 201 ? "ok" : "deny"
      );
      await refreshAudit();
    } catch (err) {
      setResult(out, `Revoke failed: ${err}`, "warn");
    }
  });

  document.getElementById("btn-denyb-run").addEventListener("click", async () => {
    const out = document.getElementById("s4-result");
    setResult(out, "Deny B: grant → encrypt → revoke → decrypt…");
    try {
      await ensureConsentGranted();
      const enc = await encryptAs(ACTOR, ["solum:crypto:encrypt"]);
      if (enc.status !== 200 || !enc.body.field) {
        setResult(out, `Encrypt failed HTTP ${enc.status}\n${JSON.stringify(enc.body, null, 2)}`, "deny");
        await refreshAudit();
        return;
      }
      lastEncryptedField = enc.body.field;
      const rev = await consentCall("POST", "/v1/consent/revoke", {
        actor: ACTOR,
        capability: ["solum:consent:revoke"],
        subject: CONSENT_SUBJECT,
        purpose: CONSENT_PURPOSE,
      });
      if (!(rev.status === 200 || rev.status === 201)) {
        setResult(out, `Revoke failed HTTP ${rev.status}\n${JSON.stringify(rev.body, null, 2)}`, "deny");
        await refreshAudit();
        return;
      }
      const dec = await decryptAs(ACTOR, ["solum:crypto:decrypt"], lastEncryptedField);
      if (dec.status === 200) {
        setResult(out, `FAIL: decrypt succeeded after revoke (HTTP 200)`, "deny");
      } else {
        setResult(
          out,
          `Deny B OK — decrypt refused after revoke (HTTP ${dec.status}).\n` +
            `message: ${dec.body.message || JSON.stringify(dec.body)}\n` +
            `Watch the live audit log for consent.denied.`,
          "ok"
        );
      }
      await refreshAudit();
    } catch (err) {
      setResult(out, `Deny B failed: ${err}`, "warn");
    }
  });

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function renderAudit(envelope) {
    const box = document.getElementById("audit-log");
    const records = (envelope && envelope.records) || [];
    document.getElementById("audit-count").textContent =
      `${records.length} record${records.length === 1 ? "" : "s"}`;
    if (!records.length) {
      box.innerHTML = '<div class="audit-empty">No events yet — run Scenario 1.</div>';
      return;
    }
    const ordered = [...records].reverse();
    box.innerHTML = ordered
      .map((rec) => {
        const ev = rec.event || {};
        const denied =
          ev.event_type === "access.denied" ||
          ev.event_type === "authorization.denied" ||
          ev.event_type === "consent.denied" ||
          ev.outcome === "denied" ||
          ev.outcome === "failure" ||
          ev.outcome === "Failure";
        return (
          `<div class="audit-entry${denied ? " denied" : ""}">` +
          `<div><span class="etype">${escapeHtml(ev.event_type || "?")}</span>` +
          ` · seq ${rec.seq} · ${escapeHtml(ev.outcome || "")}</div>` +
          `<div>actor: ${escapeHtml(ev.actor || "")}</div>` +
          `<div>${escapeHtml(ev.timestamp || "")}` +
          (ev.data_category ? ` · ${escapeHtml(ev.data_category)}` : "") +
          `</div>` +
          `</div>`
        );
      })
      .join("");
  }

  async function refreshAudit() {
    const dot = document.getElementById("live-dot");
    try {
      const res = await fetch("/v1/audit/export", { headers: identityHeaders() });
      if (!res.ok) {
        const t = await res.text();
        throw new Error(`HTTP ${res.status}: ${t.slice(0, 200)}`);
      }
      const envelope = await res.json();
      renderAudit(envelope);
      dot.classList.add("live");
    } catch (err) {
      dot.classList.remove("live");
      document.getElementById("audit-log").innerHTML =
        `<div class="audit-empty">Audit poll error: ${escapeHtml(err)}</div>`;
    }
  }

  refreshAudit();
  setInterval(refreshAudit, 2000);
})();
