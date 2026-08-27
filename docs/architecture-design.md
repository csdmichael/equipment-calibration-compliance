# Architecture Advisor — Design-Stage Reviewable Proposal

**Project:** Equipment Calibration Compliance  
**Target environment:** Dev  
**Stage:** Design  
**Proposal status:** Reviewable draft  
**Source basis:** Intake documents plus approved Requirements Agent summary  
**Important note:** Source intake documents are marked **Draft** and portions were truncated in the provided payload. This proposal identifies assumptions and open decisions rather than treating missing details as approved.

---

## 1. Executive summary

I recommend a **modular Azure-based architecture** with:

- **Ionic 8 + Angular 18** client for tablet, handheld, and browser experiences
- **Python 3.12 + FastAPI** as the primary domain API
- **Azure SQL Database** as the system of record for calibration records, readings, impact assessments, and certificate metadata
- **Azure Blob Storage with immutability** for issued certificates and evidence artifacts
- **Azure Functions** for:
  - impact assessment orchestration/execution
  - certificate rendering/generation
- **Microsoft Agent Framework / Foundry** for **drafting impact narratives only**
- **Azure API Management** as the mandatory gateway for all model traffic
- **Microsoft Entra ID** for identity, with competency enforced server-side
- **Offline-first client behavior** with queued synchronization and conflict rules designed around immutable as-found data

This design aligns with the stated constraints:

- **As-found readings must be immutable**
- **Certificate issue must be competency-gated**
- **Impact assessment must never be silently incomplete**
- **AI output is assistive only, never authoritative for deterministic impact scope**

---

## 2. Architecture goals

### Primary design goals
1. Preserve calibration record integrity.
2. Prevent use of overdue instruments.
3. Support guided, auditable calibration execution.
4. Produce deterministic impact lists for out-of-tolerance events.
5. Block certificate issue when prerequisite data is incomplete or stale.
6. Support intermittent connectivity with safe offline capture.
7. Maintain traceability to reference standards and issued certificates.
8. Keep AI usage bounded, reviewable, and non-authoritative.

### Quality attributes
- **Integrity:** highest priority
- **Auditability:** mandatory
- **Availability:** laboratory-hours operational availability
- **Consistency:** strong consistency for calibration records and impact decisions
- **Usability:** gloved/mobile workflows, explicit status wording
- **Security/compliance:** attributable actions, immutable records, least privilege

---

## 3. Proposed logical architecture

## 3.1 Context view

**Users**
- Metrology technician
- Production supervisor
- Quality engineer
- Quality manager

**Primary solution components**
- Calibration client app
- Calibration API/service
- Impact assessment engine
- Certificate generator
- Impact narrative workflow
- Integration adapters/cache
- SQL database
- Blob storage

**External systems**
- Quality Management System (QMS): instrument master, procedures
- Manufacturing Execution System (MES): measurement history
- Training Records System: competency verification
- Microsoft Foundry via APIM: narrative drafting only

---

## 3.2 Container/component view

### A. Calibration Client
**Technology:** Ionic 8, Angular 18, TypeScript  
**Responsibilities:**
- Due/overdue list
- Guided calibration capture
- Offline data entry and sync queue
- Impact review UI
- Certificate issue UI
- Barcode scanning integration
- Explicit lock-state presentation for as-found values

**Notes:**
- Client must not be trusted for business enforcement.
- Server remains authoritative for overdue blocking, competency, certificate issue, and immutable state transitions.

---

### B. Calibration Service
**Technology:** Python 3.12, FastAPI on Azure App Service  
**Responsibilities:**
- Core domain API
- Calibration lifecycle/state machine
- As-found locking enforcement
- Tolerance evaluation
- Reference standard validity checks
- Extension management
- Competency enforcement
- Certificate issue authorization
- Audit event generation
- Sync ingestion and reconciliation
- Orchestration of impact and certificate workflows

**Why centralize here:**  
This is the domain authority and should own all invariant rules.

---

### C. Impact Assessment Engine
**Technology:** Python Azure Functions  
**Responsibilities:**
- Trigger on failed as-found/out-of-tolerance calibration
- Resolve measurements since last passing calibration
- Query MES history
- Produce deterministic impact set
- Mark result complete/partial/incomplete
- Persist impact assessment status and evidence

