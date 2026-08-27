## Code Generation Agent — Build-Stage Proposal  
**Project:** Equipment Calibration Compliance  
**Environment:** Dev  
**Source readiness:** Requirements + technical constraints + UX wireframes (draft); no verified design spec or codebase snapshot supplied. All referenced files must be validated in-repo before implementation.

---

### 1. Objectives for this build increment
| Feature | Requirement trace | Intended outcome |
| --- | --- | --- |
| FEAT-01 Calibration scheduling & due management | US-101, US-102, UX SCR-01 | Persist instrument schedule data, expose authoritative due/overdue list, enforce issue block + extension workflow. |
| FEAT-02 Guided calibration capture | US-201, US-202, UX SCR-02 | Drive procedure execution step-by-step, lock as-found values, gate as-left entry, evaluate tolerances in real time. |
| FEAT-03 Out-of-tolerance impact assessment (service stubs) | Req §3.3 (truncated), Technical §4 | Prepare API contracts, DB structures, and integration seams so downstream agent workflow and quality review can hook in once upstream services are ready. |
| FEAT-06 Identity, competency, audit controls | Technical §2 & §4 | Enforce Entra ID auth, competency verification, and immutable audit events for actions (extensions, calibration submission). |
| FEAT-07 Platform integrations & ops | Technical §2–4 | Harden service telemetry, retries, offline sync envelopes, and APIM hooks needed during MVP execution. |

> **Assumption:** The repository already contains a monorepo with `client/` (Angular + Ionic) and `api/` (FastAPI) directories plus infrastructure files. This proposal references common conventions (e.g., Nx workspace, Poetry-managed FastAPI). These must be confirmed before coding.

---

### 2. Proposed implementation plan

#### 2.1 Data & persistence (Azure SQL via SQLAlchemy or equivalent)
1. **Instrument schedule tables**
   - `instruments` (id, description, location_id, criticality, interval_days, usage_basis, last_calibration_id, owner_contact).
   - `instrument_due_view` (materialized or SQL view) computing `days_to_due`, `due_status` (due/overdue/extended), `extension_id`.
2. **Extensions**
   - `instrument_extensions` (id, instrument_id, expires_at, justification, approver_id, approved_by_role, created_at, created_by_id). Add unique constraint enforcing one active extension per instrument.
3. **Calibrations & readings**
   - `calibrations` (id, instrument_id, procedure_id, procedure_revision, reference_standard_id, environmental_snapshot, competency_check_id, status enum {IN_PROGRESS, PASS, FAIL}, started_at, submitted_at, submitted_by).
   - `calibration_points` (id, calibration_id, sequence, nominal_value, tolerance_plus, tolerance_minus, as_found_value, as_found_entered_at, as_left_value, as_left_entered_at, result enum {PENDING, IN_TOLERANCE, OUT_OF_TOLERANCE}, immutable constraint on `as_found_value` once set).
4. **Impact scaffolding**
   - `impact_assessments` (id, calibration_id, status, measurement_range_start/end, completeness_flag, narrative_draft_blob_uri, approved_narrative_at, approved_by).
   - `impact_measurements` to store resolved MES records; include `source_system_sync_token` for resumable fetch.
5. **Audit trail**
   - `audit_events` table for extension approvals, calibration submission, certificate issue, competency checks.

*Migration deliverable:* Alembic/SQL migration script with up/down methods, ensuring NOT NULL + FK constraints and indexes on `due_status`, `instrument_id`.

#### 2.2 FastAPI service changes (`api/`)

1. **Schemas (`app/schemas` or `api/models`)**
   - Pydantic models for `InstrumentDueItem`, `ExtensionRequest`, `CalibrationSession`, `CalibrationPointInput`, `ImpactAssessment`.
   - Enforce as-found immutability in schema: raise validation error when `as_found_value` already stored.
2. **Routers**
   - `GET /instruments/due` with query params `filter` (ALL|OVERDUE|MY_LOCATION) + pagination. Includes extension metadata and enforcement flag.
   - `POST /instruments/{id}/extensions` requiring QM role, verifying `expires_at` > now and justification.
   - `POST /calibrations` to start session (locks instrument if not overdue & competency validated).
   - `POST /calibrations/{id}/points/{sequence}/as-found` and `.as-left` endpoints to support offline sync-friendly granular updates; responses include tolerance evaluation result.
   - `POST /calibrations/{id}/submit` to finalize; triggers tolerance summary, impact assessment kickoff stub, certificate gating (but not issuance yet).
   - `POST /calibrations/{id}/impact/prepare` (stub) storing MES request envelope + returning status (complete, partial, blocked).
3. **Services**
   - `DueListService` (fetch view, apply role-based filters, raise `InstrumentOverdueError` for tool-crib scenarios).
   - `CalibrationService` (procedure retrieval, reference standard validation via QMS API, as-found lock enforcement, status transitions).
   - `ImpactService` (MES API client w/ retry/backoff, partial completion flag, APIM route builder for Foundry narrative).
