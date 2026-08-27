# Requirements Agent — Plan-Stage Proposal

**Project:** Equipment Calibration Compliance  
**Target environment:** Dev  
**Plan status:** Proposed for review; not approved for implementation  
**Source status:** Intake documents are marked **Draft v1.0** dated 24 August 2026. `approvedArtifacts` is empty. Human review and approval are required before downstream design or code-generation gates.

---

## 1. Executive proposal

Deliver a calibration-compliance solution consisting of:

1. A due and overdue calibration worklist.
2. Guided, procedure-driven calibration capture on tablet and handheld.
3. Immutable as-found readings and immediate tolerance evaluation.
4. Deterministic out-of-tolerance impact assessment using manufacturing measurement history.
5. Quality-engineer review and disposition recording.
6. Certificate generation from the stored calibration record.
7. Reference-standard traceability.
8. Offline capture with controlled synchronization.
9. A Foundry/Microsoft Agent Framework workflow that drafts—not decides—the impact narrative.
10. Auditability, competency enforcement, and immutable certificate storage.

The system should own calibration records, impact assessments, and certificates. The quality management system remains the source for instrument master data and procedures; the manufacturing execution system remains the source for measurement history.

---

## 2. Scope boundaries

### In scope

- Scheduling by calibration interval and actual usage.
- Due and overdue visibility by instrument and location.
- Blocking overdue instruments from issue.
- Documented quality-manager extensions.
- Procedure-specific guided capture.
- As-found and as-left values at every test point.
- Tolerance evaluation.
- Environmental conditions.
- Reference-standard validity and traceability.
- Automatic impact assessment after failure.
- Explicit handling of partial or incomplete impact results.
- Quality review and disposition recording.
- Certificate generation from the calibration record.
- Immutable issued certificates and evidence.
- Offline capture and synchronization.
- Existing compliance dashboards, where integration is available.

### Out of scope

- Procurement, capitalization, or disposal.
- External calibration-house repair or refurbishment workflows.
- Measurement systems analysis, including GR&R.
- Product disposition decisions; the quality function remains accountable.
- New analytics beyond dashboards already in service.

### Proposed release boundary

The first release should prioritize the end-to-end compliance path:

> Due instrument → guided calibration → pass/fail → impact assessment if failed → quality review → certificate issue.

Usage-based scheduling, offline conflict handling, and integrations should be validated early because they are material to the release outcome.

---

## 3. Proposed epic and feature decomposition

| ID | Type | Title | Outcome |
|---|---|---|---|
| EPIC-01 | Epic | Equipment Calibration Compliance | Ensure calibration is scheduled, performed, assessed, and recorded with immediate traceability when failures occur. |
| FEAT-01 | Feature | Calibration Scheduling and Due Management | Provide an actionable due list and prevent overdue instruments from being used. |
| FEAT-02 | Feature | Guided Calibration Capture | Capture approved-procedure readings, conditions, and traceability data with immutable as-found values. |
| FEAT-03 | Feature | Out-of-Tolerance Impact Assessment | Identify measurements potentially affected by a failed instrument and expose completeness status. |
| FEAT-04 | Feature | Certificate and Traceability | Generate an attributable certificate from the stored calibration record and preserve its evidence. |
| FEAT-05 | Feature | Offline Capture and Synchronization | Support shop-floor and laboratory work during intermittent connectivity. |
| FEAT-06 | Feature | Identity, Competency, and Auditability | Enforce role, competency, attribution, and audit requirements. |
| FEAT-07 | Feature | Impact Narrative Review Workflow | Produce a model-drafted summary for quality-engineer review without allowing AI to make the impact decision. |

---

# 4. Features, user stories, and acceptance criteria

## FEAT-01 — Calibration Scheduling and Due Management

### US-101 — Prioritized due list

**As a** metrology technician,  
**I want** instruments due for calibration ranked by due date and criticality,  
**so that** I work in the order that best protects product quality.

**Acceptance criteria**

- Given instruments have calibration intervals and due dates, when the due list loads, then instruments are sorted by days to due and then by criticality.
- Each row displays instrument identifier, description, location, interval, last calibration date, next due date, and criticality.
- The list supports the proposed filters: All due, Overdue, and My location.
- An empty filtered result identifies the active filter and offers a route back to the full list.
- Quality managers can view all sites; technicians are restricted to their permitted location scope.
- The list indicates when the client is offline and identifies the data freshness timestamp.

### US-102 — Overdue instrument blocking