**Design principle:**  
The impact list is deterministic and must not depend on AI.

---

### D. Certificate Generator
**Technology:** Python Azure Functions  
**Responsibilities:**
- Render certificate from stored calibration record
- Include traceability chain and reference standard details
- Write final artifact to immutable Blob storage
- Return certificate metadata and storage URI/reference

---

### E. Impact Narrative Workflow
**Technology:** Microsoft Agent Framework / Foundry  
**Responsibilities:**
- Summarize deterministic impact scope
- Draft narrative for quality engineer review
- Never alter authoritative impact data
- Pause for human review before attachment/finalization

**Routing requirement:**  
All model traffic goes through **Azure API Management**.

---

### F. Integration Adapters / Caching Layer
Could be implemented inside the Calibration Service initially, with clear module boundaries for:
- QMS adapter
- MES adapter
- Training records adapter

**Recommendation:** start in-process for Dev unless scale/ownership requires separate services.

---

### G. Data Stores
- **Azure SQL Database**: transactional system of record
- **Azure Blob Storage**: certificates and evidence, immutable after issue

---

## 4. Proposed deployment architecture

### Azure services
- **Azure App Service Premium v3**
  - Hosts FastAPI calibration service
  - Zone redundancy in primary region
- **Azure Functions**
  - Impact assessment engine
  - Certificate generation
- **Azure SQL Database**
- **Azure Storage Account**
  - Blob containers with immutability policies
- **Azure API Management**
  - Required gateway for model traffic
- **Microsoft Entra ID**
- **Application Insights / Azure Monitor**
- **Key Vault** for secrets/certificates if needed

### Environment recommendation for Dev
- Single Dev environment with:
  - lower-cost APIM tier if governance permits
  - non-production SQL and storage
  - test integrations or mocks for QMS/MES/training APIs
- Preserve production-like boundaries even in Dev.

---

## 5. Domain model recommendation

## 5.1 Core entities

### Instrument
- instrumentId
- instrumentTypeId
- serialNumber
- description
- locationId
- criticality
- status
- calibrationInterval
- usageBasedIntervalPolicy
- lastPassingCalibrationId
- nextDueDate
- overdueFlag

### CalibrationProcedure
- procedureId
- revision
- instrumentTypeId
- effectiveDate
- status
- sourceSystemId
- cachedAt

### ProcedureTestPoint
- testPointId
- procedureId
- sequence
- nominalValue
- lowerTolerance
- upperTolerance
- unitOfMeasure
- measuringRangeMin
- measuringRangeMax

### ReferenceStandard
- standardId
- certificateNumber
- description
- calibrationValidTo
- traceabilityRoot
- status

### CalibrationSession
- calibrationId
- instrumentId
- procedureId
- procedureRevision
- technicianId
- startedAt
- submittedAt
- status
- referenceStandardId
- environmentalTemperature
- environmentalHumidity
- offlineCaptureFlag
- syncStatus

### CalibrationReading
- readingId
- calibrationId
- testPointId
- readingType (`AS_FOUND`, `AS_LEFT`)
- value
- capturedAt
- capturedBy
- lockedAt
- toleranceResult (`IN_TOLERANCE`, `OUT_OF_TOLERANCE`)
- immutableHash / version marker

### CalibrationOutcome
- calibrationId
- overallResult (`PASS`, `FAIL`)
- failReason
- asFoundFailureFlag
- asLeftResult
- evaluatedAt

### ImpactAssessment
- impactAssessmentId
- calibrationId
- status (`PENDING`, `RUNNING`, `COMPLETE`, `PARTIAL`, `FAILED_REVIEW_REQUIRED`)
- completenessFlag
- lastGoodCalibrationId
- measurementWindowStart
- measurementWindowEnd
- generatedAt
- reviewedBy
- reviewedAt

### ImpactItem
- impactItemId
- impactAssessmentId
- measurementId
- workOrderId
- lotId
- measuredAt
- productId
- dispositionStatus
- sourceCompletenessFlag

### Certificate
- certificateId
- calibrationId
- issuedBy
- issuedAt
- competencyVerifiedAt
- blobUri
- blobVersionId / immutable reference
- certificateNumber
- status

