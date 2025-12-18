# Documentation Reorganization Plan

## Current State Analysis

### Inventory of .md Files (15 total)

#### Root Level (6 files)
1. **README.md** - Main repo readme (OUTDATED - references monolithic structure)
2. **CLAUDE.md** - AI assistant context and session notes (CURRENT - updated today)
3. **SESSION_SUMMARY_2025-12-17.md** - Today's session handoff (NEW)
4. **archive_monolithic/README.md** - Explains archived code
5. **archive_monolithic/environments/README.md** - Old environment docs

#### docs/ Directory (4 files)
6. **docs/DECISIONS.md** - Architectural decision records (OUTDATED - still references two-module)
7. **docs/NEXT_STEPS.md** - Migration plan (OUTDATED - architecture already implemented)
8. **docs/TERRAFORM_COMMANDS.md** - Terraform command reference (OUTDATED - monolithic commands)
9. **docs/azure.md** - Azure architecture docs (OUTDATED - no MG IDs)

#### Module READMEs (4 files)
10. **foundation/README.md** - Foundation deployment guide (CURRENT)
11. **modules/common/README.md** - Common module docs (CURRENT)
12. **modules/foundation/README.md** - Foundation module docs (CURRENT)
13. **modules/workloads/README.md** - Workloads module docs (CURRENT)
14. **workloads/README.md** - Workloads deployment guide (needs verification)

#### secure/ Directory (1 file - gitignored)
15. **secure/OIDC_SETUP.md** - GitHub Actions OIDC setup (status unknown)

### Additional Non-.md Documentation
- **terraform_commands.txt** - Quick reference (CURRENT - created today)

---

## Problems Identified

### 1. Outdated Root README.md
- ❌ References monolithic structure (providers.tf, data-sources.tf, etc.)
- ❌ Shows old project structure diagram
- ❌ References two-module architecture as "planned"
- ❌ No mention of three-module architecture
- ❌ Workflow examples use wrong directory structure

### 2. Outdated docs/ Files
- ❌ **NEXT_STEPS.md** describes migration that's already complete
- ❌ **TERRAFORM_COMMANDS.md** has monolithic workflow examples
- ❌ **DECISIONS.md** needs Decision 15 (three-branch naming system)
- ❌ **azure.md** missing deployed MG IDs and current state

### 3. Fragmented Quick References
- terraform_commands.txt (root level)
- docs/TERRAFORM_COMMANDS.md (docs folder)
- Both serve same purpose but different content

### 4. Session Summaries Accumulation
- SESSION_SUMMARY_2025-12-17.md in root
- No clear pattern for future session summaries
- Risk of clutter in root directory

### 5. No Clear Documentation Hierarchy
- Mix of user-facing docs and AI assistant docs
- No distinction between reference docs vs guides vs ADRs
- Module docs are good but disconnected from root docs

---

## Proposed Reorganization

### Goals
1. **Single Source of Truth** - No duplicate or conflicting docs
2. **Clear Hierarchy** - Logical grouping of documentation types
3. **User-Friendly** - Easy to find what you need
4. **Maintainable** - Easy to keep up-to-date
5. **Git-Friendly** - Important docs in repo, sensitive docs gitignored

### New Structure

```
terraform_iac/
├── README.md                          # ✏️ UPDATE - Main entry point (user-facing)
├── CLAUDE.md                          # ✅ KEEP - AI assistant context
│
├── docs/                              # 📚 All documentation
│   ├── architecture/                  # 🆕 Architecture docs
│   │   ├── overview.md               # High-level architecture
│   │   ├── modules.md                # Three-module design explained
│   │   ├── management-groups.md      # MG hierarchy with IDs
│   │   └── naming-convention.md      # CAF naming patterns
│   │
│   ├── guides/                        # 🆕 How-to guides
│   │   ├── getting-started.md        # First-time setup
│   │   ├── local-development.md      # Local workflow
│   │   ├── deploying-foundation.md   # Foundation deployment
│   │   ├── deploying-workloads.md    # Workloads deployment
│   │   └── cicd-setup.md             # GitHub Actions setup
│   │
│   ├── reference/                     # 🆕 Reference material
│   │   ├── terraform-commands.md     # Comprehensive command reference
│   │   ├── azure-resources.md        # Azure resource inventory
│   │   └── troubleshooting.md        # Common issues and solutions
│   │
│   ├── decisions/                     # 🆕 ADRs (Architectural Decision Records)
│   │   ├── README.md                 # Index of all decisions
│   │   ├── 001-terraform-installation.md
│   │   ├── 002-resource-provider-registration.md
│   │   ├── ...
│   │   └── 015-three-branch-naming.md
│   │
│   └── sessions/                      # 🆕 Session summaries (AI assistant)
│       └── 2025-12-17-three-module-migration.md
│
├── archive_monolithic/                # ✅ KEEP - Archived code
│   └── README.md                      # ✅ KEEP - Explains archive
│
├── foundation/                        # ✅ KEEP - Foundation deployment
│   └── README.md                      # ✅ KEEP - Deployment guide
│
├── workloads/                         # ✅ KEEP - Workloads deployment
│   └── README.md                      # ✅ KEEP - Deployment guide
│
├── modules/                           # ✅ KEEP - Shared modules
│   ├── common/README.md              # ✅ KEEP - Module docs
│   ├── foundation/README.md          # ✅ KEEP - Module docs
│   └── workloads/README.md           # ✅ KEEP - Module docs
│
└── secure/                            # ✅ KEEP - Sensitive docs (gitignored)
    └── OIDC_SETUP.md                  # ✅ KEEP - OIDC configuration
```

