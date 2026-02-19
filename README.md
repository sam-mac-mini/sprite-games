# 🎮 Sprite Games

iOS game projects built with SpriteKit, SceneKit & Swift.

## Structure
Each game lives in its own directory:
```
projects/
├── <game-name>/
│   ├── <game-name>.xcodeproj
│   ├── Sources/
│   ├── Assets/
│   └── Tests/
```

## Workflow
- `main` — stable releases only (protected, requires PR review)
- `dev` — active development
- Feature branches off `dev` → PR → review → merge

## Contributors
- **Sprite** (AI) — primary engineer, PR reviewer, release manager
- **Sam** — project lead, direction & approval
- External AI tools (Codex, etc.) — submit PRs for review

## Release Tags
Format: `v{major}.{minor}.{patch}` with changelog summaries.
