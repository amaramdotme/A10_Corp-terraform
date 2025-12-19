# A10 Corp Terraform User Manual

Last updated: 2025-12-19

This guide explains how to operate, extend, and safely use this repository to manage A10 Corp’s Azure infrastructure with Terraform.

- Source repo: `terraform_iac/`
- Architecture overview: `ARCHITECTURE.md:1`
- Decisions log: `DECISIONS.md:1`
- OIDC setup: `OIDC_SETUP.md:1`

---

## Audience & Scope

- Cloud engineers and platform teams deploying foundation and workload resources.
- Developers contributing Terraform modules and pipelines.
- Reviewers approving deployments via GitHub Environments.

---

## Quick Start (TL;DR)

1) Authenticate to Azure locally:
   - `az login`
   - `cp .env.example .env && edit .env` then `source .env`
2) Deploy Foundation (global, run once):
   - `cd foundation && terraform init -backend-config="environments/backend.hcl"`
   - `terraform plan -out=foundation.tfplan && terraform apply foundation.tfplan`
3) Deploy Workloads (per environment):
   - `cd ../workloads && terraform init -backend-config="environments/backend-dev.hcl"`
   - `terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan`
   - `terraform apply dev.tfplan`
4) Prefer CI/CD for changes:
   - Open PR → GitHub Actions generates plans → Approve environment → Apply runs.

Details below.

---

## 1) Foundations & Workloads Duality

The repo separates “permanent” organizational structure from “replaceable” environment resources.

- Common library (naming, variables, Key Vault data)
  - `modules/common/README.md:1`
  - Exposes `naming_patterns`, subscription IDs, and shared variables.

- Foundation (one-time, global)
  - Root: `foundation/main.tf:1`
  - Module: `modules/foundation/main.tf:1`
  - Creates management groups and associates subscriptions.
  - Single state container: `foundation/environments/backend.hcl:1`
  - Never destroy during normal operations.

- Workloads (per-environment, safe to destroy/recreate)
  - Root: `workloads/main.tf:1`
  - Module: `modules/workloads/main.tf:1`
  - Creates environment-specific resource groups in the right subscriptions using aliased providers (hq/sales/service).
  - Per-env state containers: `workloads/environments/backend-*.hcl`

Why this split?
- Safety: You can destroy/recreate workloads without risking the management-group hierarchy.
- Independence: Separate state files and pipelines reduce blast radius and speed up iterations.

---

## 2) Operating Model

Branching & CI/CD
- Main flows:
  - PR to `main` → plan jobs only; comments plan summaries on PR.
  - Push to `main` → plan, then apply (with environment approval gates where configured).
- Workflows:
  - Foundation: `.github/workflows/foundation-deploy.yml:1`
  - Workloads: `.github/workflows/workloads-deploy.yml:1`
  - Workloads destroy: `.github/workflows/workloads-destroy.yml:1`
  - OIDC test: `.github/workflows/test-oidc.yml:1`

Environments
- GitHub Environments: `global`, `dev`, `stage`, `prod` (workloads).
- Foundation always targets `global`. Workloads target the chosen environment.

Approvals & Protections
- Use required reviewers on `global` and `workloads-prod` for applies.
- Workloads pipeline checks foundation state before proceeding.

State & Backends
- Azure Storage account: `storerootblob`.
- Containers: `foundation`, `workloads-dev`, `workloads-stage`, `workloads-prod`.
- Backends defined in `foundation/backend.tf:1` and `workloads/backend.tf:1` with per-env overrides in `environments/`.

Authentication
- GitHub uses OIDC (no long-lived secrets). See `OIDC_SETUP.md:1`.
- Local uses Azure CLI + `.env` (ARM_SUBSCRIPTION_ID and ARM_TENANT_ID).

Roles & Responsibilities
- Infra engineers: author modules, review plans, operate pipelines.
- Security/governance: review MG layout, RBAC, policy posture.
- App teams: request new workloads or RGs via PRs.

---

## 3) Governance

Management Groups
- Created by Foundation: HQ (root), Sales, Service.
- Associations ensure subscriptions land under the right MGs for policy scope.

RBAC (minimum set for CI/CD principal)
- Contributor on root/hq/sales/service subscriptions.
- Management Group Contributor at tenant root (foundation applies).
- User Access Administrator on workload subscriptions (for association changes).
- Key Vault Secrets User on `kv-root-terraform`.
- Storage Blob Data Contributor on `storerootblob`.

Naming Standards (CAF)
- Implemented centrally: `modules/common/naming.tf:1` (three-branch logic for hyphen/no-hyphen and env suffixes).
- All modules consume `module.common.naming_patterns`.

Secrets & Sensitive Data
- Subscription IDs are fetched at runtime from Key Vault: `modules/common/data-sources.tf:1`.
- No secrets in repo. `.env` only carries subscription/tenant IDs for local runs and is gitignored (`.gitignore:1`).

State Safety
- Remote state, per-scope containers, locking enabled by Azure Storage.
- Destroy workflows: workloads have dedicated destroy; foundation has a guarded destroy workflow with prechecks.

Policies (future)
- Add Azure Policy assignments in a new `modules/policies/` and apply at MG scope.

---

## 4) Enablement

New Contributor Onboarding
1) Request access (AAD, Key Vault, Storage, needed subs).
2) Install tooling: Terraform (>=1.0), Azure CLI, Git.
3) Clone repo and set `.env` from `.env.example`.
4) Verify auth: `az account show`, then run `test-oidc.yml` in GitHub to validate CI path.

