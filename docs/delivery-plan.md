# Delivery plan — Equipment Calibration Compliance

Sprints are two weeks. Each sprint closes with a demo and an approval gate.

| Sprint | Focus | Exit criteria |
| --- | --- | --- |
| Sprint 1 | Foundation: repo, pipelines, schema | CI green, API deployed |
| Sprint 2 | Core scope | Approved user stories delivered |
| Sprint 3 | Hardening and release | Tests pass, release gate approved |

## Approved scope

- `HelpPageComponent` (help page)
- `FaqPageComponent` (FAQ page)
- Add routes for `/help` and `/faq`
- Update navigation (tab bar or menu) to include Help and FAQ
- Ensure both pages are accessible (ARIA, keyboard navigation, readable text)
- Help page: Overview, navigation tips, calibration workflow summary, offline mode, certificate issue, impact assessment, contact/support info
- FAQ page: Common questions (e.g., "How do I start a calibration?", "What happens if an instrument is overdue?", "How is as-found data locked?", "How do I access certificates?", "What if the impact assessment is incomplete?")
- No backend changes required unless dynamic FAQ/help content is desired (not in scope for this revision).
- **Requirements:** Not explicitly listed in original requirements, but aligns with non-functional requirements for usability, auditability, and support.
- **UX Mockups:** Navigation-flow map supports additional screens; tab bar/menu can accommodate Help/FAQ.
- **Technical Requirements:** No backend dependency; frontend-only change.
- **HelpPageComponent**
