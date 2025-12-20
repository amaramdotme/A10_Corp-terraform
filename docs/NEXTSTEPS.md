# Next Steps & Parking Lot

**Last Updated**: 2025-12-20

---

## 🎯 Top Priorities (Immediate)

### 1. ✅ Verify Centralized Tagging - COMPLETE
**Status**: ✅ Verified 2025-12-20
**Success**: Resources across root, dev, and stage subscriptions confirmed to have correct `Environment` tags (global, dev, stage, prod).

---

### 2. ✅ Test GitHub Actions Workflows - COMPLETE
**Status**: ✅ Tested 2025-12-20
**Success**: Deployment workflows for foundation and workloads are operational.

---

### 3. ✅ Test Workloads Destroy/Recreate - COMPLETE
**Status**: ✅ Tested 2025-12-20
**Success**: Workloads can be safely destroyed and recreated without impacting foundation.

---

## 🔄 Short-Term (This Week)

### 4. Add Azure Policy Assignments
**Status**: Future enhancement
**Effort**: Medium
**Scope**: New module `modules/policies/` for tagging enforcement, location restrictions, and resource SKU limits.

---

### 5. Add Monitoring & Alerting
**Status**: Next Milestone
**Effort**: Large
**Scope**: Deploy Log Analytics Workspaces per environment, set up Application Insights, and configure Azure Monitor alerts.

---

## 📋 Medium-Term (This Month)

### 6. ✅ GitHub Actions OIDC Setup - COMPLETE
**Status**: ✅ Configured and tested 2025-12-18
**Reference**: [OIDC_SETUP.md](OIDC_SETUP.md) | [DECISIONS.md - Decision 9](DECISIONS.md#decision-9-cicd-authentication-method)

---

### 7. ✅ Create Terraform Deployment Workflows - COMPLETE
**Status**: ✅ Created 2025-12-18
**Deliverables**:
- `.github/workflows/foundation-deploy.yml`
- `.github/workflows/workloads-deploy.yml`
- `.github/workflows/workloads-destroy.yml`
- `.github/workflows/foundation-destroy.yml`

---

### 8. Security Review & Least Privilege Audit
**Status**: Pending
**Scope**: Review `Network Contributor` and `AcrPull` role assignments to ensure they are scoped to minimum required levels.

---

## 🅿️ Parking Lot (Future Consideration)

### 9. Networking Module (Advanced)
### 10. State File Migration to Terraform Cloud
### 11. Infrastructure Testing (Terratest)

---

## ⚠️ Known Issues & Blockers

**None currently** - Core multi-environment infrastructure is fully operational.

---

## 📊 Success Metrics

### Current Status (2025-12-20)

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Management Groups | 3 | 3 | ✅ 100% |
| Subscription Associations | 3 | 3 | ✅ 100% |
| Resource Groups (dev) | 3 | 3 | ✅ 100% |
| Resource Groups (stage) | 3 | 3 | ✅ 100% |
| Resource Groups (prod) | 3 | 3 | ✅ 100% |
| OIDC Authentication | 1 | 1 | ✅ 100% |
| CI/CD Workflows | 4 | 4 | ✅ 100% |
| Centralized Tagging | 100% | 100% | ✅ 100% |

### Next Milestone: Governance & Monitoring
- Azure Policy enforcement active
- Centralized logging operational
- Security audit complete