**As a** production supervisor,  
**I want** an overdue instrument blocked from being issued,  
**so that** measurements are not knowingly taken with an uncalibrated device.

**Acceptance criteria**

- Given an instrument is overdue, when it is scanned at the tool crib, then issue is blocked.
- The block displays the instrument, due date, days overdue, and reason.
- A passing calibration removes the overdue state.
- A quality-manager extension includes expiry, justification, approver identity, and audit timestamp.
- An expired extension immediately returns the instrument to overdue status.
- A client cannot bypass the block while offline unless an explicitly approved offline policy exists. This policy is currently **TBD**.

### US-103 — Scheduling from interval and usage

**As a** quality manager,  
**I want** due dates calculated from approved interval and usage rules,  
**so that** the schedule reflects both elapsed time and actual use.

**Acceptance criteria**

- The calculation records the interval, usage input, effective date, and source.
- A change to the governing interval or usage rule is versioned and auditable.
- The next due date is recalculated only by an authorized rule or approved action.
- The system identifies missing or stale usage data rather than silently calculating an unreliable date.

**Note:** The source requirements state interval and actual usage scheduling but do not define the usage event, formula, precedence, or source interface. These require confirmation.

---

## FEAT-02 — Guided Calibration Capture

### US-201 — Procedure-driven test sequence

**As a** metrology technician,  
**I want** the approved test points and tolerances presented in order,  
**so that** I follow the approved procedure rather than memory.

**Acceptance criteria**

- Given an instrument is selected, when calibration opens, then the current approved procedure and revision are displayed.
- Every test point, nominal value, unit, tolerance, and sequence position is displayed.
- The applicable reference standard is shown or selected before measurement entry.
- A reference standard that is out of calibration cannot be selected.
- If the quality-management system is unavailable, a cached procedure is clearly marked with its age.
- Certificate issue is blocked if the procedure revision cannot be verified as current under the defined policy.

### US-202 — Immutable as-found capture

**As a** quality engineer,  
**I want** as-found readings captured before adjustment and locked afterward,  
**so that** the instrument’s condition during production use is preserved.

**Acceptance criteria**

- As-found values must be captured before any as-left value is entered.
- Committing an as-found value permanently locks that value from normal editing.
- A locked value cannot be changed through the client, API, or offline synchronization.
- A correction requires a governed amendment or void-and-restart process, with reason, actor, timestamp, and audit trail. The exact correction process is **TBD**.
- An as-found value outside tolerance marks the calibration as failed regardless of the as-left result.

### US-203 — Tolerance evaluation

**As a** metrology technician,  
**I want** each reading evaluated against the applicable tolerance as I enter it,  
**so that** I can identify issues immediately.

**Acceptance criteria**

- Values are validated as numeric and within the instrument’s permitted measuring range.
- The system evaluates each value against the procedure’s tolerance and unit.
- The result is stated in text as “in tolerance” or “out of tolerance”; color is not the sole indicator.
- The calibration cannot be submitted until all required test points are complete or an authorized exception is recorded.
- The final outcome is reproducible from stored readings, procedure revision, and tolerance rules.

### US-204 — Environmental and reference-standard evidence

**As a** metrology technician,  
**I want** environmental conditions and reference-standard details captured with the calibration,  
**so that** the result is traceable and defensible.

**Acceptance criteria**

- Temperature and humidity are captured with units, timestamp, and source or entry method.
- The selected reference standard records identifier, certificate number, validity period, and calibration status.
- An invalid or expired reference standard prevents calibration progression.
- Environmental evidence can include an attachment where required by the approved procedure.
- The calibration record preserves the exact procedure and reference-standard versions used.

---

## FEAT-03 — Out-of-Tolerance Impact Assessment

### US-301 — Deterministic impact list

**As a** quality engineer,  
**I want** all measurements taken with a failed instrument since its last passing calibration identified,  
**so that** I can decide what affected product requires review.

**Acceptance criteria**

- Given an as-found failure, the system determines the start boundary from the last passing calibration.
- The impact engine queries the manufacturing execution system for measurements associated with the instrument and relevant time range.
- Results identify measurement, work order, lot or product context, timestamp, and source reference where available.
- The deterministic result is stored independently of any AI-generated narrative.
- The system records query start/end times, source response status, and correlation identifier.
- The system does not silently exclude records because of pagination, unavailable fields, or source errors.

### US-302 — Explicit incomplete-result handling