---

## Migration Plan

### Phase 1: Create New Structure
```bash
mkdir -p docs/{architecture,guides,reference,decisions,sessions}
```

### Phase 2: Reorganize Existing Files

#### 2.1. Update README.md
- [ ] Replace project structure with three-module architecture
- [ ] Update quick start to reference foundation/workloads
- [ ] Update features list (mark three-module as ✅ implemented)
- [ ] Update links to new docs/ structure
- [ ] Add architecture diagram (ASCII art is fine)

#### 2.2. Move and Update Architecture Docs
- [ ] **docs/architecture/overview.md** (NEW)
  - High-level three-module architecture
  - Diagram of module dependencies
  - Deployment model (foundation once, workloads per-env)

- [ ] **docs/architecture/modules.md** (NEW)
  - Detailed explanation of common/foundation/workloads
  - Module responsibilities and boundaries
  - When to use which module

- [ ] **docs/architecture/management-groups.md** (from docs/azure.md)
  - Current MG hierarchy with actual Azure IDs
  - Subscription associations
  - Management group structure rationale

- [ ] **docs/architecture/naming-convention.md** (NEW)
  - Three-branch naming system explained
  - Examples for all resource types
  - How to add new resource types
  - Reference to modules/common/naming.tf

#### 2.3. Create User Guides
- [ ] **docs/guides/getting-started.md** (from README.md)
  - Prerequisites
  - Initial setup (Azure CLI, .env file, etc.)
  - First deployment walkthrough

- [ ] **docs/guides/local-development.md** (NEW)
  - Daily workflow (source .env, terraform commands)
  - Working with foundation vs workloads
  - Testing changes before deployment

