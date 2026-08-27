# Requirements Agent — Plan-Stage Reviewable Proposal

**Project:** Equipment Calibration Compliance  
**Target environment:** Dev  
**Plan status:** Proposed for review  
**Source status:** Intake documents are marked **Draft**; no approved artifacts were provided.  
**Approval required before implementation:** Business owner, Quality/Metrology owner, Technical owner, Security/Compliance owner, and UX representative.

> This proposal is derived from the supplied requirements, technical-requirements, and UX documents. Sections of the source documents were truncated in the supplied content; unresolved items are explicitly identified rather than inferred as approved requirements.

---

## 1. Proposed outcome

Deliver a calibration-compliance solution that:

1. Shows instruments due or overdue by date, criticality, and location.
2. Blocks overdue instruments from being issued for use.
3. Guides technicians through the approved procedure for an instrument.
4. Captures immutable as-found readings before as-left readings.
5. Automatically evaluates readings against tolerance.
6. Determines the measurement, work-order, and lot impact of an out-of-tolerance instrument.
7. Prevents certificate issue when impact data is incomplete, procedure data is potentially stale, or competency cannot be verified.
8. Generates a traceable certificate from the stored calibration record.
9. Supports offline capture and synchronization after reconnection.
10. Uses the Microsoft Agent Framework only for a draft impact narrative and summary; the deterministic impact list remains authoritative and a quality engineer must approve the narrative.

---

## 2. Proposed scope and boundaries

### In scope

- Calibration scheduling based on interval and actual usage.
- Due and overdue visibility by instrument and location.
- Tool-crib issue blocking for overdue instruments.
- Quality-manager extensions with expiry, justification, and approver identity.
- Guided procedure execution.
- Reference-standard validity checking.
- Environmental-condition capture.
- As-found and as-left readings at each test point.
- Tolerance evaluation.
- Out-of-tolerance impact assessment.
- Quality-engineer disposition recording.
- Certificate generation and issue.
- Reference-standard traceability.
- Immutable calibration record and issued certificate storage.
- Offline capture and synchronization.
- Existing quality-management-system, manufacturing-execution-system, and training-record integrations.
- Impact narrative drafting through Microsoft Foundry via Azure API Management.

### Out of scope

- Instrument procurement, capitalization, and disposal.
- External calibration-house repair/refurbishment work.
- Measurement systems analysis, including Gage R&R.
- Product disposition decisions themselves; the quality function remains accountable.
- New analytics beyond existing calibration-compliance dashboards.

---

## 3. Proposed epic and feature structure

| ID | Type | Proposed title | Traceability |
|---|---|---|---|
| EPIC-01 | Epic | Equipment Calibration Compliance | Requirements §2; success measures |
| FEAT-01 | Feature | Calibration Scheduling and Due Management | Requirements §3.1; SCR-01 |
| FEAT-02 | Feature | Guided Calibration Capture | Requirements §3.2; SCR-02 |
| FEAT-03 | Feature | Out-of-Tolerance Impact Assessment | Requirements §3.3; SCR-03 |
| FEAT-04 | Feature | Certificate and Traceability | UX SCR-04; technical architecture |
| FEAT-05 | Feature | Offline Capture and Synchronization | Scope; technical constraints |
| FEAT-06 | Feature | Identity, Competency, Audit, and Controls | Technical requirements |
| FEAT-07 | Feature | Platform Integrations and Operations | Technical requirements |

---

# 4. Proposed user stories

## FEAT-01 — Calibration Scheduling and Due Management

### US-101 — Prioritized due list

**As a** metrology technician,  
**I want** instruments due for calibration ranked by due date and criticality,  
**so that** I work the schedule in the order that protects product quality.

**Acceptance criteria**

- Given instruments with valid calibration intervals, when the due list loads, then instruments are sorted by days to due and then by criticality.
- Each row displays instrument identifier, description, location, interval, last calibration date, next due date, and criticality.
- Users can filter by All Due, Overdue, and My Location.
- The selected filter is announced accessibly and the scroll position is retained when filtering.
- An empty result identifies the active filter and provides a route back to All Due.
- Quality managers can view all sites; technicians are restricted to their authorized location view.

**Source:** Requirements US-101; UX SCR-01.

### US-102 — Overdue issue block

