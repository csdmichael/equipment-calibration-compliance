# Architecture Advisor Agent — Design-Stage Reviewable Proposal

**Project:** Equipment Calibration Compliance  
**Target environment:** Dev  
**Stage:** Design  
**Status:** Reviewable proposal only; implementation should not proceed without human approval

## 1. Executive summary

This proposal translates the approved planning inputs into a governed design for an equipment calibration compliance solution using:

- **Angular 18 + Ionic 8** client
- **Python 3.12 + FastAPI** service layer
- **Azure SQL Database**
- **Azure Blob Storage** for immutable issued artifacts
- **Azure App Service** hosting
- **Azure Functions** for impact assessment and certificate generation
- **Microsoft Agent Framework / Foundry** for impact narrative drafting
- **Azure API Management** as the mandatory gateway for all model traffic
- **Microsoft Entra ID** for identity and access control

The design centers on a few non-negotiable business rules from the intake documents:

1. **As-found readings are immutable once committed**
2. **Reference standards must be in calibration to be used**
3. **Impact assessment must never appear complete when it is not**
4. **Certificate issue is competency-gated and attributable**
5. **Issued certificates and supporting evidence must be immutable**
6. **AI may draft narrative only; it must not determine impact scope or disposition**

## 2. Proposed architecture

## 2.1 Logical architecture

```text
[Ionic/Angular Client]
   |  HTTPS / OAuth2
   v
[Azure API Management]
   |
   v
[FastAPI Calibration Service on Azure App Service]
   |----> [Azure SQL Database]
   |----> [Azure Blob Storage]
   |----> [QMS API: instrument master, procedures]
   |----> [Training Records API: competency]
   |----> [Azure Functions: Impact Assessment Engine]
   |----> [Azure Functions: Certificate Generator]
   |----> [APIM -> Microsoft Agent Framework / Foundry]
                    |
                    v
              [Impact Narrative Draft]

[Impact Assessment Engine]
   |----> [MES Measurement History API]
```

## 2.2 Component responsibilities

### A. Client application
**Technology:** Angular 18, TypeScript, Ionic 8  
**Responsibilities:**
- Due/overdue worklist
- Guided calibration capture
- Offline-first local work queue
- Impact review UI
- Certificate issue UI
- Barcode scan initiation
- Clear display of lock states, failures, and incomplete impact results

### B. Calibration service
**Technology:** FastAPI on Azure App Service  
**Responsibilities:**
- Calibration workflow orchestration
- As-found locking enforcement
- Tolerance evaluation
- Reference standard validity checks
- Competency enforcement for certificate issue
- Audit trail creation
- Sync conflict handling
- Integration façade over QMS, training records, storage, and downstream functions

### C. Impact assessment engine
**Technology:** Python Azure Functions  
**Responsibilities:**
- Deterministic retrieval of affected measurements since last passing calibration
- Completeness state calculation
- Partial-result labeling
- Correlation of instrument, work order, lot, and measurement references

### D. Certificate generator
**Technology:** Python Azure Functions  
**Responsibilities:**
- Render certificate from persisted calibration record only
- Include traceability chain and evidence references
- Write issued certificate to immutable blob storage
- Return certificate metadata and storage URI

### E. Impact narrative workflow
**Technology:** Microsoft Agent Framework / Foundry via APIM  
**Responsibilities:**
- Summarize deterministic impact scope
- Draft narrative for engineer review
- Preserve human approval gate before attachment/finalization

## 3. Architecture decisions

## ADR-001 — Use Azure SQL Database as system of record for calibration domain
**Status:** Proposed  
**Decision:** Store calibrations, readings, impact assessments, dispositions, and certificate metadata in Azure SQL Database.  
**Rationale:**
- Strong relational consistency
- Clear auditability
- Range joins for impact windows
- Transactional enforcement of immutable state transitions

**Consequences:**
- Requires careful indexing for impact and due-list queries
- Offline sync must reconcile against relational constraints

---

## ADR-002 — Keep QMS and MES as external systems of record
**Status:** Proposed  
**Decision:** Do not replicate ownership of instrument master, procedures, or measurement history into this solution beyond controlled caching.  
**Rationale:**
- Matches stated system boundaries
- Reduces master-data divergence risk