**As a** quality engineer,  
**I want** incomplete impact results clearly identified,  
**so that** I do not mistake a partial list for a complete assessment.

**Acceptance criteria**

- If the manufacturing execution query times out or fails after retry, the result is labelled **Partial/Incomplete**.
- The UI states what could not be verified and provides the source error or reason at an appropriate level.
- Certificate issue remains blocked while the impact assessment is incomplete.
- A quality engineer can retry the assessment.
- Completion requires a successful query or a governed exception approved by the designated quality authority.
- Every retry and exception is audited.

### US-303 — Review and disposition recording

**As a** quality engineer,  
**I want** to record the review outcome for each affected item or group,  
**so that** product decisions remain with the quality function.

**Acceptance criteria**

- The impact screen displays affected records and their assessment state.
- A quality engineer can record a disposition or follow-up reference without changing the underlying measurement history.
- The system requires a reason and accountable identity for closure.
- The system prevents closure while required affected records remain unreviewed, unless an approved exception is recorded.
- Product disposition remains outside the calibration application’s authority unless explicitly added in a future scope decision.

---

## FEAT-04 — Certificate and Traceability

### US-401 — Certificate generated from the record

**As a** competent metrology technician,  
**I want** a certificate generated from the stored calibration record,  
**so that** the certificate does not require manual transcription.

**Acceptance criteria**

- The certificate is generated only from persisted calibration data.
- It includes instrument identity, procedure and revision, calibration date, readings, tolerances, outcome, environmental conditions, reference standard, operator, and relevant traceability data.
- The certificate includes a unique identifier and issue timestamp.
- The issue log records whether the certificate was generated successfully.
- A certificate cannot be issued when required procedure, reference-standard, competency, or impact data is incomplete.
- The target is 100% of issued certificates generated without manual transcription.

### US-402 — Competency-gated issue

**As a** quality organization,  
**I want** certificate issue restricted to an accredited competent person,  
**so that** issued certificates are attributable and valid.

**Acceptance criteria**

- The server validates the user’s Entra ID identity.
- The server evaluates calibration competency using the training-records system.
- Client-side role claims alone cannot authorize certificate issue.
- An uncertified, expired, or unavailable competency result blocks issue and states the reason.
- The certificate records the named issuer and competency verification result.
- The exact competency API contract, cache policy, and outage behavior require confirmation.

### US-403 — Immutable certificate storage

**As a** quality auditor,  
**I want** issued certificates and evidence protected from alteration,  
**so that** the record remains provably unchanged.

**Acceptance criteria**

- Issued certificates are stored in immutable Blob storage.
- Environmental evidence and other required supporting documents use the same retention and integrity policy.
- The retention target is 10 years.
- The system can retrieve the certificate and its traceability chain by instrument and calibration identifier.
- Any replacement or correction creates a new governed record; it does not overwrite the issued artifact.

---

## FEAT-05 — Offline Capture and Synchronization

### US-501 — Offline calibration capture

**As a** metrology technician,  
**I want** to capture calibration data without connectivity,  
**so that** work can continue on the shop floor and in the laboratory.

**Acceptance criteria**

- The client can make approved, previously synchronized procedures available offline.
- Offline records are encrypted at rest on the device.
- Each offline record has a device identifier, local sequence, creation timestamp, and synchronization status.
- As-found locking applies offline as well as online.
- The client clearly indicates offline state and data freshness.
- The client does not present a locally cached result as server-confirmed until synchronization succeeds.

### US-502 — Controlled synchronization

**As a** metrology technician,  
**I want** offline records synchronized safely when connectivity returns,  
**so that** no readings are duplicated, lost, or overwritten.

**Acceptance criteria**

- Synchronization is idempotent.
- A successful record receives a server identifier and synchronization timestamp.
- Conflicts are surfaced for human resolution; they are not silently merged.
- Invalid, superseded, or incomplete procedure data is rejected with an actionable reason.
- A failed synchronization preserves the local record and retry state.
- Certificate issue cannot proceed until the required server-side validations and persistence complete.

**Important policy gap:** The source material does not define whether offline calibration submission, offline issue blocking, or offline certificate issuance are permitted. These must be approved before implementation.

---

## FEAT-06 — Identity, Competency, and Auditability

### US-601 — Role-based access

**As a** system owner,  
**I want** permissions enforced by role and server-side policy,  
**so that** users can perform only authorized actions.

**Acceptance criteria**

