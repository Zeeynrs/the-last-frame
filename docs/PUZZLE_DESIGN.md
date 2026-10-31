# Puzzle Design Guide

## 1. Puzzle quality principles

- Teach a rule safely before testing it under pressure.
- Combine known rules to create complexity; avoid arbitrary exceptions.
- Make objectives and state changes observable.
- Allow experimentation without permanent punishment.
- Provide escalating hints.
- Test puzzle solutions with players unfamiliar with the design.

## 2. Standard puzzle specification

```text
Puzzle ID:
Name:
Chapter / Room:
Narrative purpose:
Player objective:
Required abilities:
Required objects:
Initial room state:
Rules the player must discover:
Step-by-step intended solution:
Alternative valid solutions:
Failure states:
Reset behavior:
Hint 1 (nudge):
Hint 2 (rule reminder):
Hint 3 (next action):
Success feedback:
Narrative reward:
Accessibility considerations:
Acceptance tests:
```

## 3. Example puzzle — The Delayed Platform

**ID:** CH1-PZ-003  
**Purpose:** Teach temporal echoes and coordination.

- Objective: Keep a security gate open while crossing a platform.
- Objects: Pressure switch, gate, echo recorder, platform.
- Rule: The pressure switch remains active while an entity stands on it.
- Intended solution:
  1. Record Elias stepping onto the pressure switch.
  2. Stop recording and replay the echo.
  3. The echo holds the switch.
  4. Elias crosses the now-open gate and platform.
- Failure/recovery: Reset the echo recording from a nearby safe position.
- Hint 1: The switch reacts to weight, not identity.
- Hint 2: Something can remain on the switch while Elias moves away.
- Hint 3: Record Elias standing on the switch, then replay the recording.
- Success feedback: Gate motor, light transition and a clear audio cue.

## 4. Example puzzle — The Wrong Door

**ID:** CH3-PZ-002  
**Purpose:** Introduce doorway graph reassignment.

- Objective: Reach a room whose visible doorway does not connect to it in the current arrangement.
- Rule: Room doorways are graph connections, not fixed geometric destinations.
- Intended solution: Discover the room's orientation clues, rotate the room in 90-degree increments and reassign the correct doorway pair.
- Safety: Preview or clearly communicate the result before committing a costly transformation.
- Recovery: Provide a reset anchor.

## 5. Puzzle playtest checklist

- Can the player state the objective?
- Are all necessary rules observable?
- Does the puzzle distinguish experimentation from failure?
- Is there any unintended soft-lock?
- Are feedback cues understandable without relying on color alone?
- Does the hint ladder help without immediately spoiling?
- Is the solution satisfying and explainable?
- Does the puzzle contribute to story, mechanics or atmosphere?
