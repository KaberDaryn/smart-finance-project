# Architecture and use-case diagrams

Three required views are provided. Mermaid `.mmd` files are the primary editable diagram sources; GitHub Markdown pages embed the same source in Mermaid code fences. SVG previews allow review without a Mermaid renderer. DOT files are additional editable layout sources used to generate the SVG previews from the same node/edge specification. No rendered diagram substitutes for its source.

| View | GitHub-readable page | Mermaid source | SVG preview | Additional rendering source |
| --- | --- | --- | --- | --- |
| System Context | [System context](SYSTEM_CONTEXT.md) | [system-context.mmd](system-context.mmd) | [system-context.svg](system-context.svg) | [system-context.dot](system-context.dot) |
| Use Case | [Use cases](USE_CASE.md) | [use-case.mmd](use-case.mmd) | [use-case.svg](use-case.svg) | [use-case.dot](use-case.dot) |
| Component | [Components](COMPONENT.md) | [component.mmd](component.mmd) | [component.svg](component.svg) | [component.dot](component.dot) |

## Boundaries and notation

- System Context shows the whole application and external actors/provider. The database is internal, not a separate external business actor.
- Use Case is a use-case view expressed with Mermaid flowchart notation (not a strict UML metamodel export); user goals are ellipses, system boundary is grouped and mandatory sub-behaviour is marked `include`. It does not imply scanning always saves.
- Component shows clients, server modules, storage and optional external inference. Solid links show dependencies/data paths; it is not a timing/sequence diagram.
- Provider interaction requires consent in the client; API authentication is independently enforced. The service is external and optional for core manual records.
- The supplied earlier source has a separate JavaScript client; the current README describes a Flutter web build. The legacy path is labelled conditional, not asserted to be the current deployed client or feature-equivalent.

## Editing

Edit Mermaid in `.mmd` and the matching Markdown page together. For SVG regeneration from the packaged DOT rendering source, use `dot -Tsvg system-context.dot -o system-context.svg` (and equivalent names). After a semantic change, update both source formats consistently and recheck view labels, requirement IDs and previews. No external diagram service receives project data.