- Technician, supervisor, quality engineer, quality manager, and administrator permissions are separately defined.
- Location and site scope are enforced server-side.
- Quality-engineer review is distinct from technician data capture.
- Quality-manager extension approval is separately attributable.
- All privileged actions are audited.

### US-602 — Audit trail

**As a** quality auditor,  
**I want** a complete audit trail,  
**so that** calibration history and decisions can be reconstructed.

**Acceptance criteria**

- The audit trail records actor, action, timestamp, entity, before/after or event details, correlation identifier, and source.
- It covers reading commitment, lock events, procedure selection, reference-standard selection, calibration outcome, impact runs, exceptions, dispositions, certificate issue, and amendments.
- Audit records cannot be altered through normal application functions.
- Audit retrieval is permission-controlled and searchable by instrument and calibration identifier.

---

## FEAT-07 — Impact Narrative Review Workflow

### US-701 — Model-drafted impact summary

**As a** quality engineer,  
**I want** a concise narrative summarizing the deterministic impact list,  
**so that** I can review the assessment efficiently.

**Acceptance criteria**

- The narrative is generated only from the stored deterministic impact result and approved context.
- All model traffic passes through Azure API Management.
- The request includes correlation headers and uses managed identity as required.
- The model output is labelled as a draft.
- The system stores model/version metadata, prompt or template version, timestamp, and correlation identifier according to the approved data-retention policy.
- The narrative cannot alter the deterministic impact list or disposition state.

### US-702 — Human approval gate

**As a** quality engineer,  
**I want** to approve, edit, or reject the drafted narrative,  
**so that** the final assessment remains a human quality decision.

**Acceptance criteria**

- The workflow pauses for quality-engineer review before the narrative is attached to the assessment.
- The reviewer can accept, edit, regenerate, or reject the draft.
- The final narrative records reviewer identity and approval timestamp.
- A rejected or unreviewed draft cannot be presented as the final assessment.
- If APIM, Foundry, or the agent workflow is unavailable, the deterministic impact list remains available and the assessment is marked as narrative-pending.
- No model output directly authorizes product disposition or certificate issue.

---

# 5. Non-functional requirements proposal

The following are derived from the technical requirements and UX inputs. Exact numbering should be reconciled with the full requirements document before baselining.

| ID | Requirement |
|---|---|
| NFR-P01 | Use Angular 18, TypeScript, Ionic 8; Python 3.12 and FastAPI; Azure SQL Database; Azure App Service Premium v3; Azure Blob Storage; GitHub Actions. |
| NFR-P02 | All model traffic must route through Azure API Management using managed identity, per-user quotas, content safety controls, and correlation headers. |
| NFR-P03 | The quality-management system is authoritative for instrument master data and procedures; the manufacturing execution system is authoritative for measurement history. |
| NFR-P04 | Quality-management integration target: two-second timeout, three retries with backoff, and 99.5% availability. On exhaustion, cached procedure data may be shown with age; certificate issue remains blocked if current revision cannot be verified. |
| NFR-P05 | Manufacturing-execution impact query target: 20-second timeout and two retries. Failure produces an explicitly incomplete result and blocks certificate issue. |
| NFR-P06 | As-found readings are immutable after commitment. This rule must be enforced at API and persistence boundaries, not only in the UI. |
| NFR-P07 | Issued certificates and required evidence are immutable and retained for 10 years. |
| NFR-P08 | Identity uses Microsoft Entra ID with conditional access requiring an Intune-compliant device. |
| NFR-P09 | Competency is read from the training-records system and evaluated server-side before certificate issue. |
| NFR-P10 | Primary hosting uses zone redundancy with paired-region warm standby. Recovery objectives are not specified and require confirmation. |
| NFR-P11 | Offline data must be encrypted on the device and synchronization must be idempotent and auditable. |
| NFR-P12 | Accessibility must not depend on color. Statuses and tolerance results must be conveyed as text and announced appropriately. |
| NFR-P13 | Every material transaction must support correlation IDs and auditable timestamps. |
| NFR-P14 | The deterministic impact engine must be independent of the AI narrative workflow. |
| NFR-P15 | Performance and availability targets for due-list load, calibration submission, certificate generation, synchronization, and mobile startup remain to be baselined. |

---

# 6. Proposed implementation tasks

## Foundation and architecture

