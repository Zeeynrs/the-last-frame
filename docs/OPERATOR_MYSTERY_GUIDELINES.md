# Operator Mystery Guidelines (canon, ADR-022) — mandatory review gate

Applies to every dialogue line, document, cutscene, sprite, sound and design note that involves the Operator. **The Operator is not a riddle the game answers; he is a mystery the player takes home.**

## 1. Hard rules
1. Never reveal his real name.
2. Never show his face clearly. The hood/mask stays on, and there is no face design that could confirm who he is.
3. Never have him say, or come close to saying, that he is Elias. Forbidden: "I am you." · "I am your future self." · "I am Elias." · any equivalent.
4. No narrator, UI text, journal "fact" or loading tip explains who he is.
5. No other character confirms who he is.
6. Use visual, audio and behavioural clues, consistently.
7. Ending 3 is the strongest clue, and it is visual/audio only.
8. The secret ending does not answer it either.

## 2. The three interpretations (all must stay possible)
1. He is Elias from the future.
2. He is an entity formed from Elias's memory and consciousness.
3. He is someone else trapped in ELYSIUM.

**Internal design note (never confirmed to the player):** Ending 3 is built as a loop suggesting Elias becomes the Operator.

## 3. Dialogue
- **Tone:** calm, natural, weary, as if he has said this before. Not a string of cryptic slogans.
- **Allowed (examples):**
  - "You always arrive at this moment."
  - "I know what you will choose."
  - "Some things cannot be remembered. Only repeated."
  - "You are closer than you think."
  - "I have seen this ending before."
  - "Do you remember who started this?"
  - "You are late. Again."
- **Ch1, as built:**
  - B03: call box; the shared phrase "Time doesn't stop. It waits."
  - B05: PA, "An echo only does what you already chose to do."
  - B07: intercom, "Leave it alone."
  - B10: "You are late." / "Again."
- **Forbidden:** rule 3, and also lines that tie him to Elias's biography as a fact ("I remember the day you met her").
- **Shared phrases between Elias and the Operator:** at most one or two per chapter, never explained.

## 4. Visual language
- A recognisable silhouette: hood, mask, long robe (owner reference `operator_ref.png`, as directed by Sol).
- **Links to Elias that must be present:**
  - the **same pocket watch**
  - the same "lifts the watch and checks it" gesture as Elias's animation
  - the same scarf colour under the robe
  - the same temporal VFX as Elias's abilities
- **Repeated camera composition:** the first sighting's framing (Ch1 Arrival Platform, figure at the far end, facing away, checking the watch) is reused in later sightings and **exactly** in Ending 3.
- **Forbidden:**
  - a visible face
  - attack / combat animations
  - a hourglass in place of the watch
  - anything so explicit that the mystery collapses

## 5. Clue ledger (keep it up to date)
| Ch | Clue | Form |
|---|---|---|
| 1 | Shared phrase "Time doesn't stop. It waits." (Elias B01, Operator B03) | dialogue |
| 1 | He knows the watch and the lock; warns Elias away from the terminal | dialogue |
| 1 | Silhouette at the far end of the Arrival Platform checking a pocket watch; gone when approached | sighting (TLF-058) |
| 1 | The terminal knows Elias's hand; a column of identical 23:59 biometric matches | document (Beat 09) |
| 1 | "You are late. Again." | voice, Beat 10 |
| 2 | Appears on a surveillance screen or in a glass reflection | sighting |
| 3 | A voice recording that sounds very like Elias: "How many times must we repeat the same mistake?" (unexplained) | audio |
| 4 | Behind lab glass: "You keep searching for the person responsible. ... Have you ever considered that the answer might not be what you are looking for?" | scene |
| 5 | "At the end of this, you will understand why I never stopped." Visual likeness to Elias grows | scene |
| 6 | "You have reached this moment." / "Does it change anything?" / "Then ask yourself why you are still here." | final conversation |
| E3 | Figure in Elias's clothes, same watch, same gesture, at the first-sighting location; "You are late. Again."; 23:59 | ending |

## 6. Review checklist (run it before merging anything with the Operator)
- [ ] Is his identity revealed directly?
- [ ] Does any character confirm it?
- [ ] Is a line too explicit?
- [ ] Does any visual show his face or a feature that removes the mystery?
- [ ] Does Ending 3 still leave room for interpretation?

Any "yes" (or "no" on the last item) blocks the merge until it is revised.
