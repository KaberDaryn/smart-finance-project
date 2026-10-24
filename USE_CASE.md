# Smart Finance — Use Case View

A use-case view in Mermaid flowchart notation, with ellipses for user goals and a system boundary. Financial operations require authenticated account access (FR02); authentication is a precondition, not repeated inside every ellipse. Receipt extraction and review do not imply saving: Save is a separate explicit action and invokes validation. A failed/cancelled scan may end in manual entry instead. The diagram does not claim that view-only review writes merchant memory.

![Smart Finance — Use Case View](use-case.svg)

## Editable Mermaid source

```mermaid
flowchart LR
  subgraph app["Smart Finance system boundary"]
    account(["Register / sign in / sign out<br/>FR01"])
    record(["Enter and save income / expense<br/>FR03 / FR04"])
    history(["Search / filter transaction history<br/>FR05"])
    csv(["Import CSV<br/>FR06"])
    receipt(["Request receipt assistance<br/>FR07"])
    consent(["Give external-processing consent<br/>FR07"])
    extract(["Extract receipt fields<br/>FR07 / FR14"])
    review(["Review / correct proposals<br/>FR08"])
    validate(["Validate required fields<br/>FR03 / FR08"])
    classify(["Request editable category suggestion<br/>FR09"])
    insights(["View summaries / forecast<br/>FR10 / FR11"])
    budget(["Set and review monthly budget<br/>FR12"])
    goal(["Create / update savings goal<br/>FR13"])
  end
  user(["Individual user"])
  provider["External receipt provider"]
  user --> account
  user --> record
  user --> history
  user --> csv
  user --> receipt
  user --> review
  user --> classify
  user --> insights
  user --> budget
  user --> goal
  receipt -.->|"include"| consent
  receipt -.->|"include"| extract
  extract --> provider
  record -.->|"include"| validate
  review -.->|"Optional next step: explicit Save"| record
  classDef external fill:#edf2f7,stroke:#718096,color:#18343e;
  classDef core fill:#e0f2ef,stroke:#177b78,color:#18343e;
  classDef store fill:#fff5df,stroke:#ac873b,color:#18343e;
  class user,provider external;
  class account,record,history,csv,receipt,consent,extract,review,validate,classify,insights,budget,goal core;
```

[Download .mmd](use-case.mmd) · [SVG](use-case.svg) · [DOT layout source](use-case.dot)
