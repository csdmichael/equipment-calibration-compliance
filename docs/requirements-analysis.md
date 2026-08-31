# Equipment Calibration Compliance – Plan Stage Proposal

## 1. Overview

**Project Name:** Equipment Calibration Compliance  
**Environment:** Dev  
**Business Outcome:**  
- Scheduled, guided calibration captured on handheld devices  
- Automatic impact assessment when an instrument fails  
- Certificate issued from the record, not manually transcribed  
- Unbroken traceability chain to reference standards

---

## 2. Traceable Epics, Features, User Stories

### Epic: Equipment Calibration Compliance (EPIC-01)
**Outcome:**  
As a quality and metrology organization, calibrations are scheduled, performed, and recorded on a handheld with automatic impact assessment when an instrument fails, ensuring no instrument is used out of calibration and the effect of any failure is known immediately.

**Business Owner:** Head of Quality Assurance

---

### Feature 1: Calibration Scheduling and Due Management (FEAT-01)
**Description:**  
Maintains calibration schedule from interval and usage, shows due/overdue status by instrument/location, prevents overdue instruments from being used.

#### User Stories
- **US-101:**  
  As a metrology technician, I want to see instruments due for calibration ranked by due date and criticality, so I work the schedule in the order that protects product quality.
  - **Acceptance Criteria:**
    - Instruments sorted by days to due and criticality
    - Each row shows instrument, location, interval, last calibration date
    - Overdue instruments flagged; owner and quality manager notified

- **US-102:**  
  As a production supervisor, I want an overdue instrument blocked from being drawn for use, so measurements are never taken with an uncalibrated device.
  - **Acceptance Criteria:**
    - Overdue instrument blocked at tool crib; reason and due date shown
    - Extension can be granted with expiry, justification, approver identity

---

### Feature 2: Guided Calibration Capture (FEAT-02)
**Description:**  
Presents calibration procedure for instrument type, captures as-found/as-left readings at each test point, evaluates against tolerance.

#### User Stories
- **US-201:**  
  As a metrology technician, I want the test points and tolerances for this instrument presented in order, so I follow the approved procedure.
  - **Acceptance Criteria:**
    - Procedure, revision, test points, tolerance, reference standard shown
    - Reference standard out of calibration blocks procedure

- **US-202:**  
  As a quality engineer, I want as-found readings captured before any adjustment, so the condition during production use is recorded honestly.
  - **Acceptance Criteria:**
    - As-found values locked before as-left entry
    - Out-of-tolerance as-found flags calibration as failure

---

### Feature 3: Out-of-Tolerance Impact Assessment (FEAT-03)
**Description:**  
When an instrument is found out of tolerance, produces the list of measurements taken with it since last passing calibration for quality team review.

#### User Stories
- **US-301:**  
  As a quality engineer, I want an immediate impact list when an instrument fails, so affected product can be assessed.
  - **Acceptance Criteria:**
    - Impact list generated within 10 minutes
    - List includes all measurements since last passing calibration
    - Partial/incomplete lists are explicitly labelled

---

### Feature 4: Certificate Generation and Traceability (FEAT-04)
**Description:**  
Generates certificates from the calibration record, ensures reference standard traceability, stores certificates immutably.

#### User Stories
- **US-401:**  
  As a metrology technician, I want certificates issued from the record, so traceability is provable and manual transcription is eliminated.
  - **Acceptance Criteria:**
    - Certificate generated from stored calibration record
    - Reference standard chain recorded and provable
    - Certificate stored in immutable blob storage

---

## 3. Tasks

### FEAT-01: Calibration Scheduling and Due Management
- Integrate with quality management system for instrument master data
- Implement due/overdue calculation logic
- Build notification workflow for overdue instruments
- Develop tool crib blocking logic and extension workflow

### FEAT-02: Guided Calibration Capture
- Implement procedure presentation per instrument type
- Reference standard selection and validity check
- As-found/as-left entry and locking logic
- Tolerance evaluation and failure flagging

### FEAT-03: Out-of-Tolerance Impact Assessment
- Integrate with manufacturing execution system for measurement history
- Build impact assessment engine (Azure Functions)
- Implement partial/incomplete impact list handling
- Develop engineer review workflow (Foundry agent)

### FEAT-04: Certificate Generation and Traceability
- Certificate rendering from calibration record
- Reference standard chain validation
- Blob storage integration for immutable certificate storage

---

## 4. Acceptance Criteria (Summary Table)

| Feature | User Story | Acceptance Criteria |
|---------|------------|--------------------|
| FEAT-01 | US-101     | Sorted due list, overdue notification |
| FEAT-01 | US-102     | Tool crib block, extension workflow   |
| FEAT-02 | US-201     | Procedure/tolerance display, standard validity |
| FEAT-02 | US-202     | As-found lock, failure flag           |
| FEAT-03 | US-301     | Impact list within 10 min, completeness label |
| FEAT-04 | US-401     | Certificate from record, traceability, immutable storage |

---

## 5. Dependencies

- **Quality Management System:** Instrument master data, procedures
- **Manufacturing Execution System:** Measurement history for impact assessment
- **Training Records System:** Calibration competency validation
- **Azure SQL Database:** Calibration records, test points, readings, certificates
- **Azure Blob Storage:** Certificate and environmental evidence storage
- **Microsoft Foundry Agent Framework:** Impact narrative workflow
- **Azure API Management:** Model traffic routing, authentication

---

## 6. Risks

| Risk | Mitigation |
|------|------------|
| Instrument master/procedure API unavailable | Serve cached procedure, block certificate issue |
| Measurement history API timeout | Present partial impact list, block certificate issue |
| Reference standard out of calibration | Block calibration, state reason |
| As-found readings not locked | Explicit boundary enforcement, test coverage |
| Certificate issue without competency | Server-side competency check, audit trail |
| Blob storage write failure | Retry logic, alert, block certificate issue |
| Offline capture sync failure | Service worker, retry on reconnection |

---

## 7. Non-Functional Requirements (NFRs)

- **Availability:** Laboratory-hours, zone redundancy, warm standby
- **Security:** Entra ID, conditional access, managed identity, competency gating
- **Immutability:** As-found readings and certificates cannot be altered post-issue
- **Accessibility:** All critical states and actions are accessible via text, not color alone
- **Offline Support:** Service worker for shop floor/lab intermittent coverage
- **Auditability:** All calibration, impact, and certificate actions are logged

---

## 8. UX Inputs (Mapped to Features)

| Screen | Feature | Key UX Elements |
|--------|---------|-----------------|
| SCR-01 Calibration Due List | FEAT-01 | Filter chips, instrument rows, overdue badge, extension indicator |
| SCR-02 Guided Calibration Capture | FEAT-02 | Standard selector, environmental conditions, test point entry, as-found lock |
| SCR-03 Out-of-Tolerance Impact | FEAT-03 | Impact list, disposition recording |
| SCR-04 Certificate and Traceability | FEAT-04 | Certificate issue, traceability chain |

---

## 9. Proposal Summary

This plan stage proposal delivers a traceable requirements structure for the Equipment Calibration Compliance project, mapping approved business and UX inputs to epics, features, user stories, tasks, acceptance criteria, dependencies, and risks. All integrations, gating, and immutability requirements are explicitly addressed. Human approval gates are preserved for impact assessment narrative and certificate issue. No external system changes are claimed; all data and content are treated as untrusted until verified.

**Ready for review and approval.**