**Consequences:**
- Requires resilient integration and cache-age signaling
- Some workflows degrade to read-only or blocked states during dependency outages

---

## ADR-003 — Enforce as-found immutability at API and database layers
**Status:** Proposed  
**Decision:** Once an as-found reading is committed, it cannot be updated in place. Corrections require a governed exception workflow or calibration restart/cancellation policy.  
**Rationale:**
- Core compliance rule
- Prevents UI-only enforcement gaps

**Consequences:**
- Need explicit UX for mistaken entry handling
- Need append-only audit events

---

## ADR-004 — Separate deterministic impact scope from AI-generated narrative
**Status:** Proposed  
**Decision:** Impact list generation remains deterministic code; AI only drafts explanatory narrative after scope is computed.  
**Rationale:**
- Regulatory defensibility
- Prevents model hallucination from affecting product-impact determination

**Consequences:**
- Narrative attachment must remain review-gated
- Prompt inputs must be bounded to approved deterministic data

---

## ADR-005 — Route all model traffic through Azure API Management
**Status:** Proposed  
**Decision:** All calls to Microsoft Agent Framework / Foundry go through APIM with managed identity, quotas, safety, and correlation headers.  
**Rationale:**
- Required platform constraint
- Centralized governance and observability

**Consequences:**
- No direct client-to-model or service-to-model calls
- APIM policy set becomes part of compliance boundary

---

## ADR-006 — Use offline capture with server-authoritative synchronization
**Status:** Proposed  
**Decision:** Client supports offline capture, but server remains authoritative for final state transitions and conflict resolution.  
**Rationale:**
- Required for intermittent coverage
- Protects integrity of calibration records

**Consequences:**
- Need sync status model
- Need conflict rules for stale procedures, expired standards, and duplicate submissions

## 4. Domain model

## 4.1 Core entities

### Instrument
- instrumentId
- serialNumber
- description
- typeCode
- locationId
- criticality
- status
- calibrationIntervalDays
- usageIntervalThreshold
- lastCalibrationId
- nextDueDate
- extensionId nullable

### CalibrationProcedure
- procedureId
- revision
- instrumentTypeCode
- effectiveFrom
- status
- testPoints
- requiredEnvironmentalFields

### CalibrationSession
- calibrationId
- instrumentId
- procedureId
- procedureRevision
- startedBy
- startedAt
- completedAt
- status: Draft | InProgress | Submitted | Passed | Failed | Cancelled
- referenceStandardId
- environmentalTemperature
- environmentalHumidity
- offlineCaptureFlag
- syncState
- lastPassingCalibrationId

### CalibrationReading
- readingId
- calibrationId
- testPointSequence
- nominalValue
- toleranceMin
- toleranceMax
- asFoundValue
- asFoundCommittedAt
- asFoundCommittedBy
- asFoundLocked boolean
- asLeftValue nullable
- asLeftCommittedAt nullable
- resultAsFound: InTolerance | OutOfTolerance
- resultAsLeft nullable

### ReferenceStandard
- referenceStandardId
- certificateNumber
- validFrom
- validTo
- status
- traceabilityChainId

### ImpactAssessment
- impactAssessmentId
- calibrationId
- triggeredAt
- status: Pending | Complete | Partial | Reviewed | Closed
- completenessFlag
- incompleteReason nullable
- lastPassingCalibrationId
- measurementWindowStart
- measurementWindowEnd
- reviewedBy nullable
- reviewedAt nullable

### ImpactedMeasurement
- impactedMeasurementId
- impactAssessmentId
- measurementId
- workOrderId
- lotId
- measuredAt
- productId
- characteristicId
- sourceCompletenessState

### Certificate
- certificateId
- calibrationId
- certificateNumber
- issuedBy
- issuedAt
- blobUri
- blobVersionId
- immutableRetentionUntil
- status

### CompetencyAssertion
- userId
- competencyCode
- validFrom
- validTo
- sourceSystem
- checkedAt

### AuditEvent
- auditEventId
- aggregateType
- aggregateId
- eventType
- eventAt
- actorId
- correlationId
- payloadJson

