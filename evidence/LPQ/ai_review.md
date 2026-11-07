# Evaluation of AI assistance

## Case 1 Configuration dependent UI and error handling

**Trigger.** The user asked for a further code review after the playable baseline existed.

**Problems in the generated code.** The start button hardcoded a seven-day voyage even though the game model supported a different number of quotas. `GameView.show_error()` displayed the menu without hiding an existing result overlay or disabling active gameplay buttons. This could hide a configuration error under a stale result or leave background controls enabled.

**Evaluation method.** The agent added `tests/test_review.gd` against the actual production scene. Before the fix, 12 checks produced 3 failures: configured voyage length, stale result visibility and active-game background button locking. These were observed failing tests, not hypothetical examples.

**Correction.** The start label now reads `config.get_total_days()`. The scene stores a generic fallback label. Error display hides the old result, disables casting/return and stops the casting visual.

**Verification.** The 12 review checks then passed. All six existing suites also passed (676 checks), giving 688 in total. Source configuration values and core fishing/settlement rules were not changed by this fix.

**Traceability.** [Fix commit 63f5992](https://github.com/Peggyyyyyyyy123/fishing-21/commit/63f5992), containing the test and implementation changes. The chronological conversation retains the request, initial findings, failed-test report and corrected outcome. Raw tool output is not reproduced in the message-only export; test source and the resulting commit are directly available.

**Student involvement.** The user requested review and later requested commit/push. The agent performed this review and automated testing. The student still needs to inspect the diff and explain why a configurable model must have a consistent UI and why a modal error must block stale actions.

## Case 2 Language assumptions

The user later stated that C# was required. The agent acknowledged that the existing implementation was GDScript and proposed migration. After rereading the assignment, the user confirmed there was no engine or language restriction, so migration was not performed. The exchange remains in the full conversation, including the earlier misunderstanding. This demonstrates checking AI advice against the actual brief rather than accepting a costly change without verification.

## Case 3 Evidence of failed and limited operations

Earlier publication attempts were blocked and several user-interrupted commit attempts had uncertain outcomes. Later Git inspection established what had actually completed. The export preserves these iterations. A successful branch push is not recorded as a merge, and automated tests are not recorded as complete human acceptance.

## Design choices reviewed in the implementation

- Fish-size differences use configuration data; there are no unused size subclasses.
- Daily rules receive the minimal `CatchSource` contract; fixed catches make checks reproducible.
- Rule objects do not reference scene nodes or buttons. They still use Godot types, so they are not claimed to be fully engine-independent.
- `GameSession` applies settlement once and only allows advancement after successful non-final settlement.

These explanations were drafted with AI assistance. The student must be able to explain them and provide their own reflection; this document does not certify independent understanding.