**As a** production supervisor,  
**I want** an overdue instrument blocked from being drawn for use,  
**so that** measurements are not taken with an uncalibrated device.

**Acceptance criteria**

- Given an instrument is overdue, when it is scanned at the tool crib, then issue is blocked.
- The block displays the due date, number of days overdue, and reason.
- The overdue state is represented as text and not by colour alone.
- An instrument remains overdue until a passing calibration or an active approved extension is recorded.
- A quality manager can record an extension only with expiry, justification, and approver identity.
- An expired extension immediately returns the instrument to overdue status.
- The issue-block decision is enforced server-side, not only in the client.

**Source:** Requirements US-102; UX SCR-01.

### Proposed additional story US-103 — Schedule calculation

**As a** quality manager,  
**I want** due dates calculated from the approved interval and applicable usage information,  
**so that** the due register reflects the governing calibration policy.

**Acceptance criteria**

- The system records the interval and source used for each next-due calculation.
- Actual usage data, when applicable, is attributable to its source and retrieval time.
- A failed or unavailable source does not silently produce a current due date.
- Changes to schedule inputs are auditable.

**Open decision:** Exact interval/usage algorithm and authoritative source are not specified in the supplied requirements.

---

## FEAT-02 — Guided Calibration Capture

### US-201 — Approved procedure presentation

**As a** metrology technician,  
**I want** the approved test points and tolerances presented in sequence,  
**so that** I follow the procedure rather than working from memory.

**Acceptance criteria**

- Scanning or selecting an instrument opens the applicable approved procedure.
- The screen shows procedure identifier, revision, test-point sequence, nominal values, tolerances, and required reference standard.
- The procedure revision used by the calibration is stored with the record.
- A reference standard that is out of calibration cannot be selected.
- The reason a standard is ineligible is displayed to the technician.
- If the quality-management system cannot confirm the current procedure revision, certificate issue is blocked.

**Source:** Requirements US-201; UX SCR-02; technical integration constraints.

### US-202 — Immutable as-found capture

**As a** quality engineer,  
**I want** as-found readings captured before adjustment,  
**so that** the instrument’s condition during production use is recorded honestly.

**Acceptance criteria**

- As-found readings must be entered before as-left readings become available.
- Each committed as-found value is immutable to the technician and all other users.
- A correction requires a documented exception or a new calibration record; the original value is retained.
- Each reading records test point, value, unit, timestamp, actor, and calibration identifier.
- An out-of-tolerance as-found value causes the calibration to be flagged as failed regardless of the as-left result.
- The result is shown in words such as “In tolerance” or “Out of tolerance” and is announced accessibly.

**Source:** Requirements US-202; UX SCR-02; technical constraints.

### Proposed US-203 — As-left capture and calibration outcome

**As a** metrology technician,  
**I want** to capture as-left readings after adjustment,  
**so that** the final calibration condition is recorded.

**Acceptance criteria**

- As-left entry is unavailable until all required as-found entries are committed.
- Each as-left value is evaluated against the applicable tolerance.
- The final outcome identifies whether the instrument passed or failed and why.
- The system does not overwrite as-found results with as-left results.
- Submission requires all mandatory test points, environmental values, and reference-standard details.

### Proposed US-204 — Environmental and reference traceability

**As a** metrology technician,  
**I want** environmental conditions and reference-standard details captured with the calibration,  
**so that** the calibration is reproducible and auditable.

**Acceptance criteria**

- Temperature and humidity can be recorded where required by the procedure.
- The selected reference standard, certificate number, calibration validity, and identity are stored.
- The system prevents submission if a required traceability field is absent.
- Any environmental evidence attachment is associated with the calibration record.

---

## FEAT-03 — Out-of-Tolerance Impact Assessment

### Proposed US-301 — Deterministic impact list

**As a** quality engineer,  
**I want** every measurement taken with a failed instrument since its last passing calibration identified,  
**so that** I can decide what to do about affected product.

**Acceptance criteria**

- When an as-found result is out of tolerance, the system identifies the last passing calibration.
- The engine queries manufacturing-execution measurement history for the applicable time range.
- The result includes, where available, measurement, instrument, timestamp, work order, lot, product, and source-system identifiers.
- The impact list is generated deterministically and is separate from any AI-generated narrative.
- The query boundaries and execution timestamps are stored.
- No result is presented as complete when the measurement-history query has failed, timed out, or returned an explicitly incomplete range.