## 4.2 State transitions

### CalibrationSession
- Draft -> InProgress
- InProgress -> Submitted
- Submitted -> Passed or Failed
- InProgress -> Cancelled
- Failed -> ImpactAssessment Pending/Complete/Partial
- Passed/Failed -> CertificateEligible only if all gating rules pass

### Important invariants
- As-left cannot exist before as-found is locked
- Failed if any as-found reading is out of tolerance
- Certificate cannot issue if:
  - competency check fails
  - impact assessment is partial or pending where failure exists
  - procedure revision is stale/unknown
  - reference standard invalid
  - required evidence missing

## 5. Data model recommendation

## 5.1 Relational schema outline

### Tables
- `instrument`
- `instrument_extension`
- `procedure_header`
- `procedure_test_point`
- `reference_standard`
- `traceability_chain`
- `calibration_session`
- `calibration_reading`
- `impact_assessment`
- `impacted_measurement`
- `impact_disposition`
- `certificate`
- `competency_check_log`
- `sync_operation`
- `audit_event`
- `integration_cache_procedure`
- `integration_cache_instrument`

## 5.2 Key constraints
- Unique `(instrument_id, calibration_id, test_point_sequence)` on readings
- Check constraint: `as_left_value IS NULL OR as_found_locked = 1`
- Check constraint: `as_found_locked = 1` iff `as_found_committed_at IS NOT NULL`
- Foreign key from certificate to calibration session
- Foreign key from impact assessment to failed calibration
- Non-update policy on `as_found_value` after lock, enforced via stored procedure or service-only write path plus DB trigger/audit

## 5.3 Index recommendations
- `instrument(next_due_date, criticality, location_id, status)`
- `calibration_session(instrument_id, completed_at desc)`
- `impact_assessment(calibration_id, status)`
- `impacted_measurement(impact_assessment_id, measured_at)`
- `audit_event(aggregate_type, aggregate_id, event_at desc)`

## 6. API contract proposal

## 6.1 External API style
- REST over HTTPS
- JSON
- OAuth2 bearer tokens via Entra ID
- Correlation ID required
- Idempotency key required for submit/issue operations
- Problem Details (`application/problem+json`) for errors

## 6.2 Core endpoints

### Due management
**GET** `/api/v1/instruments/due?locationId=&filter=&page=`
- Returns prioritized due/overdue list
- Includes freshness metadata for cached QMS data

**POST** `/api/v1/instruments/{instrumentId}/extensions`
- Creates documented extension
- Role-restricted to quality manager

### Calibration workflow
**POST** `/api/v1/calibrations`
- Starts calibration session for scanned instrument

**GET** `/api/v1/calibrations/{calibrationId}`
- Returns session, procedure revision, test points, standard eligibility, lock states

**POST** `/api/v1/calibrations/{calibrationId}/environment`
- Saves environmental conditions

**POST** `/api/v1/calibrations/{calibrationId}/readings/{sequence}/as-found`
- Commits as-found reading
- Locks reading on success

**POST** `/api/v1/calibrations/{calibrationId}/readings/{sequence}/as-left`
- Commits as-left reading only if as-found locked

**POST** `/api/v1/calibrations/{calibrationId}/submit`
- Evaluates all points and finalizes pass/fail

### Impact assessment
**POST** `/api/v1/calibrations/{calibrationId}/impact-assessments`
- Triggers deterministic impact assessment for failed calibration

**GET** `/api/v1/impact-assessments/{impactAssessmentId}`
- Returns scope, completeness state, and review status

**POST** `/api/v1/impact-assessments/{impactAssessmentId}/narrative:draft`
- Requests AI draft through APIM/Agent Framework

**POST** `/api/v1/impact-assessments/{impactAssessmentId}/review`
- Records engineer review and disposition summary

### Certificate
**POST** `/api/v1/calibrations/{calibrationId}/certificate:issue`
- Performs competency check and issues certificate if all gates pass

**GET** `/api/v1/certificates/{certificateId}`
- Returns metadata and secure retrieval link

### Sync
**POST** `/api/v1/sync/batch`
- Uploads offline operations with ordering and idempotency keys

