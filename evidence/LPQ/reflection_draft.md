# Individual reflection draft

## Li Peiqi Group5

Review status: Li Peiqi approved this text for commit and push in the recorded conversation. The existing draft filename is retained for stable links; final report submission remains the student's responsibility.

My responsibility in Stage 1 was to guide the development of the Fishing21 baseline using our game plan and the assignment requirements. I provided the planning materials, requested a clear class structure and directed implementation through manageable steps, including casting, daily settlement, seven-day progression and the playable interface.

Through this process, I developed a clearer understanding of how class responsibilities affect maintainability. For example, FishingNet manages catches and weight limits, while SettlementRules calculates daily income. GameSession manages progression and applies the financial result. Separating these responsibilities makes it easier to identify where a rule belongs and assess which classes a change should affect.

The project also helped me understand when inheritance is useful. The fish categories currently differ in probability and weight rather than behaviour, so configuration data is sufficient to represent them. CatchSource provides a meaningful use of abstraction: random gameplay and fixed test sequences share the same small contract. This gives SOLID principles a practical purpose rather than treating them as a checklist.

One challenge was evaluating whether AI-generated code remained correct beyond the default gameplay path. During a further review that I requested, Codex identified a start button with a hardcoded seven-day label and an error display that could leave an old result overlay visible. Reproducing tests exposed these issues before they were fixed. This showed me that passing normal gameplay checks does not establish correctness for every configuration or state.

I used Codex extensively for architecture suggestions, implementation, tests and documentation. My contribution included supplying requirements, directing the sequence of work, providing screenshots, requesting changes and organising development evidence. The automated checks were performed by the AI agent, so I distinguish them from my own manual verification. I remain responsible for reviewing the output and explaining the submitted design.

Before freezing Stage 1, I need to complete the remaining manual acceptance checks and review the implementation alongside the Class Map and design rationale. In later stages, I intend to evaluate new requirements against the existing responsibilities, make justified local changes and use version comparisons to assess how well the original design supports extension.
