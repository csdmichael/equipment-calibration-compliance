# API contracts — Equipment Calibration Compliance

The OpenAPI document is the authoritative contract: Swagger UI at `/docs`, raw document at `/openapi.json`. This table is the summary.

| Method | Path | Purpose | Response |
| --- | --- | --- | --- |
| `GET` | `/health` | Liveness probe used by the deploy pipeline | `{"status": "ok"}` |
| `GET` | `/api/compliances` | List compliances; `?status=` filters | `Compliance[]` |
| `POST` | `/api/compliances` | Create a compliance | `201` + `Compliance` |
| `GET` | `/api/compliances/{id}` | Fetch one compliance | `Compliance` or `404` |
| `PATCH` | `/api/compliances/{id}` | Partial update | `Compliance` or `404` |
| `DELETE` | `/api/compliances/{id}` | Remove a compliance | `204` or `404` |

## `Compliance`

| Field | Type | Notes |
| --- | --- | --- |
| `id` | integer | Server assigned |
| `title` | string | Required, 1–400 characters |
| `reference` | string | Optional, up to 200 characters |
| `status` | enum | `new`, `in-progress`, `complete` |
| `priority` | enum | `low`, `normal`, `high` |
