# Technical Debt

Only debt that exists in the repository now. Risks and gameplay issues stay in `KNOWN_ISSUES.md`.

| ID | Debt | Where | Impact | Plan |
|---|---|---|---|---|
| TD-001 | Services find each other through group lookup plus `get_node_or_null` fallbacks in several places (`InteractionService`, `Interactable.get_session`) | `scripts/session/`, `scripts/interaction/` | Hidden coupling, extra lookups per call | Keep for now; consolidate when SceneRouter lands (one session reference injected per room) |
| TD-002 | Older tests duplicate `_assert_*` wrapper helpers | `tests/session|player|interaction` | Boilerplate | `tests/support/base_test.gd` exists (TLF-008); migrate old tests opportunistically |
| TD-003 | Prompt text is a hard-coded English string with a key name | `scripts/interaction/lever.gd` | Not localizable; wrong on controller | TLF-018 HUD task (ISSUE-007) |
| TD-004 | `InteractionResult` ignored by the Player | `scripts/player/player.gd` | No failure feedback | TLF-018 (ISSUE-006) |
| TD-005 | ~~Trigger handler dispatch missing~~ **Resolved in TLF-016** | — | — | — |
