---
commit: "e5dfaa5c357535974b50c91f0e6376501fd4de85"
date: "2026-02-23T15:46:26+01:00"
author: "Michael Schürig <michael@schuerig.de>"
subject: "Add story: SF2 sample download caching in build process"
sessions: ["7ab64c08-81b1-46fb-b1a2-285d17bbd553"]
prev: "ea2fca2147.md"
next: "f1e596a6c8.md"
---

[← Previous (ea2fca2147)](ea2fca2147.md) | [Index](index.md) | [Next (f1e596a6c8) →](f1e596a6c8.md)

# Commit e5dfaa5c35

**Date:** 2026-02-23 15:46:26 UTC+01:00  
**Author:** Michael Schürig <michael@schuerig.de>

## Commit message

Add story: SF2 sample download caching in build process

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## Changed files

```
.../infra-sf2-build-download-cache.md              | 192 +++++++++++++++++++++
 docs/implementation-artifacts/sprint-status.yaml   |   3 +
 2 files changed, 195 insertions(+)
```

## Session `7ab64c08…`

*2026-02-23 14:29:14 UTC → 2026-02-23 14:46:59 UTC*

### 🧑 Human (14:29:14)

<command-message>bmad-bmm-create-story</command-message>
<command-name>/bmad-bmm-create-story</command-name>
<command-args>Look at docs/planning-artifacts/research/technical-sampled-instrument-noteplayer-research-2026-02-23.md . I don't want to add large instrument samples to the repository. Instead, I want you to extend the build process so that the samples archive is downloaded to a cache location. On further builds, the cached file is used. Create a story to extend the build process as needed.</command-args>

### 🤖 Assistant (14:29:17)

I'll start by loading the workflow system files and understanding the process.

### 🤖 Assistant (14:29:22)

Now let me load the config, instructions, template, and the referenced research document.

### 🤖 Assistant (14:29:54)

Now let me follow the workflow instructions. **Step 1: Determine target story.** The user hasn't provided an epic-story number. Let me check the sprint status and epics files.

### 🤖 Assistant (14:30:39)

I've loaded the workflow configuration and all core files. Let me proceed with **Step 1: Determine target story**.

There are no backlog stories in the sprint status. The user has explicitly requested a **new standalone story** for extending the build process with SF2 sample download caching. This doesn't fit into any existing epic — it's infrastructure work, similar to the existing hotfix entries.

Let me load the project context and architecture to understand the current build process before proposing a story key.

### 🤖 Assistant (14:30:44)

Now let me explore the current build process and project structure to understand what exists.

### 🤖 Assistant (14:32:34)

Good. Now I have a full picture of the project:

