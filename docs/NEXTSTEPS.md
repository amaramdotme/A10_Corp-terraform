# Next Steps & Parking Lot

**Last Updated**: 2025-12-20

---

## 🎯 Top Priorities (Immediate)

### 1. ✅ Verify Centralized Tagging - COMPLETE
**Status**: ✅ Verified 2025-12-20
**Success**: Resources across root, dev, and stage subscriptions confirmed to have correct `Environment` tags.

---

### 2. ✅ Test GitHub Actions Workflows - COMPLETE
**Status**: ✅ Tested 2025-12-20
**Success**: Deployment workflows for foundation and workloads are operational with OIDC.

---

### 3. ✅ Test Workloads Destroy/Recreate - COMPLETE
**Status**: ✅ Tested 2025-12-20
**Success**: Workloads can be safely destroyed and recreated without impacting foundation.

---

### 4. ✅ Initial Governance & Monitoring (Phase 1) - COMPLETE
**Status**: ✅ Deployed 2025-12-20
**Deliverables**:
- Created `modules/policies` (Native Terraform).
- Enforced: Tagging (`Environment`), Location (`eastus`), Cost (`Allowed VM SKUs`), Security (`Secure Transfer`).
- Deployed: Centralized Log Analytics Workspace in Foundation (`log-a10corp-hq`).

---

## 🔄 Short-Term (This Week)

### 5. Advanced Policy Enforcement (Phase 2)
**Status**: Next Priority
**Scope**:
- **Naming Convention**: Enforce `*-a10corp-*` pattern check on Resource Groups to prevent "rogue" unbranded resources.
- **Observability Audit**: Add "Audit if Diagnostic Settings are missing" policy to ensure resources connect to the Central Log Analytics Workspace.

---

### 6. Workload Observability Integration
**Status**: Pending
**Scope**: Update `modules/workloads` to:
- Retrieve the Central LAW ID from Foundation outputs.
- Configure Diagnostic Settings for Workload resources (VNets, NSGs, AKS) to ship logs to that ID.

---

## 📋 Medium-Term (This Month)

### 7. Security Review & Least Privilege Audit
**Status**: Pending
**Scope**: Review `Network Contributor` and `AcrPull` role assignments to ensure they are scoped to minimum required levels.

---

## 🅿️ Parking Lot (Future Consideration)

### 8. Networking Module (Advanced)
### 9. State File Migration to Terraform Cloud
### 10. Infrastructure Testing (Terratest)

---

## ⚠️ Known Issues & Blockers

**None currently** - Core infrastructure, Governance, and CI/CD are fully operational.

---

## 📊 Success Metrics

### Current Status (2025-12-20)

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Management Groups | 3 | 3 | ✅ 100% |
| Subscription Associations | 3 | 3 | ✅ 100% |
| Resource Groups (dev) | 3 | 3 | ✅ 100% |
| CI/CD Pipelines | 4 | 4 | ✅ 100% |
| Governance Policies | 4 | 4 | ✅ 100% |
| Centralized Logging | 1 | 1 | ✅ 100% |

### Next Milestone: Deep Observability
- All workloads automatically shipping logs to Foundation
- Policy auditing for "blind" resources