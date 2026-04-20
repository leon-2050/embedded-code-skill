# Embedded Code Skill Evaluation Notes

This directory documents a manual evaluation workflow for `ecs`.

## Contents

```text
.evolution/
├── SKILL.md
├── test-prompts.json
├── results.tsv
└── README.md
```

## What Is Actually Included

- scoring dimensions
- sample prompts for spot checks
- a log format for recording evaluations

## What Is Not Included

- automatic file locking
- automatic rollback tooling
- automatic sub-agent orchestration
- an executable scoring harness

## Recommended Loop

1. run `validation/check-consistency.sh`
2. inspect the relevant skill file
3. make one focused change
4. re-run validation
5. record the result in `results.tsv`

## Why This Matters

The original package mixed real guidance with aspirational automation claims. This directory now describes only the workflow that a human operator can actually execute.
