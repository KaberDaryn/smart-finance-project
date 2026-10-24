# Smart Finance — System Context

The finance application is one system boundary. External actors are the individual user, the team/local operator and an optional inference provider. There is no bank/payment-system integration. The operator is a deployment role, not an implemented remote admin console. Provider calls do not directly save ledger records. Related requirements: FR01–FR14, NFR01/NFR05.

![Smart Finance — System Context](system-context.svg)

## Editable Mermaid source

```mermaid
flowchart LR
  user(["Individual KZT user<br/>Records / reviews / plans"])
  operator(["Team / local operator<br/>Deploys and configures"])
  system["Smart Finance<br/>Client + API + financial storage<br/>Records, insights, budgets and goals"]
  provider["External Gemini provider<br/>Optional receipt inference"]
  user -->|"Manual records, plans, consented image / confirmation"| system
  system -->|"History, summaries, editable proposals / errors"| user
  operator -->|"Local startup, storage / server-side configuration"| system
  system -->|"Image + extraction request after consent"| provider
  provider -->|"Untrusted field proposals / failure"| system
  classDef external fill:#edf2f7,stroke:#718096,color:#18343e;
  classDef core fill:#e0f2ef,stroke:#177b78,color:#18343e;
  classDef store fill:#fff5df,stroke:#ac873b,color:#18343e;
  class user,operator,provider external;
  class system core;
```

[Download .mmd](system-context.mmd) · [SVG](system-context.svg) · [DOT layout source](system-context.dot)
