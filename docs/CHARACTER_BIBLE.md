# Character Bible (canon, ADR-022)

Part of the story canon; entry point `STORY_BIBLE.md`. The Operator's secrecy rules are in `OPERATOR_MYSTERY_GUIDELINES.md` and override anything here.

**Visual references:** `design/art/reference/ch01/` (owner concept sheets). These are references only (`ART_PIPELINE.md`). Sol turns them into a direction note within the 32×48 px, TLF-CH01-32 constraints (TLF-061). Text printed on the reference sheets is **not canon** where it conflicts with this file.

## Elias — the protagonist
- **Role:** the player character; amnesiac at the start.
- **Arc:**
  - confusion, fear and the need to know who he is
  - he starts to understand the link between himself, Mira and ELYSIUM
  - he faces the consequences of what he once did
  - he chooses a future based on what he has understood about loss and identity
- **Truth (revealed slowly):**
  - He was deeply bound to Mira but can't remember it.
  - The disaster is tied to **his own refusal to lose her** (revealed in Ch4).
- **Reliability:** Elias is not fully reliable, not even about his own memories.
- **Voice:** natural, human, emotional; it grows less steady as the story goes on. Short lines; he thinks out loud and asks questions.
- **Visual (current build):** Elias v2, brown trench coat, pocket-watch chain, 32×48 px (ART_BIBLE §2).
- **Visual (proposed v3):** from `elias_ref.png` (lab coat, red scarf, goggles). Pending Sol's note (TLF-061) and the owner's decision. Hurt/Knockdown/Run poses are not used (no damage, no run).
- **Always carries:** the pocket watch (the only time tool).

## Mira — the lost memory
- **Role:** the most important person in Elias's life, and one of the main reasons for the ELYSIUM experiment. Research partner (owner reference).
- **She is not just someone to be saved.** She has her own personality, opinions, wishes, conflicts and decisions.
- **Characterisation:**
  - clever, and understands the experiment's risks
  - deeply attached to Elias
  - sees that Elias is obsessed with the past
  - **does not want Elias to destroy himself to keep her**
- **Presence:** recordings, memories, temporal reconstructions and certain interactions. Her true status is revealed step by step. **In Ch5 the player learns she is a consciousness reconstruction stored in ELYSIUM**, not a living person as before. Her feelings and her time with Elias must still feel meaningful.
- **Voice:** soft and warm, with emotional firmness. Key lines:
  - Ch1 recorder: "Promise me you'll let the clock pass midnight."
  - Ch2: "choose to live"
  - Ch5: "don't lose yourself trying to remember me"
- **Never write for Mira:** pleas to be remembered or rescued as her main drive (e.g. "keep remembering me", from the reference sheet text), or knowledge of the whole timeline (that is the Operator's trait).
- **Visual:** lavender/purple, flower motif, Fade/Disperse when a memory ends (`mira_ref.png`). Not on screen in Ch1 (voice and a Trace silhouette only); the Beat 10 broadcast image is silent.

## The Operator — the unanswered identity
- **The central mystery. Never confirmed.** Full rules: `OPERATOR_MYSTERY_GUIDELINES.md`.
- **What he is like:**
  - knows a lot about Elias and understands ELYSIUM
  - can work temporal mechanisms
  - **sometimes helps and sometimes blocks** Elias
  - knows events the player hasn't lived yet
  - has an unexplained link to the pocket watch
  - feels like someone with a long history with Elias
- **Design intent, never shown as exposition:** he knows where Elias's journey ends and tries to stop him before the core, not to destroy him but to keep the mistake from repeating.
- **Voice:** calm, slightly distorted, hard to identify; never monstrous. Speaker label: **"VOICE"**.
- **Visual:**
  - From `operator_ref.png`: hood, mask, the face never visible.
  - The ADR-022 A4 constraints: Elias's **pocket watch** (not an hourglass), a hand gesture like Elias's, the same scarf colour as Elias under the robe, the same temporal effect as Elias's abilities.
  - **No attack animations** (no combat).
  - "Restrict/Block" only as a non-combat barrier gesture.

## The Archivist — keeper of memories (Ch3+)
- Keeps and manages the temporal memory recordings.
- Knows many **possible** events but not always which one really happened.
- Helps the player understand how the world works, but does not explain the whole mystery.
- May **hide** some truths, believing they would make Elias worse.
- Key line: "Memory does not preserve the truth. It preserves what survived."

## Frozen commuters (Ch1)
People who didn't leave at 23:54. Each one is a time-stamped memory read with Trace (`design/ch01/COMMUTERS_STEP1.md`). They say what they were doing and what they believed. **None of them says** who locked the station, who the Operator is, or what ELYSIUM did.

## Relationships
| | Elias | Mira | Operator | Archivist |
|---|---|---|---|---|
| **Elias** | — | loves her, can't remember her; his refusal to lose her drives the disaster | distrusts him and needs him; a strange familiarity | a source he can't fully trust |
| **Mira** | wants him to live, not to cling | — | (not established; keep it open) | is among the records it keeps |
| **Operator** | knows him too well; helps and hinders | (open) | — | (open) |