4. **Integrations**
   - QMS API client with caching fallback per Technical §4 (2s timeout, 3 retries, block certificate if stale).
   - MES API placeholder: implement client interface and response model; returns deterministic list or flagged partial.
   - Training records API call in calibration start: ensures competency requirement satisfied; store response token.
5. **Security**
   - Dependency for Entra ID JWT validation (FastAPI + `msal` or `pyjwt`), extracting roles/locations.
   - Authorization guards: technicians vs QM vs supervisor.
6. **Telemetry & resilience**
   - Structured logging (OpenTelemetry) for due list loads, calibration submissions, extension approvals.
   - Circuit breaker or backoff wrappers for external APIs; propagate partial/incomplete states to clients.

#### 2.3 Front-end (Angular 18 + Ionic 8 under `client/`)
1. **State management** (NgRx or Signals-based store)
   - `DueListStore`: actions for load/filter, selectors for due segments, offline snapshot.
   - `CalibrationSessionStore`: track active procedure, locked points, environment readings.
2. **Screens**
   - `CalibrationDueListPage` aligning with SCR-01: filter chips, instrument cards, extension badges, offline indicators.
   - `GuidedCalibrationPage` aligning with SCR-02: reference standard picker w/ validity badges, environmental capture, per-point wizard with as-found lock UI.
3. **Components**
   - `InstrumentCardComponent`, `ExtensionBadgeComponent`, `TestPointStepperComponent`.
4. **Offline support**
   - Service worker caching for due list + active calibration data; background sync queue for point submissions using IndexedDB.
5. **API layer**
   - Angular services for due list, extensions, calibration operations; include HTTP interceptors for auth token + correlation IDs + APIM headers.
6. **Validation & UX**
   - Numeric validator enforcing measuring range per test point metadata.
   - Accessibility: ARIA labels for filter chips, audible status updates when as-found locks or tolerance status changes.

#### 2.4 Certificates & storage (scaffolding only this increment)
- Create interface for Certificate Generator Azure Function (HTTP trigger) but stub actual call; ensure calibration submission stores payload needed later (procedure revision, reference standard, environmental conditions, tolerance summary).
- Blob Storage client wrapper (SAS via managed identity) prepared for eventual certificate PDF write.

---

### 3. Testing strategy

| Layer | Tests | Notes |
| --- | --- | --- |
| DB migrations | Migration smoke test script verifying new tables + constraints + view logic (due status). | Run via `pytest` fixture hitting ephemeral SQL DB. |
| FastAPI unit tests | `tests/unit/test_due_service.py`, `test_calibration_service.py`, `test_impact_service.py`. Cover: filtering, extension validation, as-found immutability, partial impact flags. | Use dependency overrides/mocks for QMS, MES, Training APIs. |
| FastAPI integration tests | `tests/api/test_due_list_api.py`, `test_calibration_flow.py`. Use TestClient + sqlite or test db; simulate calibration from start to submit incl. tolerance fail. | Validate HTTP 403 for unauthorized roles. |
| Front-end unit tests | Component specs via Jest/Vitest: filter chip behavior, card accessibility, test point wizard locking state. | Mock HTTP services. |
| Front-end e2e (Cypress/Cypress Component Testing) | Scenario: load due list, apply filters, show overdue badge; start calibration, enter as-found/out-of-tolerance path, ensure failure flagged. | Use MSAL test token injection. |
| Offline sync tests | Service worker/unit tests verifying queue flush order + conflict resolution (server wins). |
| Security tests | Validate role guard denies extension creation to technicians; verify JWT lacking competency claim triggers 403 at calibration start. |

---

### 4. Risks, mitigations, open questions

| Risk / question | Impact | Mitigation / decision needed |
| --- | --- | --- |
| Requirements docs are drafts; acceptance criteria may shift. | Rework. | Obtain stakeholder sign-off before coding; flag deltas. |
| Repository structure + tooling assumptions (FastAPI app layout, Angular workspace) unverified. | Estimation inaccuracy, setup churn. | Schedule repo discovery task; update proposal with concrete file paths post-inspection. |
| MES API spec not provided (timeouts, payload schema). | Impact service can’t be completed. | Implement provider interface + mock responses; block certificate issuance until flag cleared. |
| Offline-first complexity (service worker, IndexedDB) may exceed sprint capacity. | Delay due list release. | Scope initial offline behavior to caching + queued calibration submissions only; treat due list offline read as stretch. |
| Competency verification integration details missing. | Calibration start may be blocked erroneously. | Define fallback (e.g., cached competency TTL) with QA owner; log when stale. |

---

### 5. Next steps / approvals needed
1. **Repository discovery:** Confirm actual directories, build tooling, and existing models/tests. Update this plan with exact file paths.
2. **Data model review:** Validate proposed tables and fields with DBA + quality owner.
3. **API contract review:** Align FastAPI endpoint signatures with front-end and integration consumers.
4. **UX validation:** Ensure screen behaviors align with SCR-01/02 accessibility notes.
5. **Security review:** Confirm Entra ID scopes/roles, competency attribute availability, and APIM headers.

Upon approval, we can proceed to detailed task breakdown (tickets) and start implementing migrations, backend endpoints, and front-end components per this proposal.