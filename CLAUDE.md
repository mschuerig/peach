# Peach - Claude Code Instructions

Before starting a new task, ensure that there are no uncommitted changes in the working directory.

Before committing anything, make sure that **ALL tests** still pass:
- Run the full test suite: `xcodebuild test -scheme Peach -destination 'platform=iOS Simulator,name=iPhone 17'`
- Do NOT commit if any tests fail
- Do NOT run only specific test files - always run the complete test suite

## Git Workflow

- Commit changes after each meaningful task completion (e.g., story created, sprint status updated, code implemented)
- Use descriptive commit messages that reference the story or task context
- Do not batch unrelated changes into a single commit
- Do not push to remote unless explicitly asked