### Extension
- extensionId
- instrumentId
- approvedBy
- justification
- effectiveAt
- expiresAt
- status

### AuditEvent
- auditEventId
- entityType
- entityId
- action
- actorId
- timestamp
- correlationId
- beforeSnapshotRef
- afterSnapshotRef

---

## 5.2 Key invariants

1. **As-found readings cannot be edited after commit.**
2. **As-left readings cannot be entered before as-found is locked.**
3. **Any out-of-tolerance as-found reading causes calibration failure.**
4. **Reference standard must be valid at time of use.**
5. **Certificate issue is blocked if competency cannot be verified.**
6. **Certificate issue is blocked if impact assessment is partial/incomplete for failed calibration.**
7. **Procedure cache may support execution, but stale/superseded uncertainty blocks certificate issue.**
8. **Overdue issue blocking is enforced server-side.**
9. **AI narrative cannot overwrite deterministic impact data.**

---

## 6. Recommended data architecture

## 6.1 Azure SQL schema domains

Suggested schema grouping:

- `master`
  - instruments
  - locations
  - instrument_types
  - reference_standards
- `procedure`
  - procedures
  - procedure_test_points
  - procedure_cache_metadata
- `calibration`
  - calibrations
  - readings
  - outcomes
  - environmental_conditions
- `impact`
  - assessments
  - assessment_items
  - review_notes
  - narrative_drafts
- `certificate`
  - certificates
  - certificate_events
- `security`
  - competency_checks
  - extensions
- `audit`
  - audit_events
  - outbox_events
- `sync`
  - client_sync_batches
  - sync_conflicts

## 6.2 Storage recommendations

### SQL
Use SQL for:
- transactional consistency
- joins across calibration/test points/readings
- deterministic impact metadata
- audit and workflow states

### Blob storage
Use Blob for:
- issued PDF certificates
- environmental evidence attachments
- scanned supporting artifacts if later approved

**Immutability:**  
Enable immutable blob policies or legal hold equivalent for issued certificates per retention policy.

---

## 7. API design proposal

Below is a reviewable contract outline, not final implementation code.

## 7.1 API style
- REST over HTTPS
- JSON payloads
- Versioned routes: `/api/v1/...`
- Idempotency keys for submit/issue operations
- Correlation IDs on every request/response
- Problem Details (`application/problem+json`) for errors

---

## 7.2 Core API endpoints

### Due management
**GET** `/api/v1/instruments/due`
- Query: `locationId`, `filter`, `page`, `pageSize`
- Returns prioritized due/overdue list

**POST** `/api/v1/instruments/{instrumentId}/issue-check`
- Used by tool crib scan flow
- Returns `allowed: true/false`, reason, due status, extension status

**POST** `/api/v1/instruments/{instrumentId}/extensions`
- Quality manager only
- Creates documented extension

---

### Procedure and calibration
**GET** `/api/v1/instruments/{instrumentId}/procedure`
- Returns approved/cached procedure and revision metadata

**POST** `/api/v1/calibrations`
- Starts calibration session

**POST** `/api/v1/calibrations/{calibrationId}/reference-standard`
- Selects reference standard after validity check

**POST** `/api/v1/calibrations/{calibrationId}/environment`
- Captures temperature/humidity

**POST** `/api/v1/calibrations/{calibrationId}/readings/as-found`
- Commits one or more as-found readings
- Locks on successful commit

**POST** `/api/v1/calibrations/{calibrationId}/readings/as-left`
- Allowed only after corresponding as-found lock

**POST** `/api/v1/calibrations/{calibrationId}/submit`
- Evaluates outcome and triggers downstream workflows

---

### Impact assessment
**GET** `/api/v1/calibrations/{calibrationId}/impact-assessment`
- Returns status, completeness, items, review state

**POST** `/api/v1/calibrations/{calibrationId}/impact-assessment/review`
- Quality engineer records review/dispositions

**POST** `/api/v1/calibrations/{calibrationId}/impact-assessment/narrative-draft`
- Triggers agent workflow through APIM

