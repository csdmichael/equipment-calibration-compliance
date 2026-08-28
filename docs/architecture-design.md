**Equipment Calibration Compliance – Architecture Advisor Agent Proposal (Design Stage, Reviewable Draft)**

---

## 1. Architecture Overview

This proposal translates the approved plan into a technical architecture for the Equipment Calibration Compliance solution, targeting the Dev environment. The design addresses the business problem of calibration drift, traceability gaps, and manual impact assessment by implementing scheduled, guided calibration, automatic impact analysis, and certificate generation from immutable records.

### 1.1 Component Diagram (Textual)

- **Technician Calibration Client** (Angular 18 + Ionic 8): Tablet/handheld UI for calibration scheduling, guided capture, impact review, and certificate issue. Supports offline capture and barcode scanning.
- **Calibration Service** (Python 3.12 FastAPI, Azure App Service): API layer for calibration state, as-found locking, tolerance evaluation, certificate issue, and competency enforcement.
- **Impact Assessment Engine** (Python 3.12, Azure Functions): Queries MES for measurement history, resolves affected products, and flags incomplete results.
- **Certificate Generator** (Python 3.12, Azure Functions): Renders certificates from calibration records, stores them immutably in Azure Blob Storage.
- **Impact Narrative Workflow** (Microsoft Foundry Agent Framework): Drafts impact assessment narrative, routed through Azure API Management, always requiring human review.
- **Azure SQL Database**: Stores calibration records, test points, readings, impact decisions, and certificates.
- **Azure Blob Storage**: Stores issued certificates and environmental evidence, immutable for 10 years.
- **Azure API Management (APIM)**: Gateway for all model traffic and agent workflow, enforcing authentication, quotas, and content safety.
- **Microsoft Entra ID**: Identity provider with conditional access and competency checks.
- **External Integrations**: Quality Management System (instrument master/procedures), Manufacturing Execution System (measurement history), Training Records System (competency).

---

## 2. Architecture Decision Records (ADRs)

### ADR-001: Frontend Technology
- **Decision:** Angular 18 + Ionic 8 for cross-device UI.
- **Rationale:** Single codebase, offline support, barcode integration, accessibility.
- **Alternatives:** React Native, Flutter (not chosen due to platform standards).

### ADR-002: API Layer
- **Decision:** Python 3.12 FastAPI on Azure App Service.
- **Rationale:** Platform standard, strong typing, explicit as-found locking.
- **Alternatives:** Node.js Express (not chosen).

### ADR-003: Database
- **Decision:** Azure SQL Database.
- **Rationale:** Relational model fits calibration, test points, readings, certificates, and impact queries.
- **Alternatives:** Cosmos DB (not chosen due to strong consistency requirements).

### ADR-004: Impact Assessment Engine
- **Decision:** Azure Functions (Python).
- **Rationale:** Scalable, event-driven, integrates with MES, supports partial results flagging.
- **Alternatives:** Monolithic service (not chosen).

### ADR-005: Certificate Storage
- **Decision:** Azure Blob Storage, immutable retention.
- **Rationale:** Compliance requirement for 10-year retention and auditability.
- **Alternatives:** Filesystem, SharePoint (not chosen).

### ADR-006: Agent Workflow
- **Decision:** Microsoft Foundry Agent Framework via APIM.
- **Rationale:** Human-in-the-loop review, deterministic impact list, narrative draft only.
- **Alternatives:** Custom workflow (not chosen).

### ADR-007: Identity & Competency
- **Decision:** Microsoft Entra ID with conditional access and server-side competency check.
- **Rationale:** Attributable certificate issue, device compliance, audit trail.
- **Alternatives:** Local auth (not chosen).

---

## 3. Data Contracts & API Interfaces

