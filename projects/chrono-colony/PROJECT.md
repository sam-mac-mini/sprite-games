# Chrono Colony — PROJECT.md

## Overview
**Genre**: Roguelike Time-Loop City Builder
**Platform**: iOS (Premium $6-8)
**Session Length**: 8-15 minutes per loop
**Core Emotion**: Optimization, mastery, intelligent iteration

A systems-driven colony builder around a fixed 10-minute time loop. Build a colony on a procedurally generated planet racing against stellar collapse. Colony is destroyed each loop — but knowledge, unlocks, and strategic insight persist.

## Tech Stack
- **Language**: Swift
- **Framework**: SpriteKit (2D grid + UI overlays)
- **Architecture**: Entity-Component-System (GameplayKit ECS)
- **Target**: iOS 17+, iPhone + iPad
- **Repo**: https://github.com/sam-mac-mini/sprite-games

## Architecture Decisions
- **ECS via GameplayKit** — buildings as GKEntity, resources/production/stability as GKComponent
- **Deterministic simulation** — seeded RNG for reproducible runs (leaderboard potential)
- **Grid**: Start at 10x10 for prototype (Sam's GDD says 12x12, but testing smaller for mobile tap targets first)
- **State machines** for game phases: Landing → Expansion → Escalation → Collapse
- **Event deck system** — procedural events with clear tradeoffs, not random punishment

## Core Systems
1. **Grid System** — 10x10 tile grid, tap-to-select, tap-to-build
2. **Resource System** — Metal, Energy, Biomass, Research, Stability
3. **Building System** — place, staff, demolish, upgrade
4. **Colonist System** — assignable workers to buildings
5. **Timer System** — 10-minute countdown, escalation phases
6. **Event System** — procedural event deck with tradeoff choices
7. **Tech Tree** — 56 unlocks across 4 branches (phased rollout)
8. **Meta Progression** — Knowledge Points persist across loops

## Design Pillars (from GDD)
1. Time is the primary resource
2. Failure teaches optimization
3. Horizontal progression over power creep
4. High density, short sessions
5. Systemic depth, not content bloat

## Prototype Scope (Phase 1)
- Grid rendering + camera
- 4 starter buildings: Metal Extractor, Farm, Solar Array, Research Lab
- 5 resources with production/consumption
- 10-minute timer with collapse
- Basic colonist assignment
- Placeholder art (geometric shapes)
- NO tech tree, NO meta progression, NO events yet

## Refinements from Sprite's Analysis
- Grid starts at 10x10 (not 12x12) — testing tap target sizes on device first
- Tech tree ships with ~28-32 unlocks in v1, full 56 is content roadmap
- First 3-5 loops should be "guided" — gradual system introduction
- Temporal Physics branch is the unique hook — save it as late-game unlock
- Deterministic seed system needs early architecture commitment