**POST** `/api/v1/calibrations/{calibrationId}/impact-assessment/narrative-approve`
- Human approval required before attachment

---

### Certificate
**POST** `/api/v1/calibrations/{calibrationId}/certificate/issue`
- Verifies competency and prerequisites
- Generates immutable certificate

**GET** `/api/v1/calibrations/{calibrationId}/certificate`
- Returns metadata and retrieval reference

---

### Offline sync
**POST** `/api/v1/sync/batches`
- Uploads queued offline actions

**GET** `/api/v1/sync/batches/{batchId}`
- Returns processing status and conflicts

---

## 7.3 Example contract snippets

### Start calibration request
```json
{
  "instrumentId": "INS-100245",
  "clientSessionId": "mob-7f2d-001",
  "startedAtClient": "2026-08-27T09:15:00Z",
  "offlineMode": true
}
```

### As-found reading commit
```json
{
  "testPointId": "TP-03",
  "value": 10.014,
  "unitOfMeasure": "mm",
  "capturedAtClient": "2026-08-27T09:22:10Z",
  "idempotencyKey": "af-TP-03-001"
}
```

### As-found reading response
```json
{
  "readingId": "RD-88421",
  "calibrationId": "CAL-22019",
  "testPointId": "TP-03",
  "readingType": "AS_FOUND",
  "value": 10.014,
  "toleranceResult": "OUT_OF_TOLERANCE",
  "locked": true,
  "lockedAt": "2026-08-27T09:22:11Z",
  "nextAllowedAction": "ENTER_AS_LEFT"
}
```

### Issue-check response
```json
{
  "instrumentId": "INS-100245",
  "allowed": false,
  "status": "OVERDUE",
  "dueDate": "2026-08-20",
  "daysOverdue": 7,
  "extension": null,
  "reason": "Instrument is overdue for calibration and cannot be issued."
}
```

### Impact assessment response
```json
{
  "impactAssessmentId": "IA-90012",
  "status": "PARTIAL",
  "completenessFlag": false,
  "message": "Measurement history query incomplete after retries; certificate issue remains blocked.",
  "measurementWindowStart": "2026-05-01T00:00:00Z",
  "measurementWindowEnd": "2026-08-27T10:05:00Z",
  "items": [
    {
      "measurementId": "MEAS-1001",
      "workOrderId": "WO-7781",
      "lotId": "LOT-22A"
    }
  ]
}
```

---

## 8. Offline-first design recommendation

## 8.1 Offline scope
Allow offline support for:
- due list viewing from cached data
- procedure viewing from cached approved revision
- calibration session creation
- environmental capture
- as-found/as-left reading entry
- local barcode-assisted workflow

Do **not** allow offline final authority for:
- certificate issue
- competency validation
- final impact completeness confirmation
- extension approval

---

## 8.2 Sync model
Use an **append-only action queue** on device:
- start calibration
- select standard
- capture environment
- commit as-found reading
- commit as-left reading
- submit calibration

Each queued action should include:
- client action ID
- client timestamp
- device ID
- user ID
- idempotency key
- prior local state hash/version

---

## 8.3 Conflict strategy
### As-found readings
- Never overwrite server-accepted as-found values.
- If duplicate or conflicting submission occurs:
  - preserve original accepted value
  - mark later attempt as conflict
  - require supervised correction workflow, not silent replacement

### Procedure revisions
- If offline procedure revision is stale:
  - calibration may sync as captured against cached revision
  - certificate issue blocked pending review if revision supersession risk exists

### Reference standard validity
- If standard was believed valid offline but server determines invalid at effective time:
  - calibration flagged for review/failure path
  - certificate issue blocked

---

## 9. Integration architecture

## 9.1 QMS integration
**Purpose:** instrument master, procedures  
**Pattern:** REST pull with cache  
**Failure behavior:** use cached procedure with age marker; block certificate issue if supersession uncertainty exists

**Recommendation:**
- Cache procedure revision and effective date
- Store source ETag/version if available
- Record cache age in API response and audit trail

---

## 9.2 MES integration
**Purpose:** measurement history for impact assessment  
**Pattern:** REST query by instrument and date range  
**Failure behavior:** if retries exhausted, mark impact assessment partial/incomplete and block certificate issue

