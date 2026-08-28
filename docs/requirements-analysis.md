**Equipment Calibration Compliance – Plan Stage Proposal (Reviewable Draft)**

---

## 1. Epic

**EPIC-01: Equipment Calibration Compliance**  
*As a quality and metrology organisation, we need calibrations scheduled, performed and recorded on a handheld with automatic impact assessment when an instrument fails, so that no instrument is used out of calibration and the effect of any failure is known immediately.*

---

## 2. Features & User Stories

### FEAT-01: Calibration Scheduling and Due Management

| User Story | Description | Acceptance Criteria | Priority |
|------------|-------------|--------------------|----------|
| US-101 | As a metrology technician, I want to see instruments due for calibration ranked by due date and criticality, so that I work the schedule in the order that protects product quality. | - Instruments are sorted by days to due and criticality.<br>- Each row shows instrument, location, interval, last calibration date.<br>- Overdue instruments are flagged; notifications sent to owner and quality manager. | Must |
| US-102 | As a production supervisor, I want an overdue instrument blocked from being drawn for use, so that measurements are never taken with an uncalibrated device. | - Overdue instrument cannot be issued; reason and due date shown.<br>- Extensions require expiry, justification, and approver identity. | Must |

---

### FEAT-02: Guided Calibration Capture

| User Story | Description | Acceptance Criteria | Priority |
|------------|-------------|--------------------|----------|
| US-201 | As a metrology technician, I want the test points and tolerances for this instrument presented in order, so that I follow the approved procedure rather than working from memory. | - Procedure, revision, test points, and tolerances shown in sequence.<br>- Reference standard validity enforced; cannot proceed with expired standard. | Must |
| US-202 | As a quality engineer, I want as-found readings captured before any adjustment, so that the condition the instrument was in during production use is recorded honestly. | - As-found values locked before as-left can be entered.<br>- Out-of-tolerance as-found flags calibration as failure. | Must |

---

### FEAT-03: Out-of-Tolerance Impact Assessment

| User Story | Description | Acceptance Criteria | Priority |
|------------|-------------|--------------------|----------|
| US-301 | As a quality engineer, I want to see all measurements taken with a failed instrument since its last passing calibration, so I can assess product impact. | - List is generated deterministically from measurement history.<br>- Partial results are flagged as incomplete if source system is unavailable.<br>- Certificate issue is blocked until assessment is reviewed and closed. | Must |

---

### FEAT-04: Certificate Generation and Traceability

| User Story | Description | Acceptance Criteria | Priority |
|------------|-------------|--------------------|----------|
| US-401 | As a metrology technician, I want to generate and issue a calibration certificate directly from the record, so that the traceability chain is unbroken and auditable. | - Certificate generated from stored calibration record.<br>- Reference standard chain included.<br>- Certificate is immutable and stored in Azure Blob for 10 years.<br>- Issue is competency-gated and attributable. | Must |

---

## 3. Tasks (Sample, per Feature)

### FEAT-01: Calibration Scheduling and Due Management

- Design and implement due/overdue list UI (SCR-01).
- Integrate with quality management system for instrument master data.
- Implement notification logic for overdue instruments.
- Enforce blocking logic at tool crib (integration with MES/tool crib system).
- Extension workflow (approval, expiry, justification capture).

### FEAT-02: Guided Calibration Capture

- Guided procedure UI (SCR-02).
- Reference standard selection and validity check.
- As-found/as-left entry with locking and validation.
- Tolerance evaluation logic.
- Offline capture and sync logic.

### FEAT-03: Out-of-Tolerance Impact Assessment

- Impact assessment engine integration (Azure Functions).
- Measurement history query and result presentation.
- Partial result handling and certificate block logic.
- Foundry agent workflow for narrative draft and review.

### FEAT-04: Certificate Generation and Traceability

- Certificate rendering from calibration record.
- Reference standard chain inclusion.
- Blob storage integration for immutable certificate storage.
- Competency check via training records API.
- Certificate issue logging and audit trail.

---

## 4. Acceptance Criteria (Traceable)

- All user stories’ acceptance criteria are mapped to UI elements and backend logic.
- UX mockups (SCR-01 to SCR-04) are referenced for UI/interaction validation.
- Technical requirements (API, storage, identity, offline, etc.) are mapped to tasks and test cases.
- Non-functional requirements (NFRs) such as offline support, accessibility, and auditability are explicitly covered.

---

## 5. Dependencies

- Integration with Quality Management System (instrument master, procedures).
- Integration with Manufacturing Execution System (measurement history).
- Integration with Training Records System (competency check).
- Azure SQL Database and Blob Storage provisioning.
- Microsoft Foundry agent workflow and APIM configuration.
- Device management (Intune compliance for calibration devices).
- GitHub Actions for CI/CD.

---

## 6. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Source system unavailability (QMS, MES) | Incomplete data, blocked certificate issue | Implement retry/backoff, explicit partial/incomplete state, cache with age warning |
| Offline capture sync failures | Data loss or delayed compliance | Service worker with robust sync logic, user feedback on sync state |
| Competency data not up-to-date | Unqualified certificate issue | Server-side check at issue time, audit log, fallback to manual override with justification |
| Reference standard out of calibration | Invalid calibration | Enforce selection logic, block calibration, clear error messaging |
| Accessibility non-compliance | Exclusion of users, audit findings | Follow UX accessibility specs, test with assistive tech, WCAG 2.1 AA compliance |
| Immutable storage misconfiguration | Certificate loss or alteration | Automated tests for storage configuration, periodic audit of Blob immutability |

---

## 7. Traceability Matrix (Sample)

| Requirement/User Story | Feature | UX Mockup | Technical Requirement | Acceptance Criteria |
|-----------------------|---------|-----------|----------------------|--------------------|
| US-101                | FEAT-01 | SCR-01    | QMS integration, UI  | Due/overdue list, notification |
| US-201                | FEAT-02 | SCR-02    | Procedure API, UI    | Guided capture, as-found lock |
| US-301                | FEAT-03 | SCR-03    | MES integration, agent workflow | Impact list, partial handling |
| US-401                | FEAT-04 | SCR-04    | Blob storage, competency API | Certificate, traceability, immutability |

---

## 8. Approval Gates

- **Business owner sign-off** on feature set and priorities.
- **UX review** for accessibility and workflow.
- **Technical architecture review** for integration and security.
- **Data protection review** for certificate storage and auditability.

---

## 9. Next Steps

- Review and approve this proposal.
- Decompose features into sprint-ready stories and tasks.
- Confirm integration points and test data.
- Schedule UX walkthrough and technical architecture review.

---

**End of Plan Stage Proposal**  
*All content traceable to approved requirements, technical constraints, and UX mockups. Awaiting review and approval before decomposition and implementation.*