- Confirm authoritative source interfaces and data contracts.
- Define domain model and state transitions.
- Define roles, site/location scope, and authorization matrix.
- Define calibration, reading, procedure, reference-standard, impact, disposition, certificate, and audit schemas.
- Establish Azure SQL migration strategy.
- Establish Blob immutability, retention, and retrieval policy.
- Establish APIM route, managed identity, quotas, content safety, and correlation standards.
- Establish GitHub Actions CI/CD with Dev environment protection and provenance.
- Define observability, alerting, and audit-log access.

## FEAT-01 tasks

- Implement due-date and overdue domain services.
- Implement interval and usage scheduling rules.
- Build due-list API and Ionic screens.
- Implement tool-crib issue-block integration.
- Implement extension workflow and audit trail.
- Add scheduled notification job.
- Add stale-cache and offline indicators.

## FEAT-02 tasks

- Integrate approved procedures and revisions from the quality-management system.
- Implement reference-standard validity checks.
- Build guided test-point capture UI.
- Implement server-side numeric and tolerance validation.
- Implement as-found locking at database and API layers.
- Implement environmental-condition capture.
- Add unit, range, and boundary-condition tests.

## FEAT-03 tasks

- Define last-passing-calibration boundary logic.
- Implement MES measurement-history adapter.
- Implement deterministic impact query and pagination completeness checks.
- Implement retry, timeout, and partial-result state handling.
- Build impact review screen.
- Implement disposition and exception recording.
- Add reconciliation and audit reporting.

## FEAT-04 tasks

- Define certificate template and required fields.
- Implement record-to-certificate rendering.
- Implement competency validation.
- Implement certificate issue state machine.
- Write certificates and evidence to immutable Blob storage.
- Implement retrieval and traceability views.
- Add certificate issue and no-transcription verification tests.

## FEAT-05 tasks

- Design encrypted local storage.
- Define offline eligibility and cache freshness rules.
- Implement local event/record queue.
- Implement idempotent synchronization.
- Implement conflict and superseded-procedure handling.
- Test interruption, retry, duplicate submission, and device-loss scenarios.

## FEAT-06 tasks

- Configure Entra authentication and conditional access dependency.
- Implement server-side authorization policies.
- Integrate training-records competency API.
- Implement audit event schema and storage.
- Add audit search and export controls.
- Conduct security and privacy review.

## FEAT-07 tasks

- Define deterministic input contract to the narrative workflow.
- Implement Microsoft Agent Framework workflow.
- Configure Foundry project and APIM route.
- Implement pause/resume human review state.
- Store draft and approval metadata.
- Add prompt-injection and unsupported-claim safeguards.
- Test model unavailability and malformed output.
- Ensure model output cannot mutate impact or disposition records.

---

# 7. Traceability matrix

| Business outcome / source | Proposed coverage |
|---|---|
| Reduce overdue instruments from 8.4% to under 1% | FEAT-01 / US-101, US-102, US-103 |
| Produce impact list within 10 minutes median | FEAT-03 / US-301, US-302; performance instrumentation required |
| 100% certificates without manual transcription | FEAT-04 / US-401, US-403 |
| 100% unbroken reference-standard chain | FEAT-02 / US-204 and FEAT-04 / US-401 |
| As-found values preserved before adjustment | US-202; NFR-P06 |
| Failed instrument impact assessment | FEAT-03 / US-301–303 |
| Offline shop-floor and laboratory capture | FEAT-05 / US-501–502 |
| Competency-gated certificate issue | US-402; NFR-P08–P09 |
| AI-assisted narrative with human approval | FEAT-07 / US-701–702 |
| Procedure-led technician experience | US-201, UX SCR-02 |
| Due and overdue user experience | US-101–102, UX SCR-01 |
| Impact review experience | US-301–303, UX SCR-03 |
| Certificate and traceability experience | US-401–403, UX SCR-04 |

The supplied requirements and technical text are truncated after portions of FEAT-03 and the API requirements. Therefore, traceability to the complete source set cannot yet be certified.

---

# 8. Key dependencies

| Dependency | Type | Required for |
|---|---|---|
| Quality-management system instrument and procedure APIs | External system | FEAT-01, FEAT-02, FEAT-04 |
| MES measurement-history API | External system | FEAT-03 |
| Training-records competency API | External system | US-402 |
| Tool-crib issue transaction or blocking interface | External system | US-102 |
| Entra ID and Intune compliance | Platform/security | FEAT-01, FEAT-04, FEAT-06 |
| Azure SQL | Platform | Core record and audit persistence |
| Azure Blob immutable storage | Platform | Certificates and evidence |
| APIM and Foundry project | Platform/AI | FEAT-07 |
| Approved procedure and tolerance data | Business governance | FEAT-02 |
| Approved certificate template and retention policy | Quality/legal governance | FEAT-04 |
| Device barcode/scanner capability | Device | US-101, US-201 |
| Offline operating policy | Business/security governance | FEAT-05 |
| Quality disposition authority and exception policy | Business governance | US-302–303, US-702 |

