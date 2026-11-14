# Security

Solum-Demo welcomes reports of security issues in this repository.

## Report

Write to [contact@synapticfour.com](mailto:contact@synapticfour.com). Include the repository name, the commit, and enough detail to reproduce the issue.

Do not open a public issue for an unfixed vulnerability. Do not include credentials, personal data, or patient data in the report.

## Scope

In scope: the Compose files, the nginx template, the dashboard, and the demo harness. The published ports bind `127.0.0.1`. The sidecar token is injected by nginx and is not in the dashboard source.

Out of scope: a defect in Solum itself belongs in [Solum](https://github.com/SynapticFour/Solum). Use that repository's [SECURITY.md](https://github.com/SynapticFour/Solum/blob/main/SECURITY.md).

The `dev-local` profile, ephemeral keys, and plaintext HTTP inside the Compose network are the walkthrough posture. They are not a hospital deployment. Do not put patient data in this stack.

## Response

Reports go to the contact address the website publishes. This page does not promise a time.

A fix, when one is made, is a commit on this repository.