### 3.1 Calibration Record (Azure SQL)
```json
{
  "calibration_id": "uuid",
  "instrument_id": "string",
  "procedure_id": "string",
  "procedure_revision": "string",
  "reference_standard_id": "string",
  "reference_standard_certificate": "string",
  "environmental_conditions": {
    "temperature": "float",
    "humidity": "float"
  },
  "test_points": [
    {
      "point_id": "string",
      "nominal_value": "float",
      "tolerance": "float",
      "as_found": "float",
      "as_left": "float",
      "result": "enum('pass','fail')"
    }
  ],
  "calibration_date": "datetime",
  "technician_id": "string",
  "certificate_id": "string",
  "status": "enum('pending','passed','failed')"
}
```

### 3.2 Impact Assessment API (MES Integration)
- **Request:** `{ instrument_id, from_date, to_date }`
- **Response:** `{ measurements: [ { measurement_id, product_id, timestamp, value } ], completeness: 'complete' | 'partial' }`

### 3.3 Certificate Generation API
- **Request:** `{ calibration_id }`
- **Response:** `{ certificate_url, traceability_chain, issued_by, issue_date }`

### 3.4 Competency Check API
- **Request:** `{ user_id }`
- **Response:** `{ is_competent: boolean, competency_level: string, expiry: date }`

---

## 4. Threat Model Considerations

- **Identity & Access:** All certificate issue and calibration actions require Entra ID authentication and device compliance. Competency is checked server-side at certificate issue.
- **Data Integrity:** As-found readings are immutable once committed. All calibration records and certificates are write-once and auditable.
- **API Security:** All external API calls use managed identity and OAuth2.0. APIM enforces quotas, content safety, and correlation headers.
- **Offline Capture:** Service worker ensures local encryption and sync integrity. Sync failures are surfaced to users.
- **Agent Workflow:** No model call can bypass human approval; narrative drafts are flagged and require explicit review.
- **External Data:** All integrations treat incoming data as untrusted; validation and error handling are explicit.
- **Certificate Storage:** Blob storage is immutable; deletion and modification are blocked by policy.
- **Audit Trail:** All certificate issues, calibration edits, and impact assessments are logged with user, device, and timestamp.

---

## 5. Implementable Technical Plan

### 5.1 Frontend
- Build Angular/Ionic UI screens per UX mockups (SCR-01 to SCR-04).
- Implement offline capture with service worker.
- Integrate barcode scanning and accessibility features.

### 5.2 Backend
- Develop FastAPI calibration service with explicit as-found locking.
- Implement endpoints for calibration scheduling, guided capture, impact assessment, certificate generation, and competency check.
- Integrate with QMS, MES, and Training Records via REST APIs with managed identity.

### 5.3 Impact Assessment
- Deploy Azure Functions for measurement history queries and impact list generation.
- Implement partial result flagging and certificate block logic.

### 5.4 Certificate Generation
- Azure Function to render certificate from calibration record.
- Store certificate in Azure Blob Storage with immutable retention policy.

### 5.5 Agent Workflow
- Configure Foundry agent for impact narrative draft.
- Route all agent/model calls through APIM with correlation and safety headers.
- Enforce human review before narrative is attached to assessment.

### 5.6 Security & Compliance
- Entra ID integration with conditional access and device compliance.
- Server-side competency check at certificate issue.
- Audit logging for all critical actions.

### 5.7 CI/CD & DevOps
- GitHub Actions for build, test, deploy with environment protection.
- Azure App Service Premium v3 for hosting, zone redundancy, and warm standby.

---

## 6. Review Checklist

- [ ] All features and user stories mapped to architecture components.
- [ ] Data contracts and API interfaces defined and traceable.
- [ ] Threat model covers identity, integrity, API, offline, agent workflow, and audit.
- [ ] Technical plan is implementable and aligns with approved stack and constraints.
- [ ] ADRs documented for all major technology and integration decisions.

---

**Ready for review and approval. Please indicate any required changes or request further detail on specific components, interfaces, or threat mitigations.**