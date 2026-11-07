# Individual reflection draft

## Li Peiqi Group5

Draft for Li Peiqi to review and personalise before submission. It is based on recorded work and does not assert completed manual acceptance, independent authorship of AI code or unreported personal experiences.

My Stage 1 responsibility was to direct the development of the Fishing21 baseline from the supplied planning and numerical rules. I asked for implementation in small steps and for clear class responsibilities, then requested a playable interface and supporting design evidence. The resulting code separates configuration, domain rules and presentation.

The project provides concrete examples of the course concepts. FishingDay manages daily actions, FishingNet owns catches and weight checks, and SettlementRules calculates a result without paying coins. GameSession controls progression and applies the payment once. This separation gives each responsibility a clear owner. Fish sizes use data because their current behaviour is the same. CatchSource is a small abstract contract with actual random and fixed implementations, making polymorphism useful for reproducible checks.

An important challenge in this development was distinguishing a working default configuration from a design that remains consistent when data changes. Further review identified a start button hardcoded to seven days and error display that could leave an old result overlay visible. The agent wrote reproducing checks and corrected those issues. This case shows why generated output needs targeted verification rather than acceptance based only on a successful normal play session.

I used Codex for architecture suggestions, code, tests, documentation and Git operations. I supplied requirements, directed the sequence, provided screenshots and requested review and corrections. The automated tests were agent-run, so I must distinguish them from my own manual verification. Before submission, I need to complete remaining acceptance items, review the code and explain these design choices in my own words. The personal learning and experience statements in the final reflection should be confirmed and expanded by me.
