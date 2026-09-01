---
name: tetris-workflow-router
description: Resolve this project's Base shared and project-local Skills through its verified v9.1 operating contracts.
---

# Project Workflow Router

Before selecting any route, run the project operating-contract validator for
this repository and its pinned Base checkout. On a nonzero result, stop; do
not infer, repair, or execute a route. Then read only
`skills/PROJECT_BASE_ADAPTER.json` and the generated
`skills/PROJECT_SKILL_SNAPSHOT.json`.

Resolve `effective_routes` exactly as generated. Project-local routes take
precedence over same-name Base routes. Follow the selected recorded package at
its path; this router contains no copied Base shared Skill body.
