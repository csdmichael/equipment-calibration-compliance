# Equipment Calibration Compliance — API

FastAPI service. Owns validation, authorization, and all database access.

| Path | Purpose |
| --- | --- |
| `/health` | Liveness probe |
| `/docs` | Swagger UI |
| `/openapi.json` | OpenAPI document |
| `/api/compliances` | Compliances collection (GET, POST) |
| `/api/compliances/{id}` | Single compliance (GET, PATCH, DELETE) |
