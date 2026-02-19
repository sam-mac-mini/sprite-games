# Tech Tree Design — Chrono Colony v0.3

## Architecture Overview
- 4 branches, each with 7-8 unlocks (28-32 total)
- Knowledge Points (KP) earned per loop, spent between loops
- Unlocks are **horizontal** — new options, not flat stat boosts
- Each branch has a tier structure: Tier 1 (cheap) → Tier 3 (expensive)
- Temporal Physics is Branch 4 — requires unlocks from other branches as prerequisites

## Branches

### 🔧 Branch 1: Infrastructure (Building & Resource)
Expand building options and resource efficiency.

| ID | Name | Tier | Cost | Effect |
|----|------|------|------|--------|
| INF-01 | Reinforced Foundations | 1 | 15 | Buildings take 2 hits before destruction during escalation |
| INF-02 | Recycling Protocol | 1 | 20 | Demolish refund increased to 75% (from 50%) |
| INF-03 | Storage Depot (unlock) | 2 | 30 | New building: stores excess resources, prevents overflow waste |
| INF-04 | Advanced Drill Bits | 2 | 35 | Metal Extractors produce +25% base output |
| INF-05 | Hydroponic Systems | 2 | 35 | Farms produce +25% base output |
| INF-06 | Power Grid | 3 | 50 | Solar Arrays share energy to adjacent buildings (reduces consumption) |
| INF-07 | Mega-Structure (unlock) | 3 | 60 | New building: occupies 2x2 tiles, massive output, huge cost |

### 👥 Branch 2: Colony (Colonists & Efficiency)
Improve worker management and colony survival.

| ID | Name | Tier | Cost | Effect |
|----|------|------|------|--------|
| COL-01 | Recruitment Drive | 1 | 15 | Start each loop with +2 colonists (7 total) |
| COL-02 | Training Program | 1 | 20 | Second worker efficiency: 60% → 80% |
| COL-03 | Automation Protocol | 2 | 30 | Buildings produce at 30% without workers assigned |
| COL-04 | Medical Bay (unlock) | 2 | 35 | New building: heals colonists, prevents sickness events |
| COL-05 | Efficient Rations | 2 | 25 | Colonist biomass consumption reduced 30% |
| COL-06 | Leadership | 3 | 45 | +1 max worker per building (3 total, 3rd at 40% efficiency) |
| COL-07 | Clone Vats (unlock) | 3 | 55 | New building: slowly produces colonists during loop |

### 🔬 Branch 3: Research & Events
Improve research output and event handling.

| ID | Name | Tier | Cost | Effect |
|----|------|------|------|--------|
| RES-01 | Data Mining | 1 | 15 | Research Labs produce +25% |
| RES-02 | Event Scanner | 1 | 20 | Preview upcoming event 30s before it fires |
| RES-03 | Anomaly Resonance | 2 | 30 | Anomaly adjacency bonus doubled (+150% instead of +75%) |
| RES-04 | Emergency Protocols | 2 | 35 | Can dismiss events without choosing (minor stability cost) |
| RES-05 | Shield Generator (unlock) | 2 | 40 | New building: reduces escalation damage in 3x3 area |
| RES-06 | Advanced Sensors | 3 | 45 | See resource deposit locations before placing buildings |
| RES-07 | Knowledge Amplifier | 3 | 50 | +30% Knowledge Points earned at end of loop |
| RES-08 | Temporal Signature | 3 | 60 | Prerequisite for Temporal Physics branch |

### ⏳ Branch 4: Temporal Physics (Unique Hook — Late Game)
The time-loop mechanic becomes a gameplay tool. Requires RES-08.

| ID | Name | Tier | Cost | Effect |
|----|------|------|------|--------|
| TMP-01 | Echo Memory | 1 | 40 | First building placed each loop is free (remembered from last loop) |
| TMP-02 | Time Dilation | 1 | 45 | Can slow time to 50% for 30 seconds (once per loop) |
| TMP-03 | Loop Echo | 2 | 55 | Start loop with 20% of previous loop's ending resources |
| TMP-04 | Paradox Shield | 2 | 60 | Stability can't drop below 20% for first 5 minutes |
| TMP-05 | Temporal Rift (unlock) | 3 | 70 | New building: generates all resource types but drains stability |
| TMP-06 | Chrono Mastery | 3 | 80 | Loop extends to 12 minutes (extra 2 min before collapse) |
| TMP-07 | Time Rewind | 3 | 100 | Once per loop: undo last 30 seconds of simulation |

## Total: 29 unlocks

## Persistence System
- `MetaState` saved to UserDefaults (JSON)
- Tracks: total KP earned, KP available, unlocked IDs, total loops, best score
- Applied at loop start via `TechEffects` system that reads unlocks

## UI
- Tech tree screen accessible between loops (from summary screen)
- Visual: 4 columns, nodes connected by lines, locked/unlocked/affordable states
- Tap node to see details + purchase
- Branch 4 locked until RES-08 is purchased

## Flow
1. Loop ends → Summary screen → "SPEND KNOWLEDGE" button
2. Tech tree opens → browse branches → buy unlocks
3. "START NEW LOOP" → unlocks applied → play
