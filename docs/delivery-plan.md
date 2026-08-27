# Delivery plan — Equipment Calibration Compliance

Sprints are two weeks. Each sprint closes with a demo and an approval gate.

| Sprint | Focus | Exit criteria |
| --- | --- | --- |
| Sprint 1 | Foundation: repo, pipelines, schema | CI green, API deployed |
| Sprint 2 | Core scope | Approved user stories delivered |
| Sprint 3 | Hardening and release | Tests pass, release gate approved |

## Approved scope

- **Instrument schedule tables**
- `instruments` (id, description, location_id, criticality, interval_days, usage_basis, last_calibration_id, owner_contact).
- `instrument_due_view` (materialized or SQL view) computing `days_to_due`, `due_status` (due/overdue/extended), `extension_id`.
- **Extensions**
- `instrument_extensions` (id, instrument_id, expires_at, justification, approver_id, approved_by_role, created_at, created_by_id). Add unique constraint enforcing one active extension per instrument.
- **Calibrations & readings**
- `calibrations` (id, instrument_id, procedure_id, procedure_revision, reference_standard_id, environmental_snapshot, competency_check_id, status enum {IN_PROGRESS, PASS, FAIL}, started_at, submitted_at, submitted_by).
- `calibration_points` (id, calibration_id, sequence, nominal_value, tolerance_plus, tolerance_minus, as_found_value, as_found_entered_at, as_left_value, as_left_entered_at, result enum {PENDING, IN_TOLERANCE, OUT_OF_TOLERANCE}, immutable constraint on `as_found_value` once set).
- **Impact scaffolding**
- `impact_assessments` (id, calibration_id, status, measurement_range_start/end, completeness_flag, narrative_draft_blob_uri, approved_narrative_at, approved_by).
- `impact_measurements` to store resolved MES records; include `source_system_sync_token` for resumable fetch.
- **Audit trail**