### Proposed US-302 — Incomplete impact handling

**As a** quality engineer,  
**I want** incomplete impact results clearly identified,  
**so that** I do not mistake a partial result for a complete assessment.

**Acceptance criteria**

- If the manufacturing-execution integration is unavailable after the defined retries, the impact list is labelled **Partial / Incomplete**.
- The screen explains the missing source or range and provides retry status.
- Certificate issue remains blocked while the impact assessment is incomplete.
- The system records the failure, retry attempts, correlation ID, and user-visible status.
- A quality engineer cannot mark an incomplete assessment complete without an explicit approved exception path, if such a path is authorized.

### Proposed US-303 — Impact decisions and dispositions

**As a** quality engineer,  
**I want** to record impact decisions for identified measurements, work orders, and lots,  
**so that** the quality function owns the product-impact decision.

**Acceptance criteria**

- The engineer can record a disposition or decision against each applicable impact item or defined group.
- Each decision requires actor, timestamp, rationale, and status.
- Product disposition remains a quality decision and is not automatically made by the model.
- Changes to decisions are auditable.
- The assessment cannot be closed until all required impact items have a recorded decision or an approved exception.

### Proposed US-304 — Reviewed AI narrative

**As a** quality engineer,  
**I want** a draft impact summary and narrative,  
**so that** I can review the scope efficiently while retaining accountability for the assessment.

**Acceptance criteria**

- The agent receives only the authorized assessment data needed to draft the narrative.
- All model traffic is routed through Azure API Management.
- The generated narrative is visibly labelled as a draft.
- The workflow pauses for quality-engineer review before the narrative is attached to the assessment.
- The engineer can accept, edit, or reject the draft.
- The approved narrative records reviewer identity, timestamp, model/workflow correlation ID, and the underlying deterministic impact-list reference.
- The model cannot alter the deterministic impact list or record product disposition.
- If model execution fails, the assessment remains usable with the deterministic list and a clear “narrative unavailable” state.

**Source:** Technical requirements §1–3.

---

## FEAT-04 — Certificate and Traceability

### Proposed US-401 — Certificate generated from record

**As a** metrology technician,  
**I want** a certificate generated from the stored calibration record,  
**so that** the issued certificate does not require manual transcription.

**Acceptance criteria**

- The certificate is generated from the persisted calibration data.
- It includes instrument identity, calibration outcome, procedure and revision, readings, tolerances, environmental data where required, reference-standard traceability, actor, and issue timestamp.
- Manually retyping record values is not required.
- The generated certificate is linked to the calibration record and issue log.
- Certificate generation failure does not create an apparently issued certificate.

### Proposed US-402 — Competency-gated certificate issue

**As a** quality or metrology process owner,  
**I want** certificate issue restricted to a competent named person,  
**so that** the certificate represents an accredited act.

**Acceptance criteria**

- The server verifies the user’s identity through Microsoft Entra ID.
- The server evaluates calibration competency using the training-records system.
- A user without current required competency cannot issue a certificate.
- The issue action records named issuer, competency-check result, timestamp, and calibration identifier.
- Client-side role checks alone are insufficient.
- The certificate cannot be issued if procedure validity, impact completeness, or required traceability is unresolved.

### Proposed US-403 — Immutable certificate storage

**As a** quality auditor,  
**I want** issued certificates and supporting evidence stored immutably,  
**so that** records remain provably unaltered for the retention period.

**Acceptance criteria**

- Issued certificates are stored in Azure Blob Storage with immutability controls.
- Issued certificates cannot be edited or replaced through the application.
- Certificates are retained for 10 years, subject to approved retention policy.
- Retrieval provides the original record linkage and integrity evidence.
- Environmental evidence, when required, is retained with the same calibration reference.

---

## FEAT-05 — Offline Capture and Synchronization

### Proposed US-501 — Offline calibration capture

**As a** metrology technician,  
**I want** to capture calibration data without continuous connectivity,  
**so that** work can continue on the shop floor or in the laboratory.

**Acceptance criteria**