**GET** `/api/v1/sync/status/{deviceId}`
- Returns last sync state and unresolved conflicts

## 6.3 Example contracts

### Commit as-found reading request
```json
{
  "value": 10.023,
  "unit": "mm",
  "capturedAt": "2026-08-27T10:15:00Z",
  "deviceId": "HH-204",
  "offlineCaptured": true
}
```

### Commit as-found reading response
```json
{
  "calibrationId": "CAL-100245",
  "testPointSequence": 3,
  "asFoundValue": 10.023,
  "asFoundLocked": true,
  "resultAsFound": "OutOfTolerance",
  "tolerance": {
    "min": 9.995,
    "max": 10.005,
    "unit": "mm"
  },
  "nextAllowedAction": "EnterAsLeft"
}
```

### Impact assessment response
```json
{
  "impactAssessmentId": "IA-8821",
  "calibrationId": "CAL-100245",
  "status": "Partial",
  "completenessFlag": false,
  "incompleteReason": "MES measurement history timeout after retries",
  "measurementWindow": {
    "start": "2026-05-01T08:00:00Z",
    "end": "2026-08-27T10:40:00Z"
  },
  "impactedMeasurements": [
    {
      "measurementId": "M-90001",
      "workOrderId": "WO-1002",
      "lotId": "LOT-77",
      "productId": "P-44",
      "measuredAt": "2026-06-10T11:00:00Z"
    }
  ],
  "certificateIssueBlocked": true
}
```

### Problem details example
```json
{
  "type": "https://example/errors/business-rule-violation",
  "title": "Certificate issue blocked",
  "status": 409,
  "detail": "Impact assessment is incomplete and certificate issue is not permitted.",
  "instance": "/api/v1/calibrations/CAL-100245/certificate:issue",
  "correlationId": "7d2d0f5d-0d2e-4d5d-9d8d-1e1d2c3b4a5f"
}
```

## 7. Integration design

## 7.1 Quality Management System
**Purpose:** instrument master and procedures  
**Pattern:** synchronous read with bounded cache  
**Rules:**
- Cache procedures with revision and retrieval timestamp
- If live fetch fails after retries, serve cached procedure with age shown
- Block certificate issue if procedure revision cannot be trusted current

## 7.2 MES measurement history
**Purpose:** impact assessment source  
**Pattern:** async function invocation from calibration service  
**Rules:**
- 20-second timeout, two retries
- If exhausted, mark assessment `Partial`
- Never present partial as complete
- Block certificate issue while partial/incomplete

## 7.3 Training records competency API
**Purpose:** certificate issue authorization  
**Pattern:** synchronous server-side check at issue time  
**Rules:**
- No client-side trust
- Log competency assertion used for issuance
- Fail closed if competency cannot be verified

## 7.4 Agent workflow via APIM
**Purpose:** draft impact narrative  
**Pattern:** service-to-APIM-to-Agent Framework  
**Rules:**
- Input only deterministic impact data and approved context
- Include correlation headers
- Store draft separately from approved narrative
- Require human review before attachment/finalization

## 8. Offline and synchronization design

## 8.1 Offline scope
Recommended offline-capable actions:
- View cached due list
- Start calibration from cached procedure/instrument data
- Capture environmental conditions
- Commit as-found and as-left locally
- Queue submit request

Not recommended offline:
- Certificate issue
- Final competency validation
- Final impact assessment completion
- Any action requiring authoritative external-system freshness

## 8.2 Local storage
Use encrypted local storage for:
- Cached procedures
- In-progress calibration sessions
- Pending sync operations
- Device-scoped metadata

Do not store:
- Long-lived tokens in insecure storage
- Full unnecessary historical datasets
- AI drafts unless explicitly needed and protected

## 8.3 Sync model
Each offline operation should include:
- operationId
- deviceId
- calibrationId
- sequenceNumber
- operationType
- payload
- capturedAt
- idempotencyKey

## 8.4 Conflict rules
1. **Procedure revision changed before sync**
   - Mark conflict
   - Require technician/manager review
   - Block certificate issue until resolved

2. **Reference standard expired before sync**
   - Mark calibration for review
   - Do not auto-issue certificate

