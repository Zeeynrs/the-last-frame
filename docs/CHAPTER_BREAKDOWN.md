# Chapter Breakdown (canon, ADR-022)

Part of the story canon; entry point `STORY_BIBLE.md`. Mechanics per chapter are reconciled with `FUTURE_FEATURE_BACKLOG.md` §2. Chapter 1 detail lives in `design/ch01/CH01_BEAT_SHEET.md` (beats) and `narrative/ch01/CH01_TEXT.md` (text).

## Chapter 1 — The Forgotten Station *(vertical slice, in production)*
**Purpose:** introduction, establish the mystery, the first temporal mechanics.
- **Opening:** Elias wakes on the platform of Station Elysium-09. Emergency lights, a stopped train, clocks at 23:59, no memory. When he touches the pocket watch he sees a flash of something that isn't in the room any more (`MEM_WATCH_1/2`).
- **Major events (beat in brackets):**
  1. Exploration (01).
  2. Movement and interaction (01).
  3. First temporal recording: Trace memories (01-02).
  4. Rewind, Freeze and Echo, unlocked one at a time (02-05, ADR-020).
  5. Mira's message: the damaged recorder (06).
  6. Signs that someone used the temporal system before him: the turnstile trace, the Level-0 pass, and the terminal that knows his hand (02, 05, 09).
  7. A mysterious figure seen briefly at the far end of the Arrival Platform (01, TLF-058).
- **Signature puzzle:** *The Forgotten Sequence* (CH1-PZ-004). Record Elias's action, then replay it so two mechanisms run at the same time. It introduces Echo / Dual Elias.
- **Single revelation (Beat 09):** the station was sealed deliberately, from the Atrium terminal, at Level-0, and the terminal opens for Elias's hand. "Did I do this?" stays a question.
- **Ending:** Elias leaves the station and sees the whole city frozen (Beat 10 cinematic, TLF-059). A voice on a street device says "You are late." … "Again." Who said it is not known. A silent broadcast image of Mira shows on a plaza screen.
- **Step 1 expansion** (ADR-020): frozen commuters, solo puzzles, Last Ticket, deeper puzzles. Target ≥ 15 min measured.

## Chapter 2 — The City That Remembers
**Purpose:** emotional development, environmental storytelling, Mira's past.
- **Events:**
  - the frozen city
  - the apartment Elias seems to have shared with Mira
  - memory fragments of their life
  - recorded conversations
  - Mira's warning about ELYSIUM
  - proof the experiment was run many times
  - the Operator on a surveillance screen or in a glass reflection
- **Signature puzzle:** *The Apartment That Remembers*. Restore objects to earlier states and put the events in order; each object holds a fragment.
- **Revelation:** Mira once said "If you ever have to choose between remembering me and living your life... choose to live." (no context yet).
- **Ending:** ELYSIUM also holds recordings of events that **haven't happened yet** in Elias's timeline.

## Chapter 3 — The Infinite Library
**Purpose:** first philosophical revelation; controllable Dual Elias.
- **Setting:** a library of possible events, decisions and timelines, some showing lives Elias never lived. **Art:** warm wood, gold and sunlight, not purple.
- **Events:**
  - Elias meets the Archivist
  - memory ↔ timeline
  - several recorded versions of himself
  - proof he has passed this place before
  - full Dual Elias
  - the Operator warns about the cost of using Echo
- **Signature puzzle:** *Two Sides of Time*. Control Elias Present while using Elias Past through recorded actions.
- **Revelation:** a recording, "How many times must we repeat the same mistake?", in a voice very like Elias's. Never explained.
- **Ending:** the Archivist says "Memory does not preserve the truth. It preserves what survived."

## Chapter 4 — Paradox Laboratory
**Purpose:** the true nature of ELYSIUM; the emotional tragedy.
- **Events:**
  - the experiment logs
  - Mira trapped in a temporal anomaly
  - Elias tried to use ELYSIUM to keep or bring back Mira
  - broken causality
  - several loops
  - the Operator shows very personal knowledge
- **Signature puzzle:** *The Broken Causality*. Order events from different timelines; an action in the past changes objects in the present.
- **Major revelation:** the disaster is tied to Elias's own refusal to lose Mira. Nothing explains the Operator's part in it.
- **Scene:** the Operator behind the lab glass (lines in `OPERATOR_MYSTERY_GUIDELINES.md` §5); he vanishes before Elias reaches him.

## Chapter 5 — Beyond Reality
**Purpose:** psychological breakdown, identity uncertainty, the emotional climax.
- **Events:**
  - space is unstable; places change when re-entered
  - versions of Elias who chose differently
  - contradictory versions of events
  - **Mira is revealed as a consciousness reconstruction**, and she begins to understand it herself
  - Elias realises how long he has spent holding on
  - the Operator grows personal
  - a visual likeness between the Operator and Elias
- **Signature puzzle:** *The Unreliable Reality*. Compare versions of a room and find what stays consistent; not everything shown is true, but every puzzle is logical.
- **Mira scene:**
  - Mira: "You keep trying to bring me back."
  - Elias: "I thought I could fix it."
  - Mira: "Maybe you can fix the machine. But you cannot fix what happened to us." (pause) "Please... don't lose yourself trying to remember me."
- **Operator:** "At the end of this, you will understand why I never stopped." Unexplained.
- **Ending:** Elias reaches ELYSIUM's core.

## Chapter 6 — The Last Frame
**Purpose:** all mechanics converge; emotional resolution; branching endings.
- **Mechanics:** Echo, Dual Elias, Rewind, Freeze, Fast-Forward, spatial manipulation, Memory Reconstruction, causality puzzles.
- **Final conversation:**
  - Operator: "You have reached this moment."
  - Elias: "Who are you?"
  - Operator: "Does it change anything?"
  - Elias: "I need to know."
  - Operator: "Then ask yourself why you are still here."
- Then the final choice (`ENDING_DESIGN.md`). His identity is never explained.

## Chapter transitions
Each chapter ends on an image or line that opens the next question:
- Ch1 → the frozen city + "You are late. Again."
- Ch2 → recordings of the future
- Ch3 → "what survived"
- Ch4 → the Operator vanishes behind the glass
- Ch5 → the core
