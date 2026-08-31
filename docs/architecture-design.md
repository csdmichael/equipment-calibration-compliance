# Architecture Advisor Agent – Design Stage Proposal
## Equipment Calibration Compliance (Dev Environment)

---

### 1. Architecture Overview

**Goal:**  
Replace manual calibration tracking and certificate workflows with a governed, traceable, and auditable digital solution.  
**Key Outcomes:**  
- Scheduled, guided calibration on handheld devices  
- Automatic impact assessment for out-of-tolerance instruments  
- Certificates issued from immutable records  
- Unbroken traceability to reference standards

**Target Stack:**  
- **Frontend:** Angular 18 + Ionic 8 (tablet, handheld, browser)  
- **API:** Python 3.12 FastAPI (Azure App Service)  
- **Database:** Azure SQL Database  
- **Agentic Workflow:** Microsoft Foundry + Agent Framework (impact narrative)  
- **AI Gateway:** Azure API Management (APIM)  
- **Identity:** Microsoft Entra ID (conditional access, competency gating)  
- **Storage:** Azure Blob Storage (immutable certificates, evidence)  
- **CI/CD:** GitHub Actions  
- **Integrations:** Quality Management System (instrument/procedure), Manufacturing Execution System (measurement history), Training Records (competency)

---

### 2. Architecture Recommendations

#### 2.1 Component Model

| Component                | Responsibility                                  | Hosting                | Key Interfaces                                    |
|--------------------------|-------------------------------------------------|------------------------|---------------------------------------------------|
| Calibration Client       | Due list, guided capture, certificate issue     | Ionic/Angular (Tablet, Android) | FastAPI API, barcode scanner, offline sync        |
| Calibration Service      | Calibration state, as-found locking, tolerance, certificate issue, competency enforcement | Azure App Service      | Quality Mgmt, Azure SQL, Blob Storage             |
| Impact Assessment Engine | Measurement history query, impact list          | Azure Functions        | MES API, Calibration Service                      |
| Certificate Generator    | Certificate rendering, immutable storage        | Azure Functions        | Blob Storage, Calibration Service                 |
| Impact Narrative Agent   | Drafts impact narrative, workflow pause         | Foundry/Agent Framework| APIM, Calibration Service                         |

#### 2.2 Integration Contracts

- **Quality Management System (QMS):**
  - REST, OAuth2 (managed identity)
  - Instrument master, procedures
  - On failure: serve cached procedure, block certificate issue if stale

- **Manufacturing Execution System (MES):**
  - REST, managed identity
  - Measurement history for impact assessment
  - On failure: present partial impact list, block certificate issue

- **Training Records System:**
  - REST, managed identity
  - Competency lookup for certificate gating

- **Azure API Management (APIM):**
  - All agent/model traffic routed through APIM
  - Managed identity, per-user quotas, content safety

#### 2.3 Data Contracts

**Calibration Record**
```json
{
  "instrumentId": "string",
  "procedureId": "string",
  "procedureRevision": "string",
  "referenceStandardId": "string",
  "referenceStandardCertificate": "string",
  "environmentalConditions": {
    "temperature": "number",
    "humidity": "number"
  },
  "testPoints": [
    {
      "nominal": "number",
      "tolerance": "number",
      "asFound": "number",
      "asLeft": "number",
      "result": "pass|fail"
    }
  ],
  "calibrationDate": "datetime",
  "technicianId": "string",
  "certificateId": "string",
  "status": "passed|failed",
  "extension": {
    "expiry": "datetime",
    "justification": "string",
    "approverId": "string"
  }
}
```

**Impact Assessment**
```json
{
  "instrumentId": "string",
  "lastPassingCalibrationDate": "datetime",
  "failedCalibrationDate": "datetime",
  "affectedMeasurements": [
    {
      "measurementId": "string",
      "productLotId": "string",
      "timestamp": "datetime"
    }
  ],
  "impactNarrative": "string",
  "reviewerId": "string",
  "status": "pending|approved|closed"
}
```

**Certificate**
```json
{
  "certificateId": "string",
  "calibrationRecordId": "string",
  "issuedBy": "string",
  "issueDate": "datetime",
  "referenceStandardChain": [
    {
      "standardId": "string",
      "certificateNumber": "string",
      "validUntil": "datetime"
    }
  ],
  "documentUrl": "string (blob storage)"
}
```

---

### 3. Decision Records

