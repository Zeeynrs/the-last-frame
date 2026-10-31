# Development Roadmap

Ordered by the master-prompt priorities and the dependencies that already exist in the repo. Milestones and gates are as defined in `IMPLEMENTATION_PLAN.md` and `PRD.md` §13. Owners: **O** = Opus, **F** = Flash, **A** = Argon.

## Now: Milestones 1–2 (foundation + temporal prototype)
| # | Work | Owner | Depends | Status |
|---|---|---|---|---|
| 1 | TLF-008 TemporalComponent, Rewind/Freeze/Trace, Interactable ability delegation | O | — | COMPLETE |
| 2 | TLF-016 EchoService: record/playback, occupancy, trigger dispatch | O | 1 | COMPLETE |
| 3 | TLF-017 Settings autoload, input remapping foundation, controller test evidence (M1 exit) | F | — | READY |
| 4 | TLF-018 Pocket-watch controller (ADR-015 targeting, ability cycle, Echo controls, `echo_reset`) + HUD feedback (ISSUE-006/007) | F | 1, 2 | NOT STARTED |
| 5 | TLF-005 Ch1 room graph and placement constraints | A | — | READY |
| 6 | TLF-019 PuzzleService (ADR-016) + SaveService (ADR-010) with migration test | O | 1 | COMPLETE |
| 7 | TLF-020 SpatialGraph (ADR-009) + doorway presenters + safe anchors | O | 6 | COMPLETE |
| 8 | TLF-021 Room router: room scenes, doorway spawns, checkpoints → SaveService | O | 7 | COMPLETE |
| 9 | TLF-022 HintService + PuzzleDef (ADR-013) + documents/fragments data | O | 6 | NEXT |
| 10 | TLF-009 Ch1 greybox rooms + PZ-001…005 implemented from specs (with their acceptance tests) | F (O reviews) | 8, 4 | after TLF-018 |

## Next: Milestones 3–4 (spatial + puzzle/narrative framework)
- SpatialGraph (ADR-009) with doorway presenters and safe-anchor relocation (O)
- SceneRouter: room loading, doorway transitions, checkpoints (O + F)
- Camera per room (F, after TLF-005)
- Dialogue, documents, memory fragments, journal (F UI; O narrative state)
- TLF-010 art target sheet, palette, pixel font, Elias idle/walk, station kit v1 (A)

## Then: Milestone 5 (Chapter 1 vertical slice, Gate C)
- Implement CH1-PZ-001…005 from specs, each with its acceptance tests (TLF-009 and follow-ups; F implements, O reviews)
- Assemble the 10 rooms, the narrative beats, the cinematic (Beat 10) and the revelation (Beat 09)
- Art/audio/VFX integration, accessibility settings, save/load at checkpoints
- External playtest, then fixes

## Later: Milestones 6–7
- Chapters 2–6 in sequence, only after Gate C passes; Time Shift, room rotation, gravity, folding and overlap introduced chapter by chapter, with ADRs
- Beta, performance, Windows/Linux export, release (Gates D–F)
