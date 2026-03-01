---
commit: "9d8d8ea9ceaba996b19c790afd74942f2a10d111"
date: "2026-02-22T13:48:45+01:00"
author: "Michael Schürig <michael@schuerig.de>"
subject: "Add arc42 architecture documentation for developers"
sessions: ["3932b7a0-f2aa-42ce-bad0-c4527cbe1cc5"]
prev: "e8c8039273.md"
next: "1a386a241c.md"
---

[← Previous (e8c8039273)](e8c8039273.md) | [Index](index.md) | [Next (1a386a241c) →](1a386a241c.md)

# Commit 9d8d8ea9ce

**Date:** 2026-02-22 13:48:45 UTC+01:00  
**Author:** Michael Schürig <michael@schuerig.de>

## Commit message

Add arc42 architecture documentation for developers

10 sections covering introduction, constraints, context, solution strategy,
building blocks, runtime views, crosscutting concepts, architecture decisions,
quality requirements, and risks/technical debt. Skips deployment view (trivial
for local-only iOS app) and glossary (already exists in planning-artifacts).

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## Changed files

```
docs/arc42/01-introduction-and-goals.md   |  41 +++++++
 docs/arc42/02-constraints.md              |  35 ++++++
 docs/arc42/03-context-and-scope.md        |  49 ++++++++
 docs/arc42/04-solution-strategy.md        |  38 ++++++
 docs/arc42/05-building-block-view.md      | 163 +++++++++++++++++++++++++
 docs/arc42/06-runtime-view.md             | 191 ++++++++++++++++++++++++++++++
 docs/arc42/08-crosscutting-concepts.md    | 127 ++++++++++++++++++++
 docs/arc42/09-architecture-decisions.md   | 113 ++++++++++++++++++
 docs/arc42/10-quality-requirements.md     |  86 ++++++++++++++
 docs/arc42/11-risks-and-technical-debt.md |  86 ++++++++++++++
 docs/arc42/index.md                       |  25 ++++
 11 files changed, 954 insertions(+)
```

## Session `3932b7a0…`

*2026-02-22 12:25:15 UTC → 2026-02-22 12:48:52 UTC*

### 🧑 Human (12:25:15)

<command-message>bmad-bmm-document-project</command-message>
<command-name>/bmad-bmm-document-project</command-name>

### 🤖 Assistant (12:25:18)

I'll start by loading the workflow engine and the specific workflow configuration.

### 🤖 Assistant (12:25:23)

Now I'll load the config source and the instructions file, plus the template-related files.

### 🤖 Assistant (12:25:37)

All components loaded and variables resolved:

- **project_name**: peach
- **user_name**: Michael
- **output_folder**: `/Users/michael/Projekte/peach/docs`
- **communication_language**: English
- **document_output_language**: English
- **user_skill_level**: intermediate
- **date**: 2026-02-22
- **installed_path**: `/Users/michael/Projekte/peach/_bmad/bmm/workflows/document-project`

This is an **action-workflow** (no template). Now executing the instructions.

---

**Step 1: Validate workflow and get project info**

Let me check for the workflow-status module and project status file.

### 🤖 Assistant (12:25:45)

No workflow-status module found. Running in **standalone mode** without progress tracking.

> Note: Documentation workflow can run standalone. Continuing without progress tracking.

---

**Step 2: Check for resumability and determine workflow mode**

Checking for existing state file.

### 🤖 Assistant (12:25:49)

No state file found. Moving to Step 3.

---

**Step 3: Check for existing documentation and determine workflow mode**

### 🤖 Assistant (12:25:54)

No existing documentation found. **Starting initial project scan...**

Setting `workflow_mode = "initial_scan"`. Now loading the full scan instructions.

### 🤖 Assistant (12:26:05)

**Step 0.5: Loading documentation requirements data**

**How Project Type Detection Works:**

This workflow uses a single comprehensive CSV file to intelligently document your project:

- Contains 12 project types (web, mobile, backend, cli, library, desktop, game, data, extension, infra, embedded)
- 24-column schema combining project type detection AND documentation requirements
- Acts as a "scan guide" - tells the workflow WHERE to look and WHAT to document

Loaded documentation requirements for all 12 project types.

---

**Step 0.6: Workflow mode determined**

No existing `index.md` found. Setting `workflow_mode = "initial_scan"`.

Now I need your input on scan depth:

### 🤖 Assistant (12:26:46)

What would you like to clarify about the scan level options, Michael? Happy to explain the differences in more detail or answer any questions before we proceed.

### 🧑 Human (12:28:24)