---

# 9. Risks and mitigations

| Risk | Impact | Mitigation / decision needed |
|---|---|---|
| Source documents are draft and incomplete | Baseline may change after planning | Obtain approved requirements, technical requirements, and UX artifacts before implementation approval. |
| Usage-based scheduling rule is undefined | Incorrect due dates | Confirm usage source, formula, precedence, and recalculation policy. |
| MES history may be incomplete or unavailable | False assurance about impact scope | Use explicit partial state, completeness checks, retry, reconciliation, and certificate blocking. |
| Offline data may become stale or conflict | Invalid procedures or duplicate records | Define cache TTL, offline eligibility, server validation, idempotency, and conflict workflow. |
| As-found immutability implemented only in UI | Regulatory/data-integrity failure | Enforce in API, database, synchronization, and amendment workflows. |
| Competency service outage | Certificate issuance blocked | Define approved cache duration and emergency escalation; do not bypass server-side authorization. |
| AI narrative may introduce unsupported claims | Quality or compliance risk | Keep impact list deterministic, ground prompts only in stored results, require human approval, and label draft output. |
| Certificate immutability and correction process unclear | Audit and retention risk | Approve Blob immutability, retention, legal hold, and superseding-certificate policy. |
| External system contracts not finalized | Integration delays | Run contract workshops and create mocks before feature implementation. |
| Availability and disaster-recovery objectives missing | Architecture cannot be validated | Define RTO, RPO, backup, restore, and paired-region failover expectations. |
| Notifications may fail or be ignored | Overdue compliance remains high | Define notification channels, escalation, delivery monitoring, and ownership. |
| Product disposition boundary is ambiguous | Unauthorized business action | Keep product disposition outside the application unless explicitly approved as a new scope item. |

---

# 10. Open questions requiring decisions

1. What is the exact interval-plus-usage scheduling formula?
2. Which system and event define actual instrument usage?
3. What is the formal boundary for “last passing calibration”?
4. Can a calibration be completed offline, and can an instrument be issued offline?
5. What is the maximum acceptable age for cached procedures and competency data?
6. What is the governed correction process for a committed as-found value?
7. What constitutes a complete MES impact response?
8. Who can approve an incomplete-impact exception?
9. Are quality-engineer dispositions recorded in this application or only referenced externally?
10. What are the RTO and RPO targets?
11. What are the performance targets for due-list loading, synchronization, calibration submission, and certificate generation?
12. What notification channels and escalation intervals are required?
13. What is the approved certificate template and signing/sealing requirement?
14. What exact data may be sent to Foundry through APIM, and what retention policy applies to prompts and outputs?
15. What are the requirements for environmental evidence attachments?
16. What are the complete FEAT-03, FEAT-04, NFR, traceability, and assumptions sections omitted by the supplied truncated text?

---

# 11. Proposed approval gates

### Gate 1 — Requirements baseline

Approve:

- Scope and out-of-scope boundaries.
- Scheduling and usage rules.
- Calibration state model.
- Impact completeness and exception policy.
- Offline operating policy.
- Certificate and amendment policy.
- Roles and competency rules.

### Gate 2 — Technical design

Approve:

- External API contracts.
- Data model and immutability design.
- Offline synchronization design.
- APIM/Foundry workflow and data-handling design.
- Security, retention, DR, and observability design.

### Gate 3 — UX and accessibility

Approve:

- Complete screens and states, including failure, offline, partial, blocked, and stale-data states.
- Role-based visibility.
- Accessibility behavior for status and tolerance results.
- Human-review workflow for impact narratives.

### Gate 4 — Dev implementation readiness

Proceed only after:

- Draft source documents are replaced or explicitly baselined.
- Open questions affecting behavior are resolved.
- Dependencies have owners and test environments.
- Acceptance criteria are approved.
- Test data and integration mocks are available.

---

## Recommendation

**Do not authorize code generation yet.** The proposal is sufficiently structured for requirements and architecture workshops, but the source package is draft, truncated, and missing decisions that affect compliance behavior—particularly usage-based scheduling, offline authority, impact completeness, competency outages, certificate correction, and disaster recovery.