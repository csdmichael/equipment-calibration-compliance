# Delivery plan — Equipment Calibration Compliance

Sprints are two weeks. Each sprint closes with a demo and an approval gate.

| Sprint | Focus | Exit criteria |
| --- | --- | --- |
| Sprint 1 | Foundation: repo, pipelines, schema | CI green, API deployed |
| Sprint 2 | Core scope | Approved user stories delivered |
| Sprint 3 | Hardening and release | Tests pass, release gate approved |

## Approved scope

- Calibration Scheduling and Due Management (FEAT-01)
- Guided Calibration Capture (FEAT-02)
- Out-of-Tolerance Impact Assessment (FEAT-03)
- Certificate Generation and Traceability (FEAT-04)
- **Endpoints:**
- `/instruments/due` (GET): Returns instruments due/overdue, sorted by days to due and criticality.
- `/calibrations/start` (POST): Initiates calibration, returns procedure, test points, tolerances, reference standard options.
- `/calibrations/{id}/capture` (PATCH): Captures as-found/as-left readings, locks as-found, evaluates tolerance.
- `/calibrations/{id}/submit` (POST): Submits calibration, triggers impact assessment if failed.
- `/impact-assessment/{instrument_id}` (GET): Returns measurements since last passing calibration.
- `/certificates/{calibration_id}/generate` (POST): Generates certificate, checks competency, stores in Blob.
- **Models:**
