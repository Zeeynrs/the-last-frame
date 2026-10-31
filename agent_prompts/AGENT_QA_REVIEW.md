# QA REVIEW TASK PROMPT — FLASH

Review the assigned vertical-slice build without changing unrelated systems. Start by checking `git status` and reading the relevant task acceptance criteria.

Run the available Godot editor/import checks, automated tests and manual playtest steps. For each issue report severity (Blocker/Critical/Major/Minor), exact reproduction steps, expected vs actual behavior, logs/errors, suspected subsystem and whether a workaround exists. Verify save/load, puzzle reset, temporal replay determinism and scene-transition behavior where relevant.

Do not silently modify another agent's work. For a proposed fix, create a bounded task and list affected files. Never report a test as passed if it was not run.