| Decision ID | Description | Rationale | Status |
|-------------|-------------|-----------|--------|
| ADR-001     | Use Angular/Ionic for client | Single codebase, offline support | Approved |
| ADR-002     | Python FastAPI for API layer | Platform standard, explicit boundary rules | Approved |
| ADR-003     | Azure SQL for calibration/impact/certificates | Relational joins, strong consistency | Approved |
| ADR-004     | Azure Functions for impact/certificate engines | Event-driven, scalable | Approved |
| ADR-005     | Foundry Agent workflow for impact narrative | Human-in-the-loop, deterministic impact list | Approved |
| ADR-006     | APIM for all agent/model traffic | Enforcement, observability, security | Approved |
| ADR-007     | Entra ID with competency gating | Certificate issue is accredited | Approved |
| ADR-008     | Azure Blob Storage for certificates | Immutability, retention | Approved |

---

### 4. Threat Model Considerations

- **As-Found Readings:**  
  - Immutable once entered; cannot be edited or overwritten.
  - Lock enforced at API boundary and database level.
  - Audit trail for every calibration event.

- **Certificate Issue:**  
  - Competency gating: only accredited users (validated via training records) can issue certificates.
  - Certificate is generated from record, not manual entry; stored immutably.

- **Impact Assessment:**  
  - No silent failures: partial lists are flagged, certificate issue blocked if incomplete.
  - All agent/model calls routed through APIM for content safety and correlation.

- **Offline Capture:**  
  - Service worker backs offline mode; sync on reconnection.
  - No certificate issue allowed while offline.

- **Reference Standard Traceability:**  
  - Reference standards checked for calibration validity before use.
  - Chain-of-traceability recorded and auditable.

- **Identity & Access:**  
  - Conditional access: only Intune-compliant devices.
  - Role-based access: technician, supervisor, quality manager.

- **Data Retention:**  
  - Certificates and evidence retained for 10 years, immutable.

- **Integration Failure Handling:**  
  - QMS/MES failures block certificate issue, never allow stale data.

---

### 5. Implementable Technical Plan

#### 5.1 Phased Implementation

**Phase 1: Core Calibration Workflow**
- Build Ionic/Angular client (due list, guided capture, offline mode)
- FastAPI service layer (calibration state, as-found locking, tolerance evaluation)
- Azure SQL schema for calibration records, test points, certificates
- Integration with QMS for instrument/procedure data

**Phase 2: Impact Assessment**
- Azure Function for impact list (MES integration, measurement query)
- FastAPI endpoints for impact assessment
- UI for impact review, partial list handling

**Phase 3: Certificate Generation & Traceability**
- Azure Function for certificate rendering
- Blob storage integration (immutable document write)
- Reference standard chain validation and recording

**Phase 4: Agentic Workflow & Narrative**
- Foundry agent workflow for impact narrative drafting
- APIM route for all agent/model traffic
- Human-in-the-loop review UI for quality engineer

**Phase 5: Security, Compliance, and Retention**
- Entra ID integration, conditional access, role/competency gating
- Audit logging, certificate retention policy enforcement
- Threat model validation and penetration testing

**Phase 6: CI/CD & DevOps**
- GitHub Actions pipeline (build, test, deploy)
- Azure App Service deployment (zone redundant, warm standby)
- Monitoring and alerting setup

---

### 6. Review Checklist

- [ ] All functional/non-functional requirements traceable to architecture components
- [ ] Data contracts defined for calibration, impact, certificate, traceability
- [ ] Integration contracts specify failure handling and security
- [ ] Threat model covers all critical flows (as-found, certificate, impact, offline)
- [ ] Technical plan is phased, implementable, and aligns with approved stack
- [ ] Decision records documented and linked to rationale

---

### 7. Next Steps

- Review and approve architecture proposal
- Validate data/API contracts with integration partners
- Confirm threat model with security/compliance stakeholders
- Proceed to code generation and test planning upon approval

---

**References:**  
- [Requirements Summary](https://github.com/csdmichael/equipment-calibration-compliance/blob/main/docs/intake/requirements/Equipment-Calibration-Compliance-Requirements.docx)  
- [Technical Requirements](https://github.com/csdmichael/equipment-calibration-compliance/blob/main/docs/intake/technical-requirements/Equipment-Calibration-Compliance-Technical-Requirements.docx)  
- [UX Mockups](https://github.com/csdmichael/equipment-calibration-compliance/blob/main/docs/intake/ux-mockups/Equipment-Calibration-Compliance-UX-Mockups.docx)

---

**For review:**  
Please confirm alignment with business goals, stack, and compliance requirements. Feedback or approval required before implementation phase.