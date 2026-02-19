# Lessons

Mistakes and hard-won knowledge. Check before repeating history.

## Format
```
- **YYYY-MM-DD**: What happened → What to do instead
```

## Experiments
Track things tried and outcomes — not just mistakes, but deliberate tests.
```
- **YYYY-MM-DD**: Tried [X] → Result: [what happened] → Keep/Drop
```

## Log
- **2026-02-17**: Skill descriptions written as marketing copy → Write them as routing logic with "use when / don't use when" and negative examples. Glean saw 20% accuracy drop without negatives.
- **2026-02-17**: Cramming templates into system prompt → Put them inside skills. Zero token cost when unused, loaded on demand.
- **2026-02-17**: Running many agents with overlapping context → One agent with good skills beats a squad of confused ones. Only split agents when domains are truly distinct.
- **2026-02-17**: Generic sub-agent tasks ("research this") produce generic results → Assign sub-agents an explicit role/lens: "You are the research agent: verify facts, ground in data" or "You are the critic agent: find holes in this plan." Inspired by Grok 4.20's 4-agent specialization pattern. Parallel sub-agents with different lenses + synthesis beats one sequential pass.