- The client can display an explicitly identified cached procedure when offline.
- The cache displays its age and source revision.
- Offline capture preserves the sequence, validation, as-found lock, and local audit information.
- The client clearly indicates which data is pending synchronization.
- Offline mode cannot falsely indicate that a certificate has been issued.

### Proposed US-502 — Reconnection synchronization

**As a** metrology technician,  
**I want** locally captured records synchronized when connectivity returns,  
**so that** the system of record is updated without data loss.

**Acceptance criteria**

- Synchronization is retryable and idempotent.
- Conflicts are detected and presented for resolution; they are not silently overwritten.
- The system records synchronization status, attempt time, outcome, and error details.
- A calibration requiring current procedure validation or complete impact assessment remains blocked from certificate issue until server-side checks succeed.
- Duplicate records are not created after retry.

---

## FEAT-06 — Identity, Competency, Audit, and Controls

### Proposed US-601 — Role and location access

- Entra ID authentication is required.
- Conditional access requires an Intune-compliant device where configured.
- Technicians, supervisors, quality engineers, and quality managers receive only the permissions approved for their role and site.
- Authorization is enforced by the service layer.

### Proposed US-602 — Complete audit trail

The audit trail should cover:

- Calibration creation and submission.
- As-found commitment and any exception handling.
- Procedure and revision used.
- Reference standard selection.
- Extensions and approvals.
- Impact query parameters and results status.
- AI draft, review, edit, acceptance, or rejection.
- Certificate generation and issue.
- Synchronization and integration failures.

---

## FEAT-07 — Platform Integrations and Operations

### Proposed US-701 — Quality-management-system integration

- Use REST over HTTPS with managed identity and OAuth 2.0 client credentials.
- Apply the specified 2-second timeout and three retries with backoff.
- On exhaustion, serve cached procedure data with age clearly shown.
- Block certificate issue against potentially superseded procedure data.

### Proposed US-702 — Manufacturing-execution integration

- Use managed identity.
- Apply the 20-second range-query timeout and two retries.
- On exhaustion, explicitly label the impact list partial/incomplete.
- Keep certificate issue blocked until completeness is established.

### Proposed US-703 — Training-records competency integration

- Verify competency server-side before certificate issue.
- Handle unavailable or stale competency data as a certificate-blocking condition unless an approved exception policy exists.
- Record the competency source and check time.

### US-704 — AI gateway enforcement

- Route all model calls through the single APIM route.
- Use managed identity, per-user quotas, content safety, and correlation headers.
- Do not permit direct client-to-model traffic.
- Capture model-use observability data without exposing secrets.

---

# 5. Proposed implementation tasks

## Foundation and architecture

- **TASK-001:** Confirm and baseline the domain model for instruments, procedures, calibrations, test points, readings, standards, impact items, decisions, certificates, and audit events.
- **TASK-002:** Define calibration state transitions, including draft, in progress, submitted, passed, failed, impact incomplete, impact reviewed, and certificate issued.
- **TASK-003:** Define API contracts and error semantics for all external integrations.
- **TASK-004:** Establish correlation-ID propagation across client, FastAPI, Functions, APIM, Foundry workflow, and external systems.
- **TASK-005:** Create Azure SQL schema, indexes, retention strategy, and migration process.
- **TASK-006:** Configure Blob Storage immutability and certificate retention policy.
- **TASK-007:** Establish App Service, Azure Functions, APIM, identity, and Dev environment configuration using managed identities.

## Client

- **TASK-101:** Implement SCR-01 due list, filtering, sorting, role/location visibility, and offline state.
- **TASK-102:** Implement SCR-02 guided calibration flow and one-test-point-at-a-time interaction.
- **TASK-103:** Implement as-found lock and accessible tolerance-result announcements.
- **TASK-104:** Implement SCR-03 impact review with complete/partial/incomplete states.
- **TASK-105:** Implement SCR-04 certificate and traceability view.
- **TASK-106:** Implement local offline store, pending-sync indicators, retry, and conflict presentation.
- **TASK-107:** Complete accessibility verification for text alternatives, focus order, keyboard use, touch targets, and screen-reader announcements.

## Services and domain logic

