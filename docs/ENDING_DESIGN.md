# Ending Design (canon, ADR-022)

Part of the story canon; entry point `STORY_BIBLE.md`. The Operator rules in `OPERATOR_MYSTERY_GUIDELINES.md` apply to every ending. Three main endings plus one secret ending (= PRD FR-016 "four endings, including one secret").

## Requirements for every ending (Story Bible §10.4)
- A clear trigger.
- No conflict with earlier chapters.
- A good cinematic transition.
- No information the story never set up.
- A stable implementation.
- Works with save/load and state progression.

**Implementation sketch (Ch6, not built):** the final choice sets one persistent flag, `ending.choice = new_beginning | eternal_stillness | paradox`, in `NarrativeState`, saved before the sequence plays. The secret ending's prerequisites (all memory fragments + the hidden puzzle) are separate flags checked when Ch6 loads. The ending summary screen (GDD §15) reads the flag.

## Ending 1 — A New Beginning
- **Theme:** acceptance and letting go.
- **Trigger:** the final choice "stop ELYSIUM".
- **Sequence:**
  - The system destabilises and the recordings fade.
  - The city moves again; the frozen rain finally falls.
  - Mira appears one last time and smiles. Mira: "You finally made it." Elias: "I don't want to forget you." Mira: "Then don't. Just don't stay here forever." She disappears.
  - The clock shows **00:00**. Elias walks out.
  - The Operator doesn't appear and nothing explains him.
- **Reading:** Elias accepts the loss and goes on living. **He keeps his memories**; the old "loses his memories" text is superseded.

## Ending 2 — Eternal Stillness
- **Theme:** obsession, preservation forever.
- **Trigger:** the final choice "keep ELYSIUM running".
- **Sequence:**
  - Elias believes that while the system runs, Mira and their memories are never really lost.
  - The city stays frozen and midnight never comes.
  - Elias becomes the keeper of ELYSIUM, sitting alone in the control room.
  - A screen shows a mysterious figure watching from far away. It is unclear whether it is the Operator, Elias, or something else.
  - The clock stays at **23:59**.
- **Reading:** he keeps the memories at the cost of a future.

## Ending 3 — The Paradox
- **Theme:** identity, causality, the unanswered loop.
- **Trigger:** the final choice "merge with the core".
- **Rule:** the main twist about Elias and the Operator, **never confirmed in words**.
- **Sequence:**
  1. Elias merges with the core and tries to control every temporal link. Light fills the room; white screen.
  2. **The Arrival Platform**, where the Operator was first seen (ADR-022 D3), in **the identical composition** of that sighting.
  3. A figure stands with its back to the camera, in the same clothes as Elias, holding the same pocket watch.
  4. The camera slowly moves closer. The figure lifts the watch and checks it, moving **exactly like Elias's opening animation**.
  5. The Ch1 line: "You are late. Again."
  6. Black. A pocket watch ticks. **23:59.** No narration, no explanation, no confirmation.
- **Last frame:** the figure's silhouette in the same composition as the Operator's earlier appearances.
- **Music:** the Ch1 motif (the Operator's first appearance) with a small variation.
- **Open questions left to the player:**
  - Did Elias become the Operator, or just another version of him?
  - Is the Operator a reconstructed consciousness?
  - Is the loop real, or an ELYSIUM simulation?
- **Ch1 dependency:** the sighting's position, framing, the gesture animation and the voice line are reused here. Document them precisely when TLF-058/TLF-059 are built.

## Secret Ending — The Last Player
- **Theme:** breaking the expected story.
- **Trigger:**
  - Every memory fragment found, plus a specific hidden puzzle; no obscure pixel hunting (GDD §12).
  - Then a room that isn't recorded in ELYSIUM, built differently from every place before it.
- **Sequence:**
  - Recordings with no timestamp.
  - ELYSIUM may not only store events but also **observe whoever interacts with it**.
  - Elias stops the system outside the normal procedure.
  - The clock moves from 23:59 to **00:01**; for the first time, time passes the limit.
  - Before black: "**Someone is still watching.**" Nothing more.
- **Rule:** it widens the mystery and must not confirm the Operator's identity.