- **No existing build scripts** — no Xcode Run Script build phases, no Makefile, no Fastfile
- **`tools/` directory** has two Python utility scripts
- **Resources/** has only Assets.xcassets and Localizable.xcstrings — no audio/sample files yet
- **.gitignore** is minimal and would need entries for cached downloads

This story is standalone infrastructure work, not part of an existing epic. I need to determine a story key. Given the convention of hotfix/standalone entries in the sprint status (e.g., `hotfix-tune-kazez-convergence`), I'll propose:

**`infra-sf2-build-download-cache`** — Infrastructure: SF2 sample download caching in build process

Before I generate the story, let me confirm the scope I'll be writing. Based on the research and your request, the story will cover:

1. **A build-time script** (in `tools/`) that downloads the GeneralUser GS SF2 archive to a cache location (e.g., `~/.cache/peach/`)
2. **An Xcode Run Script Build Phase** that invokes the script, copying the cached SF2 into the app bundle
3. **Cache-on-first-download** — subsequent builds reuse the cached file
4. **`.gitignore` entries** to exclude the cached/downloaded samples from the repo

Now let me initialize the output file and generate the first section.

### 🤖 Assistant (14:32:43)

Good. The standalone stories use descriptive kebab-case names. Now let me generate the story. I'll write the **story header** section first.

### 🤖 Assistant (14:33:22)

**Story header generated.** Here's what I've written:

- **Story key:** `infra-sf2-build-download-cache`
- **Title:** SF2 Sample Download Caching in Build Process
- **Status:** ready-for-dev

Options: **[a]** Advanced Elicitation, **[c]** Continue, **[p]** Party-Mode, **[y]** YOLO the rest of this document only

### 🧑 Human (14:34:29)

c

### 🤖 Assistant (14:34:33)

Generating the **story requirements** section — user story statement and acceptance criteria.

### 🤖 Assistant (14:35:06)

**Story requirements generated.** Key points:

- **User story:** Developer-facing, keeping large samples out of git while making them available at build time
- **7 acceptance criteria** covering: first download, cache hit, checksum mismatch, network failure, gitignore, script quality, and Xcode build phase integration
- **Cache location:** `~/.cache/peach/` (persistent, user-level, survives clean builds)
- **Integrity:** SHA-256 checksum verification
- **Config-driven:** URL and checksum in a version-controlled config, not hardcoded
- **Zero new dependencies:** uses only standard macOS tools (`curl`, `shasum`, `mkdir`, `cp`)

Options: **[a]** Advanced Elicitation, **[c]** Continue, **[p]** Party-Mode, **[y]** YOLO the rest of this document only

### 🧑 Human (14:35:52)

c

### 🤖 Assistant (14:35:55)

Generating the **developer context section** — tasks, subtasks, and implementation guidance.

### 🤖 Assistant (14:36:20)

**Developer context section generated.** 5 tasks with detailed subtasks:

1. **Config file** — `tools/sf2-sources.json` with URL, filename, SHA-256
2. **Shell script** — `tools/download-sf2.sh` with cache-check, download, checksum verify, copy to bundle, error handling
3. **Xcode build phase** — Run Script before Copy Bundle Resources, with input/output file lists for incremental builds
4. **`.gitignore`** — exclude SF2 files from repo
5. **End-to-end verification** — clean build, cache hit, corrupt file, network failure, bundle output

Options: **[a]** Advanced Elicitation, **[c]** Continue, **[p]** Party-Mode, **[y]** YOLO the rest of this document only

### 🧑 Human (14:36:30)

c

### 🤖 Assistant (14:36:33)

Generating the **technical requirements** section — architecture compliance, implementation specifics, and guardrails.

### 🤖 Assistant (14:37:07)

**Technical requirements, architecture compliance, library/framework, file structure, and testing sections generated.**

Key guardrails for the dev agent:
- **`set -euo pipefail`** for strict error handling in the script
- **Temp file + rename pattern** to avoid corrupted cache from partial downloads
- **Xcode build variables** (`SRCROOT`, `BUILT_PRODUCTS_DIR`) — no hardcoded paths
- **Zero dependencies** — only stock macOS tools, consistent with the project's architecture
- **No Swift code changes** — purely build infrastructure
- **No Swift tests** — manual verification via build scenarios

Options: **[a]** Advanced Elicitation, **[c]** Continue, **[p]** Party-Mode, **[y]** YOLO the rest of this document only

### 🧑 Human (14:40:38)

y

### 🤖 Assistant (14:40:50)

YOLO mode activated. Generating all remaining sections and finalizing the story.

Let me gather the last pieces of intelligence — recent git history and the GeneralUser GS download source.

### 🤖 Assistant (14:44:04)

Good — I have enough information. Now let me generate all remaining sections and finalize the story.

### 🤖 Assistant (14:44:30)

Now let me run the validation checklist and update the sprint status.

### 🤖 Assistant (14:44:48)

Story content complete. Now performing validation and updating sprint status.

Self-validation against the checklist (YOLO mode — simulated expert review):

- User story with clear role/action/benefit
- 7 BDD acceptance criteria covering: first download, cache hit, checksum mismatch, network failure, gitignore, script quality, Xcode build phase
- 5 tasks with 20 subtasks, all mapped to ACs
- Technical guardrails: `set -euo pipefail`, temp file pattern, Xcode env vars, `curl` flags, checksum verification
- Architecture compliance: zero dependencies, `tools/` convention, no Swift changes
- File structure: clear new/modified/unchanged breakdown
- Testing: manual verification steps (appropriate for shell script infrastructure)
- References: all sources cited with paths

No critical gaps found. Now updating sprint status.

### 🤖 Assistant (14:45:03)

**ULTIMATE BMad Method STORY CONTEXT CREATED, Michael!**

**Story Details:**
- **Story Key:** `infra-sf2-build-download-cache`
- **File:** `docs/implementation-artifacts/infra-sf2-build-download-cache.md`
- **Status:** ready-for-dev
- **Sprint Status:** Updated

**What was created:**
- User story for SF2 sample download caching in the build process
- 7 BDD acceptance criteria (first download, cache hit, checksum mismatch, network failure, gitignore, script quality, Xcode build phase)
- 5 tasks / 20 subtasks covering config file, shell script, Xcode integration, gitignore, and end-to-end verification
- Technical guardrails: `set -euo pipefail`, temp-file-then-rename, SHA-256 checksum, Xcode env vars
- GeneralUser GS download source research with candidate URLs
- Architecture compliance notes (zero dependencies, `tools/` convention)

**Next Steps:**
1. Review the story at `docs/implementation-artifacts/infra-sf2-build-download-cache.md`
2. Run `dev-story` for implementation
3. Run `code-review` when complete

Sources:
- [GeneralUser GS GitHub](https://github.com/mrbumpy409/GeneralUser-GS)
- [S. Christian Collins - GeneralUser GS](https://schristiancollins.com/generaluser.php)

### 🧑 Human (14:46:00)

Is this the right place for a task that adds GeneralUser GS to the NOTICE file?

### 🤖 Assistant (14:46:06)

No. Attribution in a NOTICE file is a legal/licensing concern, not a build infrastructure task. It belongs in a separate story — likely a small standalone story like `infra-sf2-attribution` or as a subtask in a future story that actually integrates the SF2 into the app (e.g., the `SoundFontNotePlayer` implementation story).

This story's scope is strictly: **download, cache, copy to bundle at build time**. Adding attribution would blur that boundary.

### 🧑 Human (14:46:16)

ok, let's commit both files

### 🤖 Assistant (14:46:31)

Committed as `e5dfaa5` — story file and sprint status update.

### 🧑 Human (14:46:59)

<command-name>/exit</command-name>
            <command-message>exit</command-message>
            <command-args></command-args>

### 🧑 Human (14:46:59)

<local-command-stdout>See ya!</local-command-stdout>

---

[← Previous (ea2fca2147)](ea2fca2147.md) | [Index](index.md) | [Next (f1e596a6c8) →](f1e596a6c8.md)
