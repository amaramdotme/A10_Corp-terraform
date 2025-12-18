# Documentation Refactoring Plan - Zero Duplication Strategy

**Created**: 2025-12-17
**Status**: Ready for Execution
**Estimated Time**: 1 hour

---

## 🎯 Objective

Eliminate all duplicate and outdated documentation, ensuring each piece of information exists in exactly ONE place.

---

## 📊 Current State Analysis

**Total Documentation**: 14 active .md files (3,361 lines excluding archives)

**Major Issues**:
1. ❌ **OUTDATED**: README.md references monolithic structure (now three-module)
2. ❌ **OUTDATED**: docs/DECISIONS.md missing Decision 15 (three-branch naming)
3. ❌ **OUTDATED**: docs/azure.md missing current infrastructure IDs
4. ❌ **OBSOLETE**: docs/NEXT_STEPS.md (711 lines) - migration already complete
5. ❌ **DUPLICATE**: CLAUDE.md + README.md both have quick start workflows
6. ❌ **DUPLICATE**: docs/TERRAFORM_COMMANDS.md + terraform_commands.txt (577 total lines)
7. ❌ **MISPLACED**: SESSION_SUMMARY_2025-12-17.md in root (should be in docs/)
8. ❌ **OBSOLETE**: DOCUMENTATION_REORGANIZATION_PLAN.md (355 lines) - superseded by this plan

**Lines to Remove**: 1,129 lines of duplicate/obsolete content

---

## 📋 Single Source of Truth Matrix

