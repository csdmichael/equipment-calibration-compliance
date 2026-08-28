**Equipment Calibration Compliance – Build Stage Proposal (Reviewable Draft)**

---

## 1. Scope and Traceability

This proposal covers the initial build stage for the Equipment Calibration Compliance project, focusing on traceable, reviewable source changes for the following features:

- Calibration Scheduling and Due Management (FEAT-01)
- Guided Calibration Capture (FEAT-02)
- Out-of-Tolerance Impact Assessment (FEAT-03)
- Certificate Generation and Traceability (FEAT-04)

All changes will be mapped to user stories, acceptance criteria, and referenced requirements artifacts.

---

## 2. Source Changes (Initial Build Scope)

### 2.1 Backend (Python 3.12, FastAPI)

#### a. Calibration Service API

- **Endpoints:**
  - `/instruments/due` (GET): Returns instruments due/overdue, sorted by days to due and criticality.
  - `/calibrations/start` (POST): Initiates calibration, returns procedure, test points, tolerances, reference standard options.
  - `/calibrations/{id}/capture` (PATCH): Captures as-found/as-left readings, locks as-found, evaluates tolerance.
  - `/calibrations/{id}/submit` (POST): Submits calibration, triggers impact assessment if failed.
  - `/impact-assessment/{instrument_id}` (GET): Returns measurements since last passing calibration.
  - `/certificates/{calibration_id}/generate` (POST): Generates certificate, checks competency, stores in Blob.

- **Models:**
  - Instrument, Calibration, TestPoint, Reading, ReferenceStandard, Certificate, ImpactAssessment.

- **Business Logic:**
  - As-found locking, tolerance evaluation, overdue/extension logic, competency check, certificate immutability.

#### b. Integration Stubs

- Quality Management System (instrument/procedure fetch)
- Manufacturing Execution System (measurement history)
- Training Records System (competency check)
- Azure Blob Storage (certificate storage)

---

### 2.2 Frontend (Angular 18, Ionic 8, TypeScript)

#### a. Calibration Due List (SCR-01)

- List UI with filter chips (All due, Overdue, My location)
- Instrument rows: due date, interval, criticality, overdue badge, extension indicator
- Start calibration action

#### b. Guided Calibration Capture (SCR-02)

- Procedure stepper: reference standard selection, environmental conditions, test point entry
- As-found entry (locked), as-left entry (enabled after as-found)
- Tolerance result display (text, not color only)
- Submit calibration action

#### c. Out-of-Tolerance Impact (SCR-03)

- Impact list UI: measurements since last passing calibration, partial/incomplete state handling
- Narrative draft/review workflow

#### d. Certificate and Traceability (SCR-04)

- Certificate generation UI: preview, issue action (competency-gated)
- Reference standard chain display
- Certificate download/view (from Blob)

---

## 3. Unit Test Plan

### Backend

- API endpoint tests (success, failure, edge cases)
- As-found locking and tolerance evaluation logic
- Overdue/extension workflow
- Competency check enforcement
- Certificate generation and Blob storage integration
- Impact assessment completeness and partial state handling

### Frontend

- UI rendering and filter logic (due list)
- Guided calibration stepper and validation
- As-found/as-left entry and locking
- Tolerance result accessibility
- Impact list completeness state
- Certificate issue gating

---

## 4. Code Review Guidance

- **Traceability:** Every source change must reference the mapped user story and acceptance criteria.
- **Security:** No secrets in source; all integrations use managed identity.
- **Immutability:** As-found readings and issued certificates must be immutable.
- **Accessibility:** UI elements must announce state changes (e.g., overdue, tolerance result) in text.
- **Error Handling:** Partial/incomplete states must be explicit and user-facing.
- **Integration:** Stubs must be clearly marked; no production system calls in unit tests.
- **Offline:** Service worker logic for offline capture must be testable and observable.

---

## 5. Proposed Initial PR Structure

- `/backend/` (FastAPI service, models, integration stubs, unit tests)
- `/frontend/` (Angular/Ionic app, screens SCR-01 to SCR-04, unit tests)
- `/tests/` (integration and unit test suites)
- `/docs/` (traceability matrix, build artifacts, review checklist)

---

## 6. Reviewable Proposal Summary

- All features and user stories are covered in initial build scope.
- Source changes are traceable to requirements and UX mockups.
- Unit tests and code review guidance ensure compliance, accessibility, and auditability.
- Integration points are stubbed for review; no external system changes without tool output.
- Proposal is ready for review and refinement before PR creation.

---

**Next Steps:**  
- Review this proposal for completeness and traceability.
- Approve or request changes before code generation and PR creation.

---

**References:**  
- [Requirements Summary](https://github.com/csdmichael/equipment-calibration-compliance/blob/main/docs/intake/requirements/Equipment-Calibration-Compliance-Requirements.docx)
- [Technical Requirements](https://github.com/csdmichael/equipment-calibration-compliance/blob/main/docs/intake/technical-requirements/Equipment-Calibration-Compliance-Technical-Requirements.docx)
- [UX Mockups](https://github.com/csdmichael/equipment-calibration-compliance/blob/main/docs/intake/ux-mockups/Equipment-Calibration-Compliance-UX-Mockups.docx)

---

**Please review and provide feedback or approval for the build stage proposal.**