3. **Duplicate reading submission**
   - Resolve by idempotency key
   - Do not create duplicate audit events

4. **Instrument already calibrated elsewhere**
   - Flag duplicate/inconsistent session
   - Require manual resolution

## 9. Security architecture

## 9.1 Identity and access
- Entra ID authentication
- Conditional access requiring compliant device
- Role-based access:
  - Metrology Technician
  - Quality Engineer
  - Quality Manager
  - Production Supervisor
  - System Admin
- Competency is separate from role and checked server-side

## 9.2 Authorization model
Examples:
- Technician can create and complete calibration sessions
- Technician cannot issue certificate unless competency valid and role permits
- Quality manager can grant extensions
- Quality engineer can review impact assessments
- Supervisor can view issue-block status

## 9.3 Data protection
- TLS 1.2+
- Encryption at rest for SQL and Blob
- Managed identity for service-to-service auth
- Immutable blob policies for issued certificates/evidence
- Minimize PII; store named attribution only where required for compliance

## 9.4 Auditability
Audit events required for:
- Calibration start/submit/cancel
- As-found commit and lock
- As-left commit
- Failure determination
- Impact assessment trigger/result/review
- Narrative draft request/review/approval
- Certificate issue
- Extension grant/expiry
- Competency check outcome

## 10. Threat model considerations

## 10.1 Key assets
- Calibration records
- As-found readings
- Impact assessment completeness state
- Certificate artifacts
- Competency assertions
- Procedure revision integrity
- Audit trail

## 10.2 Threats and mitigations

### Tampering with as-found values
**Threat:** user or attacker alters as-found after commit  
**Mitigations:**
- API forbids update
- DB-level immutability enforcement
- Append-only audit events
- Signed correlation and actor attribution in logs

### Using stale or invalid procedure
**Threat:** offline or cached procedure is superseded  
**Mitigations:**
- Cache age shown in UI
- Procedure revision persisted with calibration
- Certificate issue blocked if revision trust is uncertain

### Silent incomplete impact assessment
**Threat:** MES outage yields incomplete scope but UI implies complete  
**Mitigations:**
- Explicit `Partial` status
- Blocking rule on certificate issue
- UI badges and warning text
- Audit event for incomplete dependency result

### Unauthorized certificate issue
**Threat:** user without current competency issues certificate  
**Mitigations:**
- Server-side competency check at issue time
- no client-side override
- immutable issuance record with named issuer

### Prompt injection or unsafe model output
**Threat:** untrusted data influences narrative generation  
**Mitigations:**
- Treat all source data as untrusted
- bounded prompt templates
- APIM safety controls
- human review before use
- narrative separated from deterministic impact list

### Offline device compromise
**Threat:** local queued data altered  
**Mitigations:**
- encrypted local storage
- signed/idempotent operation envelopes where feasible
- device compliance policy
- server-side validation of all synced operations

## 11. Non-functional design mapping

## 11.1 Availability
- App Service Premium v3 with zone redundancy
- Paired-region warm standby
- Async functions for long-running impact/certificate tasks

## 11.2 Performance
Targets inferred from requirements:
- Due list load: < 3 seconds typical in Dev-like conditions
- Reading commit: near-real-time feedback, target < 1 second server response
- Impact assessment: deterministic list generation target within integration SLA; incomplete state surfaced immediately if timeout occurs
- Certificate generation: target < 30 seconds after all gates pass

## 11.3 Reliability
- Idempotent submit/issue endpoints
- Retry with backoff for external dependencies
- Dead-letter/error handling for async tasks
- Correlation IDs across all services

## 11.4 Compliance and retention
- Issued certificates retained 10 years
- Immutable storage policy on issued artifacts
- Full audit trail retained per quality/compliance policy
- Human approval gate preserved for AI narrative

## 11.5 Accessibility and usability
From UX inputs:
- Do not rely on color alone
- Announce tolerance results in text
- Locked as-found state visibly explained
- Glove-friendly handheld interactions
- Explicit offline/freshness indicators

## 12. Observability and operations

## 12.1 Logging
Log:
- correlationId
- userId/service principal
- deviceId
- calibrationId
- impactAssessmentId
- external dependency latency/outcome
- APIM model call metadata, excluding sensitive payloads where not needed