- **TASK-201:** Implement due-date and overdue evaluation.
- **TASK-202:** Implement server-side issue blocking and extension authorization.
- **TASK-203:** Implement procedure and reference-standard validity checks.
- **TASK-204:** Implement immutable as-found persistence and tolerance evaluation.
- **TASK-205:** Implement impact-assessment engine and explicit completeness status.
- **TASK-206:** Implement quality-engineer impact decisions and audit events.
- **TASK-207:** Implement competency enforcement.
- **TASK-208:** Implement certificate generation from persisted records.
- **TASK-209:** Implement certificate issue log and immutable storage integration.
- **TASK-210:** Implement idempotent synchronization endpoints.

## Agent workflow

- **TASK-301:** Define the structured input contract for the impact-summary agent.
- **TASK-302:** Implement the Microsoft Agent Framework workflow through APIM to Foundry.
- **TASK-303:** Add the mandatory pause for quality-engineer review.
- **TASK-304:** Prevent the agent from modifying impact-list facts or recording dispositions.
- **TASK-305:** Store draft, approved, edited, and rejected narrative versions with reviewer and correlation metadata.
- **TASK-306:** Test model timeout, refusal, malformed output, unavailable APIM, and unavailable Foundry behavior.

## Integration, security, and quality

- **TASK-401:** Build QMS adapter with timeout, retry, cache-age, and stale-procedure handling.
- **TASK-402:** Build MES adapter with range-query completeness checks.
- **TASK-403:** Build training-records competency adapter.
- **TASK-404:** Configure Entra ID, conditional access, role mapping, and server-side authorization.
- **TASK-405:** Implement audit logging and operational dashboards.
- **TASK-406:** Add unit, integration, contract, offline-sync, accessibility, security, and end-to-end tests.
- **TASK-407:** Validate Dev deployment through protected GitHub Actions workflows with build provenance.
- **TASK-408:** Conduct pilot acceptance with technicians, quality engineers, supervisors, and auditors.

---

# 6. Cross-cutting acceptance criteria

The release should not be considered ready for business acceptance unless:

- No certificate can be issued without a valid, attributable competent issuer.
- No as-found reading can be edited after commitment.
- No certificate can be issued against an unresolved or potentially superseded procedure revision.
- No incomplete impact query is presented as complete.
- The deterministic impact list is distinguishable from the AI-generated narrative.
- AI output is reviewed and approved by a quality engineer before attachment.
- All model traffic uses APIM.
- All issued certificates are stored immutably.
- Offline operation cannot create a false issued-certificate state.
- All critical actions are auditable.
- The target metrics can be measured from system records:
  - Instruments overdue: under 1%.
  - Median impact-list production time: 10 minutes or less.
  - Certificates generated without manual transcription: 100%.
  - Unbroken reference-standard chain: 100% of sampled calibrations.

---

# 7. Proposed dependencies

| Dependency | Direction | Required for |
|---|---|---|
| Quality-management system instrument master and procedure APIs | External | Scheduling, procedure selection, validity checks |
| Manufacturing-execution measurement-history API | External | Impact assessment |
| Training-records competency API | External | Certificate issue authorization |
| Microsoft Entra ID and Intune compliance | Platform | Authentication and device policy |
| Azure SQL Database | Platform | Calibration and assessment records |
| Azure Blob Storage immutability | Platform | Certificate and evidence retention |
| Azure App Service and Azure Functions | Platform | Service and processing components |
| Azure API Management | Platform | All model traffic and observability |
| Microsoft Foundry and Microsoft Agent Framework | Platform | Draft impact narrative |
| Barcode/scanner capability | Device | Instrument and standard identification |
| Offline storage and device security | Client/platform | Shop-floor and laboratory operation |
| Existing compliance dashboard | External/operational | Success-measure comparison |

---

# 8. Key risks and mitigations