- [ ] **docs/guides/deploying-foundation.md** (from foundation/README.md + terraform_commands.txt)
  - When to deploy foundation
  - Step-by-step deployment
  - Verification steps
  - What NOT to do (don't destroy!)

- [ ] **docs/guides/deploying-workloads.md** (from workloads/README.md + terraform_commands.txt)
  - Multi-environment deployment
  - Environment switching
  - Safe destroy/recreate workflow

- [ ] **docs/guides/cicd-setup.md** (from secure/OIDC_SETUP.md if appropriate)
  - GitHub Actions OIDC setup
  - Required secrets
  - Workflow usage

#### 2.4. Create Reference Docs
- [ ] **docs/reference/terraform-commands.md** (merge docs/TERRAFORM_COMMANDS.md + terraform_commands.txt)
  - Comprehensive command reference
  - Foundation commands (2 switches)
  - Workloads commands (3 switches)
  - State management commands
  - Troubleshooting commands

- [ ] **docs/reference/azure-resources.md** (from docs/azure.md)
  - Pre-Terraform infrastructure (RG, KV, Storage)
  - Foundation resources (MGs, subscriptions)
  - Workloads resources (RGs per environment)
  - Current state inventory

- [ ] **docs/reference/troubleshooting.md** (from README.md + CLAUDE.md)
  - Common errors and solutions
  - Provider authentication issues
  - State lock issues
  - Naming validation errors

#### 2.5. Restructure Decision Records
- [ ] **docs/decisions/README.md** (NEW)
  - Index of all decisions
  - Table format with decision number, title, status

- [ ] **Split docs/DECISIONS.md into individual files**
  - docs/decisions/001-terraform-installation.md
  - docs/decisions/002-resource-provider-registration.md
  - ... (13 existing decisions)
  - docs/decisions/015-three-branch-naming.md (NEW)

#### 2.6. Move Session Summaries
- [ ] **Move SESSION_SUMMARY_2025-12-17.md** → docs/sessions/2025-12-17-three-module-migration.md
- [ ] Update CLAUDE.md to reference new location

#### 2.7. Archive/Delete Obsolete Files
- [ ] **DELETE docs/NEXT_STEPS.md** (migration complete, no longer needed)
- [ ] **DELETE docs/TERRAFORM_COMMANDS.md** (merged into docs/reference/terraform-commands.md)
- [ ] **DELETE terraform_commands.txt** (merged into docs/reference/terraform-commands.md)
- [ ] **KEEP docs/azure.md** temporarily, will be split into architecture/ and reference/

### Phase 3: Update Cross-References
- [ ] Update all internal links in documentation
- [ ] Update CLAUDE.md to reference new structure
- [ ] Update module READMEs to link to docs/
- [ ] Update foundation/README.md and workloads/README.md

### Phase 4: Add Missing Content

#### 4.1. Create Decision 15: Three-Branch Naming System
```markdown
# Decision 15: Three-Branch Naming System

**Context**: Azure Storage Accounts don't support hyphens, but CAF naming uses hyphens

**Decision**: Implement three-branch naming logic with `no_hyphen_resources` set

**Rationale**:
- Maintains CAF compliance for standard resources
- Handles Azure restrictions (storage accounts, etc.)
- Expandable design via set membership
- Clean ternary logic on separator character

**Implementation**: See modules/common/naming.tf lines 64-83
```

#### 4.2. Update README.md Project Structure
Show actual three-module architecture, not monolithic

#### 4.3. Create Architecture Overview
High-level diagram and explanation of the three-module design

---

## Success Criteria

✅ All documentation is up-to-date with three-module architecture
✅ Clear distinction between user docs (guides) and reference docs
✅ No duplicate or conflicting documentation
✅ Easy to find information (logical hierarchy)
✅ Session summaries don't clutter root directory
✅ Decision records are easily browseable
✅ All cross-references updated
✅ README.md is accurate entry point

---

## Rollout Strategy

### Option 1: Big Bang (Recommended for Current State)
- Do all reorganization at once
- Single commit: "docs: Reorganize documentation into logical hierarchy"
- Easier to maintain consistency
- Clear before/after state

### Option 2: Incremental
- Phase 1: Create new structure
- Phase 2: Move files gradually
- Phase 3: Update references
- Risk: Broken links during transition

**Recommendation**: Use Option 1 (Big Bang) since we're already in a refactoring session

---

## Estimated Effort

- **Phase 1** (Create structure): 5 minutes
- **Phase 2** (Move and update files): 2-3 hours
  - 2.1 README.md: 30 min
  - 2.2 Architecture docs: 30 min
  - 2.3 Guides: 45 min
  - 2.4 Reference: 30 min
  - 2.5 Decision records: 30 min
  - 2.6 Session summaries: 5 min
  - 2.7 Cleanup: 10 min
- **Phase 3** (Update cross-references): 30 min
- **Phase 4** (Add missing content): 30 min

**Total**: ~4 hours of focused work

---

## Benefits

### For Users
- 🎯 **Easy Navigation** - Clear hierarchy makes finding info quick
- 📖 **Better Onboarding** - Getting started guide is separate from reference
- 🔍 **Searchable** - Organized structure helps with grep/find

### For AI Assistants (Claude)
- 📍 **Clear Context** - CLAUDE.md + docs/architecture for quick understanding
- 📜 **Session History** - docs/sessions/ for handoffs
- 🧭 **Decision Trail** - docs/decisions/ for architectural reasoning

### For Maintenance
- 🔄 **Single Source of Truth** - No duplicate docs to keep in sync
- ✏️ **Easy Updates** - Clear which file to update for which topic
- 🗂️ **Logical Grouping** - Related docs are together

---

## Next Steps

1. **Review this plan** with user
2. **Get approval** for reorganization approach
3. **Execute Phase 1** (create structure)
4. **Execute Phase 2** (move and update files)
5. **Execute Phase 3** (update cross-references)
6. **Execute Phase 4** (add missing content)
7. **Commit and push** documentation reorganization
8. **Update CLAUDE.md** with new documentation structure

---

**Created**: 2025-12-17
**Status**: Proposed
**Requires**: User approval before execution