## 12.2 Metrics
- due list response time
- reading commit latency
- sync success/failure rate
- impact assessment completion vs partial rate
- certificate issue success/block rate
- competency check failure rate
- model call count, latency, token/cost metrics via APIM

## 12.3 Alerts
- spike in partial impact assessments
- certificate issue failures above threshold
- QMS or MES dependency degradation
- sync backlog growth
- unusual volume of extension grants
- APIM safety or quota violations

## 13. Implementation plan

## 13.1 Suggested work packages

### WP1 — Foundation
- Repo structure
- CI/CD pipelines
- environment configuration
- Entra auth integration
- APIM baseline policies
- SQL schema baseline
- Blob storage setup

### WP2 — Due management
- Instrument/procedure cache
- due list API
- overdue marking job
- extension workflow
- issue-block API contract

### WP3 — Guided calibration capture
- calibration session APIs
- test point rendering contract
- as-found lock enforcement
- tolerance evaluation
- reference standard validity checks
- environmental capture

### WP4 — Offline sync
- local queue model
- sync batch API
- conflict detection/resolution flows
- freshness indicators

### WP5 — Impact assessment
- failed calibration trigger
- MES query function
- completeness/partial-state model
- impact review UI

### WP6 — AI narrative workflow
- APIM-routed Agent Framework integration
- prompt template and bounded input schema
- draft/review/approval persistence
- audit events

### WP7 — Certificate issuance
- competency check integration
- certificate rendering
- immutable blob write
- retrieval metadata API

### WP8 — Hardening
- threat mitigation validation
- performance tests
- accessibility review
- disaster recovery rehearsal
- audit/reporting verification

## 13.2 Delivery sequence recommendation
1. Foundation
2. Due list + scheduling controls
3. Guided capture + immutability
4. Offline sync
5. Impact assessment deterministic engine
6. Certificate issuance
7. AI narrative workflow
8. Hardening and UAT

## 14. Testing strategy

## 14.1 Unit tests
- tolerance evaluation
- as-found lock rules
- certificate gating logic
- completeness-state logic
- sync conflict resolution

## 14.2 Integration tests
- QMS cache fallback
- MES timeout -> partial impact state
- training records competency enforcement
- blob immutability write path
- APIM-routed agent invocation

## 14.3 End-to-end tests
- due instrument to passed certificate
- failed calibration to partial impact block
- failed calibration to reviewed impact and certificate issue
- offline capture then sync
- stale procedure conflict handling

## 14.4 Security tests
- authorization matrix
- token misuse
- tamper attempts on locked readings
- prompt injection resilience
- local storage exposure review

## 15. Open design questions for review

1. **Offline issue-block policy:** requirements note this as TBD. Can any offline instrument issue ever be allowed?
2. **Mistaken as-found entry workflow:** should correction require cancellation and restart, or a governed exception process?
3. **Usage-based scheduling source:** where exactly does usage telemetry originate, and what is its update cadence?
4. **Procedure cache tolerance:** what maximum cache age is acceptable before calibration start is blocked?
5. **Certificate numbering scheme:** generated internally or allocated from an external quality system?
6. **Environmental evidence:** are photos/files required, or only numeric readings?
7. **Impact disposition granularity:** measurement-level, lot-level, work-order-level, or all three?
8. **Warm standby expectations in Dev:** full paired-region deployment in Dev, or production-only pattern documented now?

## 16. Review recommendation

This design is **architecturally viable** and aligned with the provided requirements and technical constraints, with the strongest aspects being:

- clear system-of-record boundaries
- deterministic compliance-critical logic
- explicit incomplete-state handling
- strong auditability and competency gating
- governed AI usage through APIM and human review

## 17. Proposed approval outcome

**Recommend conditional approval for detailed design / implementation planning**, subject to resolution of the open questions above, especially:

- offline issue policy
- as-found correction workflow
- procedure cache-age policy
- exact competency and certificate numbering rules

If helpful, I can next convert this into:
1. a **formal ADR set**,  
2. a **C4-style component/spec package**, or  
3. a **developer-ready backlog with architecture acceptance criteria**.