| Risk | Impact | Proposed mitigation |
|---|---|---|
| Source documents are draft and incomplete | Scope or acceptance ambiguity | Obtain formal approval and complete missing sections before build authorization |
| QMS procedure data is stale or unavailable | Invalid calibration or certificate | Cache with visible age; block certificate issue when current revision is unverified |
| MES history is incomplete or unavailable | Missed product impact | Explicit partial status; block certificate issue; retain query diagnostics |
| Usage-based scheduling rules are undefined | Incorrect due dates | Approve calculation policy and authoritative usage source |
| Offline data conflicts after reconnection | Duplicate or altered records | Idempotency keys, conflict detection, server-side validation |
| As-found immutability is implemented only in UI | Record-integrity failure | Enforce immutability in API and database rules |
| Competency data is stale or unavailable | Unauthorized certificate issue | Server-side check and fail-closed behavior |
| AI narrative is mistaken for authoritative analysis | Incorrect quality decision | Keep deterministic list authoritative; label draft; mandatory human review |
| Model output contains unsupported claims | Audit or quality risk | Structured input, grounding to impact records, reviewer approval, provenance |
| Certificate storage is mutable or retention is misconfigured | Compliance failure | Configure immutable Blob policy and verify restore/retrieval tests |
| Device or scanner limitations affect shop-floor use | Adoption and data quality issues | Pilot on target devices, test gloved operation and intermittent connectivity |
| Performance targets are not met | Failure to achieve business outcome | Establish performance tests for due list, impact queries, and certificate generation |
| Existing dashboards may not expose required metrics | Success cannot be measured | Define telemetry and reporting fields before implementation |

---

# 9. Open decisions and clarification requests

These items require resolution before stories can be baselined:

1. **Requirements completeness:** The supplied requirements and technical documents are truncated. Provide the remaining sections, particularly:
   - FEAT-03 and FEAT-04 source stories.
   - Full non-functional requirements.
   - Full integration requirements.
   - Full UX interaction specifications.
   - Traceability matrix and assumptions.
2. **Scheduling algorithm:** Define exactly how interval and actual usage combine, including precedence, reset rules, and exceptions.
3. **Overdue extension policy:** Define who may approve extensions, maximum duration, allowed reasons, and whether extensions require additional controls.
4. **Last passing calibration:** Define whether “passing” means a passing as-found result, passing as-left result, or another approved status.
5. **Impact scope:** Define treatment of missing, duplicate, corrected, or late-arriving MES measurements.
6. **Product-impact decisions:** Define required disposition statuses and whether decisions are recorded per measurement, work order, lot, or another unit.
7. **Certificate format:** Confirm required fields, numbering, signature requirements, locale, and regulatory format.
8. **Retention policy:** Confirm whether 10 years applies to all calibration evidence, audit events, drafts, and rejected AI narratives.
9. **Offline boundaries:** Define how long procedures may be cached and whether offline calibration may be submitted without current server validation.
10. **Competency rules:** Identify required competencies, expiry behavior, grace periods, and training-system failure behavior.
11. **NFR baselines:** NFR-001, NFR-003, and NFR-006 are referenced by UX but their definitions were not supplied. All NFR IDs and measurable targets are needed.
12. **AI governance:** Confirm approved model, data classification, prompt/content controls, retention, and whether generated narrative may leave the tenant through any service.
13. **Role model:** Confirm exact permissions for technician, supervisor, quality engineer, quality manager, auditor, and administrator.
14. **Device support:** Confirm supported Android versions, tablet/handheld models, scanner integration, and MDM policy.
15. **Dev environment:** Confirm whether Dev uses production-like integration endpoints, synthetic data, or approved test doubles.

---

# 10. Proposed traceability summary

| Business outcome / requirement | Proposed implementation |
|---|---|
| Keep instruments in calibration | FEAT-01, US-101–US-103, TASK-201–202 |
| Block overdue use | US-102, server-side issue-control service |
| Capture true as-found condition | FEAT-02, US-202, TASK-203–204 |
| Follow approved procedure | US-201, QMS integration, procedure revision persistence |
| Identify affected product quickly | FEAT-03, US-301–US-304, TASK-205–306 |
| Keep product disposition with Quality | US-303 |
| Generate certificates from records | FEAT-04, US-401–US-403, TASK-208–209 |
| Prove reference-standard traceability | US-204, US-401, US-403 |
| Support shop-floor offline operation | FEAT-05, US-501–US-502, TASK-106, TASK-210 |
| Protect accredited certificate issue | US-402, FEAT-06, Entra/training integration |
| Govern model use | US-304, US-704, TASK-301–306 |

---

## Recommendation

**Proceed to requirements clarification and architecture refinement, not implementation approval yet.** The overall direction is coherent and technically feasible, but the plan should remain provisional until the truncated source sections and the open decisions—especially scheduling, impact completeness, certificate policy, NFRs, and competency behavior—are approved.