**Recommendation:**
- Persist raw query metadata and response completeness markers
- Support resumable/retryable impact jobs

---

## 9.3 Training records integration
**Purpose:** competency verification for certificate issue  
**Pattern:** synchronous check at issue time, optionally cached short-term  
**Failure behavior:** fail closed; no competency confirmation means no certificate issue

---

## 10. AI/agent architecture recommendation

## 10.1 Allowed AI role
AI may:
- summarize deterministic impact scope
- draft assessment narrative
- assist engineer review

AI may not:
- determine impact scope
- change calibration outcome
- approve certificate issue
- override competency or completeness checks

---

## 10.2 Agent workflow pattern
1. Calibration fails due to as-found out-of-tolerance.
2. Impact engine computes deterministic impact list.
3. Calibration service sends approved structured summary to APIM.
4. APIM routes to Foundry/Microsoft Agent Framework.
5. Agent returns draft narrative.
6. Narrative stored as draft only.
7. Quality engineer reviews/edits/approves.
8. Approved narrative attached to assessment.

---

## 10.3 APIM policy recommendations
- Managed identity authentication
- Per-user/per-app quotas
- Correlation headers
- Content safety checks
- Request/response logging with sensitive-field redaction
- Model allowlist
- Payload size limits
- Explicit route segregation for narrative drafting only

---

## 11. Security architecture

## 11.1 Identity and access
Use **Microsoft Entra ID** with:
- conditional access
- Intune-compliant device requirement where mandated
- role-based authorization plus domain policy checks

### Suggested roles
- Technician
- Production Supervisor
- Quality Engineer
- Quality Manager
- System Administrator
- Auditor (read-only)

### Fine-grained policy examples
- Only Quality Manager can approve extension
- Only competent named person can issue certificate
- Technician can capture calibration but not alter locked as-found values
- Quality Engineer can review impact and approve narrative, but not bypass completeness block

---

## 11.2 Data protection
- TLS in transit
- TDE for SQL at rest
- Storage encryption at rest
- Key Vault-backed secrets
- PII minimization in logs
- Immutable storage for issued certificates
- Audit trail for all privileged actions

---

## 11.3 Auditability
Audit events should capture:
- who
- what
- when
- from which device/session
- before/after state where appropriate
- correlation ID across API, function, and agent calls

Critical audited actions:
- extension approval
- as-found commit
- calibration submit
- impact review
- narrative approval
- certificate issue
- failed competency check
- sync conflict resolution

---

## 12. Threat model considerations

Below is a reviewable STRIDE-oriented summary.

## 12.1 Spoofing
**Threats**
- Unauthorized user impersonates competent issuer
- Shared device misuse on shop floor

**Mitigations**
- Entra ID authentication
- conditional access / compliant device checks
- short session lifetime on handhelds
- server-side competency verification at issue time
- named-user attribution in audit logs

---

## 12.2 Tampering
**Threats**
- Modification of as-found readings after capture
- Alteration of issued certificates
- Manipulation of offline sync payloads

**Mitigations**
- immutable state transition for as-found
- append-only audit trail
- idempotency keys and server validation
- blob immutability/versioning
- signed or integrity-checked sync payload metadata
- server-side recalculation of tolerance and outcome

---

## 12.3 Repudiation
**Threats**
- User denies issuing certificate or approving extension

**Mitigations**
- attributable identity
- timestamped audit events
- correlation IDs
- competency verification record at issue time
- immutable certificate event log

---

## 12.4 Information disclosure
**Threats**
- Exposure of product/lot impact data
- Leakage of model prompts/responses containing sensitive operational data

**Mitigations**
- role-based access
- APIM redaction/logging controls
- least-privilege data access
- avoid unnecessary sensitive fields in AI prompts
- segregated storage and access policies

---

## 12.5 Denial of service
**Threats**
- MES or QMS outage blocks operations
- excessive model usage or API abuse

**Mitigations**
- cached procedures for continuity
- explicit degraded modes
- retries with backoff
- APIM quotas/rate limits
- async impact processing
- warm standby architecture

---

## 12.6 Elevation of privilege
**Threats**
- Technician gains extension approval or certificate issue capability
- client-side role manipulation