| Topic                    | Owner File                      | No Duplicates In           |
|--------------------------|---------------------------------|----------------------------|
| Project Overview         | README.md (root)                | CLAUDE.md                  |
| Quick Start              | README.md (root)                | CLAUDE.md                  |
| Architecture Decisions   | docs/DECISIONS.md               | README.md, CLAUDE.md       |
| Module Design Details    | CLAUDE.md                       | README.md                  |
| Terraform Commands       | docs/TERRAFORM_COMMANDS.md      | terraform_commands.txt     |
| Azure Resource Inventory | docs/azure.md                   | README.md, CLAUDE.md       |
| Foundation Deployment    | foundation/README.md            | README.md, CLAUDE.md       |
| Workloads Deployment     | workloads/README.md             | README.md, CLAUDE.md       |
| AI Assistant Context     | CLAUDE.md                       | README.md                  |
| Session History          | docs/sessions/*.md              | CLAUDE.md (links only)     |

**Principle**: Each topic has ONE authoritative source. All other files LINK to it, never duplicate it.

---

## 🗂️ File-by-File Actions

### **1. README.md** - The Public Entry Point
**Current**: 391 lines, OUTDATED
**Target**: ~250 lines

**Actions**:
- ✏️ UPDATE: Replace project structure with three-module architecture
- ✏️ UPDATE: Quick Start to reference foundation/workloads directories
- ✏️ UPDATE: Features list (mark three-module as ✅)
- ✏️ SIMPLIFY: Remove architectural details (link to DECISIONS.md)
- ✏️ SIMPLIFY: Remove detailed commands (link to TERRAFORM_COMMANDS.md)
- ✏️ ADD: Clear navigation to foundation/README.md and workloads/README.md

**New Structure**:
```markdown
# A10 Corp Azure Infrastructure
## What This Does (2 paragraphs)
## Architecture Overview (diagram + link to DECISIONS.md)
## Quick Start (5 steps → link to foundation/README.md)
## Documentation Index (navigation to all docs)
## Troubleshooting (5 issues → link to TERRAFORM_COMMANDS.md)
```

---

### **2. CLAUDE.md** - AI Assistant Context
**Current**: ~400 lines, MOSTLY CURRENT
**Target**: ~350 lines

**Actions**:
- ✏️ UPDATE: "Current State" section with workloads deployment (DONE today)
- ✏️ UPDATE: File structure to show three-module architecture
- ✏️ ADD: Link to docs/sessions/ for historical context
- ❌ REMOVE: Duplicate workflow instructions (replace with links)
- ✅ KEEP: Exit routine, session maintenance, troubleshooting, current deployment status

**Unique Role**: AI-specific guidance + authoritative source for current deployment status

---

### **3. docs/DECISIONS.md** - Architectural Decision Records
**Current**: 925 lines, MISSING Decision 15
**Target**: ~1050 lines

**Actions**:
- ✏️ ADD: **Decision 15 - Three-Branch Naming System**
  ```markdown
  ## Decision 15: Three-Branch Naming System for Azure Restrictions

  **Context**: Azure Storage Accounts don't support hyphens (alphanumeric only),
  but CAF naming uses hyphens

  **Options**:
  - Two-branch (standard + env-aware): ❌ Can't handle storage accounts
  - **Three-branch with no_hyphen_resources set**: ✅ Handles all Azure restrictions

  **Decision**: Implement three-branch naming logic

  **Implementation**: modules/common/naming.tf lines 64-83

  **Result**:
  - Standard resources: "rg-a10corp-sales-dev" (with hyphens)
  - No-hyphen resources: "sta10corpsalesdev" (alphanumeric only)
  - Global resources: "mg-a10corp-sales" (no environment)
  ```

- ✏️ UPDATE: Decision 11 status from "Planned" to "✅ Implemented (2025-12-17)"
- ✏️ UPDATE: Decision 14 to reflect actual Key Vault integration status

---

### **4. docs/TERRAFORM_COMMANDS.md** - Complete Command Reference
**Current**: 514 lines, OUTDATED (monolithic)
**Target**: ~650 lines (foundation + workloads)

**Actions**:
- ✏️ REPLACE: All monolithic examples with three-module workflows
- ✏️ MERGE: Content from terraform_commands.txt (foundation/workloads commands)
- ✏️ ORGANIZE: Into sections:
  1. **Foundation Lifecycle** (init, plan, apply, state, outputs, destroy)
  2. **Workloads Lifecycle** (init, plan, apply, state, outputs, destroy)
  3. **State Management** (import, show, rm, mv, pull)
  4. **Multi-Environment Workflows** (dev → stage → prod)
  5. **Troubleshooting Commands**

**Source Content**: Merge terraform_commands.txt (delete after merge)

---

### **5. docs/azure.md** - Azure Resources Inventory
**Current**: 90 lines, OUTDATED
**Target**: ~140 lines

**Actions**:
- ✏️ UPDATE: Deployment status (foundation ✅, workloads ✅)
- ✏️ ADD: Management Group IDs:
  ```
  mg-a10corp-hq:      a56fd357-2ecc-46bf-b831-1b86e5fd43bb
  mg-a10corp-sales:   3ad4b4c9-368c-44c9-8f02-df14e0da8447
  mg-a10corp-service: 4b511fa7-48ad-495e-b7d7-bf6cfdc8a22e
  ```
- ✏️ ADD: Resource Group details (rg-a10corp-shared-dev, sales-dev, service-dev)
- ✏️ ADD: Pre-Terraform infrastructure (Key Vault: kv-root-terraform, Storage: storerootblob)
- ✏️ UPDATE: Subscription associations (all 3 subscriptions correctly associated)
- ❌ REMOVE: Architecture explanations (link to DECISIONS.md instead)

**Unique Role**: Current state inventory with actual Azure resource IDs

---

### **6. foundation/README.md** - Foundation Deployment Guide
**Current**: 159 lines, CURRENT
**Target**: ~200 lines

**Actions**:
- ✏️ ADD: Verification section:
  ```bash
  terraform state list
  terraform state show module.foundation.azurerm_management_group.a10corp
  terraform output
  ```
- ✏️ ADD: "What NOT to Do" section (⚠️ Never destroy foundation!)
- ✏️ ADD: Backend configuration details
- ✅ KEEP: Step-by-step deployment workflow

---

### **7. workloads/README.md** - Workloads Deployment Guide
**Current**: 157 lines, CURRENT
**Target**: ~220 lines

**Actions**:
- ✏️ ADD: Multi-environment deployment examples:
  ```bash
  # Dev
  terraform plan -var-file="environments/dev.tfvars" -out=dev.tfplan

  # Stage
  terraform plan -var-file="environments/stage.tfvars" -out=stage.tfplan

  # Prod
  terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
  ```
- ✏️ ADD: Safe destroy/recreate workflow (workloads are safe to destroy)
- ✏️ ADD: Environment switching best practices
- ✏️ ADD: Backend configuration for all three environments

---

### **8-10. Module READMEs** - Keep As-Is
- ✅ **KEEP**: modules/common/README.md (162 lines)
- ✅ **KEEP**: modules/foundation/README.md (98 lines)
- ✅ **KEEP**: modules/workloads/README.md (154 lines)

**No changes needed** - all current and accurate

---

### **11. docs/NEXT_STEPS.md** - DELETE
**Status**: 711 lines, OBSOLETE (migration complete)
**Action**: ❌ **DELETE** - Migration documented in SESSION_SUMMARY

---

### **12. SESSION_SUMMARY_2025-12-17.md** - MOVE
**Current Location**: Root directory
**New Location**: `docs/sessions/2025-12-17-three-module-migration.md`
**Action**: 🔄 **MOVE**

---

### **13. DOCUMENTATION_REORGANIZATION_PLAN.md** - DELETE
**Status**: 355 lines, superseded by this plan
**Action**: ❌ **DELETE** after executing this refactoring

---

### **14. terraform_commands.txt** - DELETE
**Status**: 63 lines, duplicate content
**Action**: ❌ **DELETE** after merging into docs/TERRAFORM_COMMANDS.md

---

### **15. secure/*** - DO NOT TOUCH
**Action**: ✅ **LEAVE ALONE** - No changes to secure/ directory

---

## 🚀 Execution Steps

### Step 1: Create Directory Structure (1 min)
```bash
cd /home/wsladmin/dev/cloud_computing/amaram_git_realm/projects/terraform_iac
mkdir -p docs/sessions
```

### Step 2: Move Files (1 min)
```bash
mv SESSION_SUMMARY_2025-12-17.md docs/sessions/2025-12-17-three-module-migration.md
```

### Step 3: Update Files (40 min)
Execute updates in this order:
1. docs/DECISIONS.md (add Decision 15)
2. docs/TERRAFORM_COMMANDS.md (merge terraform_commands.txt)
3. docs/azure.md (update current state)
4. README.md (simplify, update structure)
5. CLAUDE.md (update current state, add links)
6. foundation/README.md (add verification)
7. workloads/README.md (add multi-env)

### Step 4: Delete Obsolete Files (1 min)
```bash
rm docs/NEXT_STEPS.md
rm terraform_commands.txt
rm DOCUMENTATION_REORGANIZATION_PLAN.md
```

### Step 5: Verify Cross-References (10 min)
- Check all links work
- Ensure no broken references
- Update any remaining duplicates

### Step 6: Git Commit (5 min)
```bash
git add .
git commit -m "docs: Refactor to eliminate duplication and update for three-module architecture

- Add Decision 15 (three-branch naming system)
- Merge terraform_commands.txt into TERRAFORM_COMMANDS.md
- Update README.md for three-module architecture
- Update azure.md with current deployment state
- Move session summaries to docs/sessions/
- Delete obsolete NEXT_STEPS.md (migration complete)
- Remove 1,129 lines of duplicate/obsolete content"
git push
```

---

## ✅ Success Criteria

After refactoring:
1. ✅ **Zero Duplication** - Each fact in exactly ONE file
2. ✅ **Clear Ownership** - Each topic has single authoritative source
3. ✅ **Current Information** - All docs reflect three-module architecture
4. ✅ **Easy Navigation** - Clear links between docs
5. ✅ **Minimal Maintenance** - Updates needed in only one place
6. ✅ **1,129 lines removed** - Eliminated duplicates and obsolete content

---

## 📝 Final File Count

**Before**: 14 files, ~3,361 lines
**After**: 11 files, ~2,510 lines
**Reduction**: 3 files, ~851 lines (25% reduction)

**Files Removed**:
- docs/NEXT_STEPS.md (711 lines)
- terraform_commands.txt (63 lines)
- DOCUMENTATION_REORGANIZATION_PLAN.md (355 lines)

**Files Moved**:
- SESSION_SUMMARY_2025-12-17.md → docs/sessions/

**Files Updated**:
- README.md (simplified)
- CLAUDE.md (updated)
- docs/DECISIONS.md (Decision 15 added)
- docs/TERRAFORM_COMMANDS.md (merged content)
- docs/azure.md (current state)
- foundation/README.md (verification added)
- workloads/README.md (multi-env added)

---

## 🎯 For Next Session

**Command to Start**:
```bash
cd /home/wsladmin/dev/cloud_computing/amaram_git_realm/projects/terraform_iac
cat DOCUMENTATION_REFACTORING_PLAN.md
# Then execute steps 1-6 above
```

**Total Time**: ~1 hour
**Difficulty**: Medium (mostly content updates)
**Risk**: Low (no code changes, only documentation)

---

**Ready for Execution**: ✅
**Reviewed By**: User (pending)
**Execute In**: Fresh session (recommended)