I'm not looking to reverse engineer a PRD, we already have one. I'm trying to generate architecture documentation for developers trying to understand the app. Think of https://arc42.org/overview .

### 🤖 Assistant (12:28:36)

Got it - that's a different goal than what this workflow is optimized for. The document-project workflow is focused on brownfield analysis to feed into PRD creation, but you want **developer-facing architecture documentation** in the arc42 style.

Let me first understand what you already have, then we can figure out the best approach.

### 🤖 Assistant (12:30:20)

Great, now I have a thorough understanding of Peach. You have rich documentation scattered across planning artifacts, implementation stories, and project-context.md — but no consolidated, developer-facing architecture reference.

An **arc42-style document** would pull together what exists into a single navigable structure. Based on what I found, here's how the arc42 sections map to your project:

| Arc42 Section | Source Material Available |
|---|---|
| 1. Introduction & Goals | prd.md, README |
| 2. Constraints | project-context.md (85 rules), NFRs |
| 3. Context & Scope | Single-user offline iOS app — simple system context |
| 4. Solution Strategy | architecture.md, tech stack choices |
| 5. Building Block View | Source structure, service boundaries, protocols |
| 6. Runtime View | TrainingSession state machine, observer flow, audio pipeline |
| 7. Deployment View | Minimal (iOS app, no backend) |
| 8. Crosscutting Concepts | DI via @Environment, concurrency model, error handling, testing |
| 9. Architecture Decisions | architecture.md, hotfix docs, story design decisions |
| 10. Quality Requirements | NFRs, testing strategy, accessibility |
| 11. Risks & Technical Debt | future-work.md (18 items) |
| 12. Glossary | glossary.md (already exists) |

### 🤖 Assistant (12:32:01)

Sharded `docs/arc42/` with 10 sections (skipping Deployment View and Glossary). Let me read the key source material to build accurate documentation.

### 🤖 Assistant (12:32:06)

Good, I have all the source material. Let me now read the key source files for accurate building block and runtime documentation.

### 🤖 Assistant (12:32:25)

I have everything I need. Let me start generating the arc42 documentation section by section. I'll begin with the index and Section 1 (Introduction & Goals).

### 🤖 Assistant (12:33:12)

**Section 1: Introduction and Goals** is written.

It covers:
- What Peach is and the "training, not testing" philosophy
- Three core capabilities the architecture must support (training loop, audio precision, perceptual profile)
- Quality goals ranked by priority
- Stakeholders

How would you like to proceed?

- **[c] Continue** — I'll write Section 2 (Constraints)
- **[a] Advanced Elicitation** — Deeper discussion on this section
- **[y] YOLO** — I'll generate all remaining sections without stopping

### 🧑 Human (12:39:42)

y

### 🤖 Assistant (12:39:46)

YOLO mode activated. Generating all remaining sections.

### 🤖 Assistant (12:44:31)

All 10 sections are written. Let me verify the output.

### 🤖 Assistant (12:44:42)

---

**Arc42 Architecture Documentation Complete, Michael!**

**Generated in `docs/arc42/`:**

| File | Section | Size |
|---|---|---|
| `index.md` | Entry point with navigation | 1.5K |
| `01-introduction-and-goals.md` | What Peach is, quality goals, stakeholders | 2.9K |
| `02-constraints.md` | Technical, organizational, conventions | 2.7K |
| `03-context-and-scope.md` | System boundary diagram, external interfaces | 2.5K |
| `04-solution-strategy.md` | Technology table, architectural approach, key decisions | 3.3K |
| `05-building-block-view.md` | Component diagram, all services and views documented | 8.7K |
| `06-runtime-view.md` | Training loop, startup, interruptions, lifecycle, settings flow | 8.1K |
| `08-crosscutting-concepts.md` | DI, concurrency, observer pattern, error handling, testing | 4.9K |
| `09-architecture-decisions.md` | 9 ADRs with context/decision/rationale | 6.2K |
| `10-quality-requirements.md` | Quality tree + 6 quality scenarios with measures | 3.6K |
| `11-risks-and-technical-debt.md` | 4 risks, debt by priority, UX gaps | 6.3K |

**Total:** ~51K across 11 files. All content derived from actual source code and existing documentation — no placeholders, no TODOs.

### 🧑 Human (12:48:32)

commit this

### 🤖 Assistant (12:48:52)

Committed as `9d8d8ea` — 11 files, 954 lines added.

---

[← Previous (e8c8039273)](e8c8039273.md) | [Index](index.md) | [Next (1a386a241c) →](1a386a241c.md)