**Mitigations**
- server-side authorization only
- role claims plus policy checks
- no trust in client role presentation
- privileged action revalidation

---

## 13. Architecture decision records

## ADR-001: Use Azure SQL Database as primary system of record
**Status:** Proposed  
**Decision:** Store calibration records, readings, impact metadata, and certificate metadata in Azure SQL.  
**Rationale:** Strong consistency, relational joins, transactional integrity, auditability.  
**Consequences:** Requires schema governance and migration discipline; less flexible than document-first storage.

---

## ADR-002: Keep deterministic impact assessment separate from AI narrative generation
**Status:** Proposed  
**Decision:** Impact list is computed by deterministic service logic; AI only drafts narrative.  
**Rationale:** Regulatory/audit integrity and requirement that impact assessment must never be silently incomplete.  
**Consequences:** Two-step workflow; human review remains mandatory.

---

## ADR-003: Enforce as-found immutability in the domain API and database model
**Status:** Proposed  
**Decision:** As-found commits become locked records and cannot be edited in place.  
**Rationale:** Core business rule and audit requirement.  
**Consequences:** Correction requires exception workflow, not update-in-place.

---

## ADR-004: Use Azure Functions for impact and certificate workloads
**Status:** Proposed  
**Decision:** Implement impact assessment and certificate generation as separate function-based workloads.  
**Rationale:** Natural fit for asynchronous/background processing and workload isolation.  
**Consequences:** Requires orchestration, observability, and retry design.

---

## ADR-005: Support offline capture with append-only sync actions
**Status:** Proposed  
**Decision:** Client stores queued actions and syncs to server with idempotency keys.  
**Rationale:** Intermittent connectivity is a stated requirement; append-only aligns with immutable record rules.  
**Consequences:** Conflict handling and reconciliation complexity increase.

---

## ADR-006: Block certificate issue on incomplete impact, stale procedure uncertainty, or failed competency verification
**Status:** Proposed  
**Decision:** Fail closed for certificate issue.  
**Rationale:** Matches technical constraints and quality/compliance posture.  
**Consequences:** More operational escalations, but safer compliance behavior.

---

## ADR-007: Route all model traffic through Azure API Management
**Status:** Proposed  
**Decision:** No direct client or service calls to model endpoints.  
**Rationale:** Governance, observability, quotas, safety, and stated platform constraint.  
**Consequences:** APIM becomes a critical dependency for AI-assisted features.

---

## 14. Sequence flows

## 14.1 Guided calibration happy path
1. Technician scans instrument.
2. Client requests issue/procedure status.
3. Service validates instrument status and returns procedure.
4. Technician selects valid reference standard.
5. Technician records environment.
6. Technician enters as-found reading for each test point.
7. Service locks each as-found reading on commit and evaluates tolerance.
8. Technician enters as-left readings.
9. Technician submits calibration.
10. Service computes final outcome.
11. If pass and competency later verified, certificate may be issued.
12. Certificate generator renders and stores immutable certificate.

---

## 14.2 Failed calibration with impact workflow
1. As-found reading is out of tolerance.
2. Service marks calibration failed.
3. Impact engine starts using last passing calibration date.
4. MES queried for measurement history.
5. Impact list persisted with completeness status.
6. If complete, quality engineer reviews.
7. Narrative draft requested through APIM to Foundry.
8. Engineer approves/edits narrative.
9. Certificate remains blocked until required review gates are satisfied.

---

## 15. Non-functional design recommendations

## 15.1 Availability and resilience
- Use retries with backoff for QMS/MES/training integrations
- Surface degraded mode explicitly in UI
- Never hide partial impact state
- Use async jobs for long-running impact queries
- Warm standby in paired region for production target later

## 15.2 Performance
Suggested initial targets for review:
- Due list load: < 2 seconds for normal page
- Procedure fetch from cache: < 1 second
- As-found commit: < 500 ms typical
- Impact assessment initiation: < 2 seconds
- Impact completion: dependent on MES, but status visible immediately
- Certificate generation: < 30 seconds typical

## 15.3 Observability
- Distributed tracing across client/API/functions/APIM/agent workflow
- Business metrics:
  - overdue instrument count
  - failed calibrations
  - impact completion time
  - certificate issue success/failure reasons
  - sync conflict rate
