# Technical Debt

Only debt that exists in the repository now. Risks and gameplay issues stay in `KNOWN_ISSUES.md`.

| ID | Debt | Where | Impact | Plan |
|---|---|---|---|---|
| TD-001 | Services find each other through group lookup plus `get_node_or_null` fallbacks in several places (`InteractionService`, `Interactable.get_session`) | `scripts/session/`, `scripts/interaction/` | Hidden coupling, extra lookups per call | Keep for now; consolidate when SceneRouter lands (one session reference injected per room) |
| TD-002 | Tests duplicate `_assert_*` wrapper helpers in every test file | `tests/**` | Boilerplate | Move the helpers into a shared base test script the runner injects (Flash, low priority) |
| TD-003 | Prompt text is a hard-coded English string with a key name | `scripts/interaction/lever.gd` | Not localizable; wrong on controller | TLF-018 HUD task (ISSUE-007) |
| TD-004 | `InteractionResult` ignored by the Player | `scripts/player/player.gd` | No failure feedback | TLF-018 (ISSUE-006) |
| TD-005 | `trigger_enter/exit` only emit signals; there's no handler dispatch to the trigger node | `scripts/session/interaction_service.gd` | Triggers can't drive puzzle objects yet | TLF-016 (Opus) |