How to Propose Changes
- Small changes: open PR; CI will format-check and plan.
- Module refactors: add/update module docs under `modules/*/README.md` and reference in `ARCHITECTURE.md:1`.
- Governance changes: propose via ADR entry in `DECISIONS.md:1`.

Where to Look
- Root callers: `foundation/*`, `workloads/*`.
- Reusable logic: `modules/common/*`.
- Pipelines: `.github/workflows/*`.
- How-to docs: `ARCHITECTURE.md:1`, `OIDC_SETUP.md:1`, `NEXTSTEPS.md:1`.

---

## 5) How To Scale From Here

Add a new workload resource
1) Extend naming if needed: `modules/common/naming.tf:1` (add type + include_env rule).
2) Add resources to `modules/workloads/main.tf:1` using `var.naming_patterns`.
3) Use the right aliased provider (`azurerm.hq|sales|service`) for placement.
4) Expose outputs as needed; plan in dev first.

Add a new environment
1) Create `workloads/environments/<env>.tfvars` with `environment = "<env>"`.
2) Add `workloads/environments/backend-<env>.hcl` container pointing to `workloads-<env>`.
3) Add GitHub Environment `workloads-<env>` and corresponding OIDC federated credential.
4) Extend workflow choice lists if required.

Introduce policy/monitoring layers
- Create `modules/policies/` and/or `modules/monitoring/`.
- Call from new root folders (e.g., `policy/`, `monitoring/`) with their own backends.

Multi-region
- Add `location` lists and per-region modules; encode into naming as needed.

Quality Gates
- Add tflint, checkov, pre-commit hooks; integrate as separate jobs before plan.

---

## 6) How To Run This Locally

Prerequisites
- Azure CLI authenticated: `az login`
- `.env` prepared and sourced: `source .env`
- Remote state containers exist in `storerootblob`.

Foundation (global)
```bash
cd foundation
source ../.env
terraform init -backend-config="environments/backend.hcl"
terraform fmt -recursive && terraform validate
terraform plan -out=foundation.tfplan
terraform apply foundation.tfplan
```

Workloads (example: dev)
```bash
cd workloads
source ../.env
terraform init -backend-config="environments/backend-dev.hcl"
terraform fmt -recursive && terraform validate
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan
terraform apply dev.tfplan
```

Destroy workloads (safe)
```bash
cd workloads
source ../.env
terraform destroy -var-file="environments/dev.tfvars"
```

Never casually destroy foundation
- Use the guarded workflow only: `.github/workflows/foundation-destroy.yml:1`.

Helper script
- `./init-plan-apply.sh:1` supports `--foundation` or `--workloads --env <env>` with `init|plan|apply|destroy`.

Common pitfalls
- “subscription ID could not be determined”: ensure `source .env` before terraform commands.
- Key Vault auth errors: verify Key Vault RBAC and that default provider points to sub-root (see `foundation/providers.tf:1`, `workloads/providers.tf:1`).
- Provider registration timeouts: auto-registration disabled by design (`resource_provider_registrations = "none"`). Manually register missing RPs if needed.

---

## CI/CD Workflows (How They Work)

Foundation
- Plans on PR/push, applies on push to `main` with `global` environment approval.
- Uploads human-readable plans to Azure Storage for audit.

Workloads
- Determines env: PRs default to `dev`, `workflow_dispatch` selects `dev|stage|prod`.
- Checks that foundation is healthy and no concurrent foundation deploys.
- Plans → uploads plan to Azure Storage → optional PR comment preview → applies on push to `main` or manual dispatch with approvals.

Destroy flows
- Separate workflows for workloads and foundation with confirmation prompts and prechecks.

---

## Troubleshooting

- Authentication failures in CI: verify GitHub `permissions: id-token: write`, environment variables, and OIDC federated credentials. See `OIDC_SETUP.md:1`.
- Key Vault access denied: check `Key Vault Secrets User` on `kv-root-terraform` and that the default provider targets sub-root.
- Missing state containers: create `foundation`, `workloads-dev`, `workloads-stage`, `workloads-prod` in `storerootblob`.
- Foundation already exists: import resources before first apply (see examples in `ARCHITECTURE.md:240`).

---

## Glossary

- Foundation: Management Groups and subscription associations (global, permanent).
- Workloads: Environment-specific Resource Groups (per-subscription, replaceable).
- Common: Shared naming, variables, and data sources reused by all modules.
- OIDC: OpenID Connect for GitHub Actions to authenticate to Azure without secrets.

---

## Appendix: Key File Map

- Root callers
  - `foundation/main.tf:1`, `workloads/main.tf:1`
- Modules
  - `modules/common/*`, `modules/foundation/*`, `modules/workloads/*`
- Providers & backends
  - `foundation/providers.tf:1`, `workloads/providers.tf:1`
  - `foundation/backend.tf:1`, `workloads/backend.tf:1`
- Backends (env)
  - `foundation/environments/backend.hcl:1`
  - `workloads/environments/backend-dev.hcl:1`, `workloads/environments/backend-stage.hcl:1`, `workloads/environments/backend-prod.hcl:1`
- CI/CD
  - `.github/workflows/foundation-deploy.yml:1`
  - `.github/workflows/workloads-deploy.yml:1`
  - `.github/workflows/workloads-destroy.yml:1`
  - `.github/workflows/test-oidc.yml:1`

