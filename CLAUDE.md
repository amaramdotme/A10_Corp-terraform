# CLAUDE.md - AI Assistant Context

This file provides guidance to Claude Code (claude.ai/code) when working in this repository.

---

## 📚 Documentation Structure

**This repository has 4 core documentation files. Each has a single, specific purpose:**

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Infrastructure overview, current state, Terraform commands, troubleshooting
2. **[DECISIONS.md](DECISIONS.md)** - Architectural Decision Records (ADRs) with rationale for design choices
3. **[NEXTSTEPS.md](NEXTSTEPS.md)** - Top priorities, short-term tasks, parking lot items
4. **[CLAUDE.md](CLAUDE.md)** - This file (AI assistant context only)

**Rule**: Each fact exists in exactly ONE file. Link to other files instead of duplicating.

---

## 🎯 Quick Start for AI Assistants

### Repository Basics
- **Location**: `/home/wsladmin/dev/cloud_computing/amaram_git_realm/projects/terraform_iac`
- **Repository**: `github.com:amaramdotme/A10_Corp-terraform.git` (private)
- **Terraform Binary**: `~/bin/terraform`
- **Always run from**: Repository root directory

### Before Running Any Terraform Command
```bash
source .env  # REQUIRED - Sets ARM_SUBSCRIPTION_ID and ARM_TENANT_ID
```

### Directory Structure
- **foundation/** - Management Groups module (GLOBAL - no environments)
- **workloads/** - Resource Groups module (PER-ENVIRONMENT - dev/stage/prod)
- **modules/** - Shared code (common, foundation, workloads)

---

## 🔍 Current Infrastructure State

**Last Updated**: 2025-12-17

### Deployed ✅
- **Foundation Module**: 3 Management Groups + 3 Subscription Associations
  - State: `storerootblob/foundation/terraform.tfstate`
  - MG IDs documented in [ARCHITECTURE.md](ARCHITECTURE.md#management-group-ids)

### Pending ⏳
- **Workloads Module**: 0/9 Resource Groups
  - Ready to deploy (see [NEXTSTEPS.md - Priority 1](NEXTSTEPS.md#1-deploy-workloads-module-dev-environment))

### Pre-Terraform (Manual, never touch)
- `rg-root-iac` → `kv-root-terraform` (9 secrets) + `storerootblob` (4 containers)

**Full details**: [ARCHITECTURE.md - Current Infrastructure](ARCHITECTURE.md#current-infrastructure)

---

## 🛠️ Working with Terraform

### Foundation Commands (Global)
```bash
cd foundation/
source ../.env
terraform init -backend-config="environments/backend.hcl"
terraform plan -out=foundation.tfplan
terraform apply foundation.tfplan
```

### Workloads Commands (Per-Environment)
```bash
cd workloads/
source ../.env

# Dev
terraform init -backend-config="environments/backend-dev.hcl"
terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan
terraform apply dev.tfplan

# Stage
terraform init -reconfigure -backend-config="environments/backend-stage.hcl"
terraform plan -var-file="environments/stage.tfvars"

# Prod
terraform init -reconfigure -backend-config="environments/backend-prod.hcl"
terraform plan -var-file="environments/prod.tfvars"
```

**Complete command reference**: [ARCHITECTURE.md - Terraform Commands](ARCHITECTURE.md#terraform-commands)

---

## 🔒 Security & Secrets

### Environment Variables (.env file)
```bash
# .env (gitignored)
export ARM_SUBSCRIPTION_ID="<sub-root-id>"  # Where Key Vault lives
export ARM_TENANT_ID="<tenant-id>"
```

### Key Vault Secrets (9 total)
- **Pattern**: `terraform-{env}-{workload}-sub-id`
- **Example**: `terraform-dev-hq-sub-id`, `terraform-dev-sales-sub-id`
- **Fetched by**: Terraform data sources in `modules/common/data-sources.tf`

**Details**: [ARCHITECTURE.md - Security & Secrets](ARCHITECTURE.md#security--secrets)

---

## 🏷️ Naming Convention

**Implementation**: `modules/common/naming.tf` (three-branch naming system)

### Standard Resources (with hyphens)
- Management Group: `mg-a10corp-sales`
- Resource Group: `rg-a10corp-sales-dev`

### No-Hyphen Resources (alphanumeric only)
- Storage Account: `sta10corpsalesdev`

**Why**: [DECISIONS.md - Decision 16](DECISIONS.md#decision-16-three-branch-naming-system-for-azure-resource-restrictions)

---

## 📝 Session Maintenance

### Before Ending a Session

1. **Update Current State** (above) if infrastructure changed
2. **Update [NEXTSTEPS.md](NEXTSTEPS.md)** if priorities changed
3. **Add to [DECISIONS.md](DECISIONS.md)** if architectural choices were made
4. **Verify `terraform plan` shows no unexpected changes**

### Session Handoff Checklist
- [ ] What was accomplished this session?
- [ ] What's the next recommended step?
- [ ] Any blockers or issues?
- [ ] Is infrastructure state clean?
- [ ] Are docs updated?

---

## 🚨 Common Pitfalls to Avoid

1. **Forgetting `source .env`** → Error: "subscription ID could not be determined"
2. **Wrong directory** → Must be in `foundation/` or `workloads/`, NOT root
3. **Missing `-var-file`** → Workloads requires `environments/{env}.tfvars`
4. **Wrong backend config** → Dev env needs `backend-dev.hcl`, not `backend-stage.hcl`
5. **Editing naming manually** → All naming logic in `modules/common/naming.tf`

**Troubleshooting**: [ARCHITECTURE.md - Troubleshooting](ARCHITECTURE.md#troubleshooting)

---

## 🔗 Git Workflow

### Committing Changes
```bash
git status
git add <files>
git commit -m "type: description

- Detail 1
- Detail 2"
git push
```

### Commit Types
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `refactor:` Code restructuring
- `chore:` Maintenance tasks

---

## 📋 Decision-Making Guidelines

### When to Ask User
- Architectural changes (new modules, major refactoring)
- Security-impacting changes
- Production deployments
- Deleting/destroying resources

### When to Proceed Automatically
- Documentation updates
- Code formatting
- Non-destructive state operations (`terraform state list/show`)
- Dev environment changes (if explicitly authorized)

### When to Update DECISIONS.md
- New architectural pattern introduced
- Trade-off decision made (chose option A over B)
- Deviation from standard practice
- Security or compliance decision

**ADR Template**: [DECISIONS.md](DECISIONS.md) (see existing entries for format)

---

## 🎓 Key Architectural Decisions (Quick Reference)

- **Decision 15**: Three-module architecture (Common + Foundation + Workloads)
- **Decision 16**: Three-branch naming (hyphens + no-hyphens + env suffixes)
- **Decision 14**: Native Key Vault integration (no scripts)
- **Decision 9**: OIDC authentication for CI/CD (zero long-lived secrets)

**Full context**: [DECISIONS.md](DECISIONS.md)

---

## 🔄 Next Actions (Quick Reference)

**Top Priority**: Deploy workloads module (dev environment)

**See**: [NEXTSTEPS.md](NEXTSTEPS.md) for complete task list with priorities

---

**Maintained For**: Claude Code AI assistant
**Last Updated**: 2025-12-17
**Repository**: Private (github.com:amaramdotme/A10_Corp-terraform.git)
