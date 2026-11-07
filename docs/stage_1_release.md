# Stage 1 frozen baseline

Group: Group5
Stage 1 contributor: Li Peiqi
Tag: [stage-1](https://github.com/Peggyyyyyyyy123/fishing-21/tree/stage-1)
Freeze requested by the user on 2026-11-07 (Asia/Shanghai).

## Scope

This tag preserves the playable 2D baseline and its recorded evidence. It is created on the personal branch LPQ/featrue-stage1; creating a tag does not merge that branch into main or certify completion of all assessment materials. Keep the tag unchanged. Later fixes and released feature requirements belong in new commits and later versions.

## Clean source verification

Committed source ce618dcc89a4b577826deedefc189fece92745d2 was exported using git archive into a separate folder without the project's existing .godot cache. Godot 4.7.2 stable Mono build ed1daf0bf imported it successfully. All seven suites passed on that clean source:

| Suite | Checks | Failures |
| --- | ---: | ---: |
| Foundation | 41 | 0 |
| Initialization | 44 | 0 |
| Casting | 54 | 0 |
| Settlement | 50 | 0 |
| Progression | 408 | 0 |
| UI | 79 | 0 |
| Review | 12 | 0 |
| Total | 688 | 0 |

The freeze preparation changes documentation/evidence only. Runtime code and tests are unchanged from that verified source. UI tests instantiate the production scene and reproduce a complete seven-day victory and failure paths. These are automated checks, not a claim that every human demonstration was performed.

## Known limitations and pending evidence

- Remaining human acceptance items in docs/stage_1_acceptance.md are still open; the freeze does not mark them passed.
- No merged group PR is asserted. Preserve the personal commit history and record actual integration later.
- Class Map PPTX and short design rationale DOCX remain separate deliverables outside this repository, as requested. Include them in the submission package.
- The confirmed reflection text is retained in the existing reflection_draft.md file. Final report assembly and declarations remain the group's responsibility.
- The AI logs are snapshots with explicit cutoffs. This freeze includes the request to freeze; the completion message generated afterward and future conversations require a later supplement.
- Basic visuals, no save/load, audio or dedicated fullscreen toggle. Shop/upgrades/catalogue remain outside this baseline.

## Retrieve this baseline

```powershell
git clone --branch stage-1 https://github.com/Peggyyyyyyyy123/fishing-21.git fishing21-stage1
cd fishing21-stage1
```

Open project.godot with the tested Godot version and run F5. The clone is in detached HEAD at the tag. See README.md for rules, controls and verification commands.

Wait for the lecturer to release Stage 2 requirements before implementing the next extension. Do not move or force-update stage-1 after publication.
