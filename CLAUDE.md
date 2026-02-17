# Peach - Claude Code Instructions

Before starting a new task, ensure that there are no uncommitted changes in the working directory.

Before committing anything, make sure that **ALL tests** still pass:
- Run the full test suite: `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
- Do NOT commit if any tests fail
- Do NOT run only specific test files - always run the complete test suite

## Tool Scripts

When you need to run analysis, data processing, or evaluation code (e.g., parsing test output, computing statistics, visualizing results), **write it as a saved script file** rather than inline code in the chat. Place scripts in `tools/` at the project root.

- **Do NOT** write inline Python/Shell/Ruby/etc. snippets for direct execution in the shell
- **Do** create a named script file (e.g., `tools/analyze-convergence.py`), ask for a review, and only after approval execute it
- Scripts are reviewable once and reusable — inline code requires re-review every time
- Commit tool scripts alongside the work that introduced them

## Git Workflow

- Commit changes after each meaningful task completion (e.g., story created, sprint status updated, code implemented)
- Use descriptive commit messages that reference the story or task context
- Do not batch unrelated changes into a single commit
- Do not push to remote unless explicitly asked