- Security metrics:
  - failed authorization attempts
  - competency check failures
  - APIM quota/safety events

---

## 16. Implementation plan

## Phase 1 — Foundation
- Establish repo structure and CI/CD
- Provision Dev infrastructure
- Set up Entra ID auth and role model
- Create SQL schema baseline
- Create storage containers and immutability approach
- Implement observability baseline
- Define API versioning and error standards

## Phase 2 — Core calibration domain
- Instrument due list
- Issue-block API
- Procedure retrieval/cache
- Calibration session lifecycle
- Reference standard validation
- Environmental capture
- As-found/as-left reading APIs
- Tolerance evaluation
- Audit logging

## Phase 3 — Offline support
- Client local store and sync queue
- Idempotent sync ingestion
- Conflict detection and operator-visible errors
- Cached procedure and due list behavior

## Phase 4 — Impact assessment
- Last passing calibration logic
- MES integration adapter
- Impact engine and persistence
- Partial/incomplete handling
- Quality engineer review UI/API

## Phase 5 — Certificate and traceability
- Competency integration
- Certificate rendering
- Immutable blob storage
- Traceability chain presentation
- Certificate issue gating

## Phase 6 — AI-assisted narrative
- APIM route and policies
- Agent workflow integration
- Draft storage
- Human approval workflow
- Prompt/data minimization review

## Phase 7 — Hardening and validation
- Security testing
- offline/sync testing
- audit trail verification
- resilience/failure-mode testing
- UAT with metrology and quality users

---

## 17. Suggested backlog for technical design

1. Define calibration state machine.
2. Define immutable reading persistence model.
3. Define sync action schema and idempotency strategy.
4. Define QMS procedure cache policy and stale-data rules.
5. Define MES impact query contract and completeness semantics.
6. Define competency check contract and fail-closed behavior.
7. Define certificate template data contract.
8. Define audit event taxonomy.
9. Define APIM policies for model traffic.
10. Define exception workflow for erroneous as-found entry.
11. Define retention and immutability settings for certificates/evidence.
12. Define role/permission matrix.

---

## 18. Open questions / approval items

These should be resolved before implementation approval:

1. **Tool crib integration boundary:**  
   Is issue blocking enforced through this app only, or must it integrate with an existing crib/issuance system?

2. **Usage-based scheduling details:**  
   What exact usage signals and formulas govern next-due calculation?

3. **Procedure supersession rule:**  
   Can a calibration started offline against cached revision complete if a newer revision became effective before sync?

4. **As-found correction workflow:**  
   What approved exception process applies to mistaken entries if edits are prohibited?

5. **Impact disposition scope:**  
   What exact disposition fields are recorded by quality, and in which system is final product disposition authoritative?

6. **Certificate numbering scheme:**  
   Is numbering generated locally, centrally, or from QMS?

7. **Traceability chain depth:**  
   How much of the reference-standard chain must appear on the certificate versus remain retrievable from record?

8. **Retention policy details:**  
   The technical document states 10 years for certificates; does the same retention apply to readings, impact assessments, and audit logs?

9. **Training records SLA and cache tolerance:**  
   Is any temporary cache acceptable for competency checks, or must every issue action call live data?

10. **Dev integration mode:**  
   Are real Dev endpoints available for QMS/MES/training, or are mocks required initially?

---

## 19. Review recommendation

**Recommendation:** Approve this as the **baseline design direction**, subject to resolution of the open questions above and formal sign-off from:
- Business owner
- Quality/Metrology owner
- Technical owner
- Security/Compliance owner
- UX representative

---

## 20. Reviewable summary

This proposal is fit for review because it:
- translates requirements into a concrete architecture
- preserves the stated compliance constraints
- defines bounded AI usage through Microsoft Agent Framework and APIM
- proposes data and API contracts
- includes threat-model considerations
- provides an implementable phased plan

If you want, I can next convert this into any of these formats:
1. **Formal ADR document set**
2. **Detailed API contract spec**
3. **SQL schema draft**
4. **C4 architecture description**
5. **Implementation work breakdown with epics/stories/tasks**