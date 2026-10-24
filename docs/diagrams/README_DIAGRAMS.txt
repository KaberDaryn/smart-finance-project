SMART FINANCE — DIAGRAMS BASED ON PROBATIONARY PERIOD 1 REPORT

These diagrams were redrawn from Section 7 (pages 17–19) of:
SE-2430_Kaber_ProbPeriod1 (1).pdf

Files:
- 01_System_Context.png / .pdf — system boundary, user, team operator, financial storage and optional Gemini provider
- 02_Use_Case.png / .pdf — user actions and requirements FR01–FR13, with consent/review before receipt-assisted save
- 03_Component_Diagram.png / .pdf — Flutter and separate JavaScript clients, Python backend modules, storage and analytics
- *.dot — Graphviz editable sources
- *.mmd — Mermaid editable sources

Accuracy notes taken from the report:
- SQLite is the verified local path; PostgreSQL is an alternative adapter, not a concurrently required store.
- Gemini is optional; receipt data is sent only after consent.
- Provider output is a proposal, not a trusted record; user review and explicit save are required.
- The separate JavaScript client is not assumed to be feature-equivalent to Flutter.
- Diagrams document the architecture; they do not prove that all requirements have passed.

Recommended repository location: docs/diagrams/
