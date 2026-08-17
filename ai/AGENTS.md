# Agent Instructions

Authoritative agent-facing standards for this repo. Read this before writing code or prose. When in doubt, this file wins over conversation.

---

## Issue-first planning

All non-trivial work starts with a tracked issue, not code.

- Every feature, refactor, spike, research plan, architecture proposal, or roadmap slice must have an issue before implementation starts.
- If an issue exists, extend or clarify it — don't create parallel planning docs with no tracker.
- Do not treat a conversation alone as approval to start untracked implementation.
- Reference issue numbers in every commit and PR. Close issues in PR descriptions with `Closes #N`.

---

## Issue sense-check

Before dispatching implementation on larger or ambiguous issues, run a sense-check pass. Goal: leave a visible reasoning trail on the issue so future agents inherit sharp scope.

Apply this rubric:

1. Does the issue state the user/problem clearly?
2. Is the scope sized for one implementation slice?
3. Are acceptance criteria concrete enough to test?
4. Are dependencies, blockers, or prerequisite issues missing?
5. Does the issue leak into adjacent areas without deciding boundaries?
6. Does the wording introduce ambiguous or non-canonical terms?
7. Does the issue need a spike, child issues, or a narrower first milestone?

Return a structured verdict: **ready | needs-scope | blocked | overscoped**. List what is clear, what is missing, risks, and recommended edits. Under 350 words. No praise. Be direct — useful friction beats agreeable filler.

**Implementation readiness:** one short paragraph stating whether an agent should start now, wait for edits, or split first.

---

## Reuse-first

Before writing new state, utilities, or modules, verify you are not duplicating something that already exists. This is the most common cause of code drift.

1. Search for existing state ownership — extend before creating new.
2. Search for existing utility functions — 80% overlap is close enough; extend, don't duplicate.
3. Search for existing components or modules covering the same shape — compose before recreating.

If you find a near-match that is itself drifted or off-spec, treat it as tech debt. Build the new thing correctly and track the migration separately — don't inherit the drift.

---

## SOLID principles

All code must follow SOLID. These are hard constraints, not aspirational.

### Single Responsibility (SRP)

Every class and module has exactly one reason to change. If you need "and" to describe what it does, split it.

- A class that manages both state transitions and external API calls is doing two things — separate lifecycle from I/O.
- A router/controller that contains business logic is doing two things — it is an adapter, delegate to application services.
- Avoid names like `Orchestrator`, `Manager`, `Handler`, `Service` unless the scope is genuinely narrow. These names attract unrelated responsibilities. Prefer names that describe the single thing the class does: `JobExecutor`, `JobScheduler`, `CentroidBatcher`.

### Open/Closed (OCP)

Modules are open for extension, closed for modification. Prefer composition over conditionals.

- When adding a new variant (provider, data source, strategy), add a new module — don't extend existing ones with `if variant == "new"` branches.
- Use enum + mapping patterns (e.g. `PROVIDER_COLLECTION`) so adding a variant means adding a key, not editing logic.

### Liskov Substitution (LSP)

Subtypes must be substitutable for their base type without the caller knowing.

- Don't override methods to raise `NotImplementedError` — that breaks substitutability.
- Prefer protocols (`typing.Protocol`, TypeScript interfaces) over inheritance when defining contracts between layers.
- If a function accepts a base type, every subtype must honour the same pre/post-conditions.

### Interface Segregation (ISP)

No client should depend on methods it does not use.

- Don't create fat base classes that force implementors to stub unused methods.
- If a consumer only needs two methods from a ten-method class, define a protocol with those two methods and depend on that.
- Keep infrastructure clients focused: one client per external system.

### Dependency Inversion (DIP)

High-level modules must not depend on low-level modules. Both depend on abstractions.

- Application services receive infrastructure dependencies via constructor injection, not by importing and instantiating them internally.
- Wiring concrete implementations happens at the edge (routers, entry points, composition roots) — not in domain or application layers.
- Domain models must never import from infrastructure.

---

## Code organisation

Every piece of behaviour belongs in exactly one place. Pick the one that matches the shape; don't split or mix.

| Shape                                          | Goes in                                                         |
| ---------------------------------------------- | --------------------------------------------------------------- |
| Mutable shared state with methods              | Singleton / class exported as a module-level constant           |
| Pure data transform, no state, no side effects | Free function in a utils/helpers module                         |
| Side-effecting I/O (disk, network, DB)         | Dedicated I/O module, all access routed through one entry point |

Application components/controllers hold only local UI state and delegate everything else to one of the three layers above. If a component is reaching across modules for state, that state probably belongs in a class or store.

---

## Module decomposition

Split a module when **any one** of these is true:

- File exceeds **300 lines**.
- Five or more mutable state declarations, or four or more effect/side-effect blocks.
- An iterated render body exceeds **20 lines** — extract into a dedicated sub-component.
- An inline modal, popover, or overlay is used in more than one place — extract and share.
- The module has three or more visually or logically distinct sections — each section becomes a child.

When splitting, child modules own their own state. Only state genuinely needed by the parent or siblings crosses the boundary — prefer routing through shared state over prop-drilling.

---

## Schema validation for all persisted data

Any data that crosses a system boundary (disk, network, external API, environment) is untrusted input. Validate it. No exceptions for "small" formats or "internal" files.

When introducing a new persisted or ingested format:

1. Define a schema (Zod, JSON Schema, Pydantic, Rust serde — whatever fits the stack) in the same PR.
2. Mark every field's optionality explicitly. Use defaults via the schema, not ad hoc fallbacks.
3. Include a `schemaVersion` field on every top-level persisted shape so future migrations have a hook. Bump it when the shape changes incompatibly.
4. Validate on the boundary:
   - Reads: parse and handle mismatch before touching the data.
   - Writes: validate the value before serialising. Never serialise an unvalidated object.
5. Add a unit test that round-trips a fixture through the schema. For migrating formats, cover both the legacy and migrated shapes.
6. Strip derived/computed fields before write. Persist only canonical inputs; recompute everything else at load time.

If you reach for `as any`, a type cast, or a hand-written type guard at a boundary, stop and write the schema instead.

---

## TDD / BDD — test first

- **New feature:** write a failing test first (unit or E2E depending on scope), then implement.
- **Bug fix:** write a regression test that reproduces the failure, then fix. The test lives in the suite permanently.
- Prefer the narrowest test that covers the behaviour: unit test for pure logic, integration or E2E only for flows that require the full stack.

**Coverage targets:**

- Pure utility functions and I/O modules: **90% line coverage**.
- Shared state / classes / controllers: **80% line coverage**.
- Coverage must not regress on modified files.

---

## Quality gate — zero tolerance

Every PR must pass all of the following with **zero warnings**:

- Linter (ESLint, Clippy, Ruff — whatever the stack uses) — no suppressions without a comment explaining why.
- Formatter (Prettier, Black, rustfmt) — no exceptions.
- Type checker — no `any`, no unresolved types.
- Unit tests.
- E2E / integration tests where applicable.

These are hard gates, not aspirational targets. Do not merge anything that leaves a warning, a disabled rule, or a skipped test without a tracked issue for the follow-up.

Advisory tools (dead-code detection, security scanners) run in CI but do not block merge while their false-positive rates are being tuned. Once findings stabilise, they become hard gates too.

---

## SonarCloud compliance

All repos in the `thefa-win` organisation are analysed by SonarCloud. Treat SonarCloud findings the same as linter errors — they must be resolved before merge.

### Project setup

Every repo must have a `sonar-project.properties` at root. Use the canonical format:

```properties
sonar.projectKey=TheFA-WIN_{repo-name}
sonar.organization=thefa-win
sonar.projectName={repo-name}
```

Add language-specific coverage and source paths:

- **Python**: `sonar.python.coverage.reportPaths=coverage.xml` and `sonar.sources=app/` and `sonar.tests=tests/`
- **TypeScript/JavaScript**: `sonar.javascript.lcov.reportPaths=coverage/lcov.info` and `sonar.sources=src/` and `sonar.tests=tests/`
- **Terraform/IaC**: `sonar.sources=infrastructure/`

Do not copy `sonar-project.properties` from another repo without updating the paths. Stale coverage paths are the most common cause of SonarCloud showing 0% coverage on a project that actually has tests.

### Exclusions

Exclude files that contain no testable logic:

```properties
sonar.exclusions=tests/**/*,**/node_modules/**/*,**/*.d.ts,**/types/**,**/enums/**,**/constants/**
```

Do **not** exclude:
- Application services, domain logic, or infrastructure modules — these contain behaviour and must be analysed.
- Routers/controllers — they are thin, but SonarCloud catches security issues (injection, CORS, auth) that linters miss.
- Configuration files that contain conditional logic.

### Issue categories and how to handle them

| Category | Action | Notes |
| --- | --- | --- |
| **Bug** | Fix immediately | Confirmed logic errors, null dereferences, resource leaks |
| **Vulnerability** | Fix immediately | SQL injection, XSS, insecure crypto, hardcoded secrets |
| **Security Hotspot** | Review and resolve | Mark as SAFE with a one-line justification if the flagged pattern is intentional, FIXED if you changed it, ACKNOWLEDGED only with a tracked issue |
| **Code Smell** | Fix in the same PR if touched | Cognitive complexity, duplicated blocks, unused imports, naming |
| **Coverage** | Meet thresholds on new code | New code must meet the quality gate coverage threshold (typically 80%) |

Never mark a real issue as "Won't Fix" or "False Positive" without a comment explaining why. If SonarCloud flags something that the team disagrees with, suppress it via the SonarCloud UI with a justification — do not add `# nosonar` or `// NOSONAR` inline comments without a tracked rationale.

### Pre-PR local analysis

When a SonarQube MCP server is available, use `analyze_code_snippet` to check files **before** pushing. Pass the full file content plus the project key:

```
analyze_code_snippet(projectKey="TheFA-WIN_{repo}", fileContent=<full file>, language=["python"])
```

This catches issues locally before they appear on the PR's SonarCloud check, saving a CI round-trip. Prioritise running this on:
- New files (no prior analysis baseline).
- Files with complex logic (transforms, validators, business rules).
- Infrastructure-as-code (Terraform, Dockerfiles) — SonarCloud catches misconfigurations that linters miss.

### Common SonarCloud issues to avoid proactively

These are the issues that appear most frequently across the org's repos. Write code that avoids them in the first place:

- **Cognitive complexity** — keep functions under complexity 15. Extract helper functions or early-return instead of deep nesting.
- **Duplicated blocks** — if SonarCloud flags duplication, extract a shared utility. This aligns with the reuse-first rule.
- **Broad exception handling** — `except Exception` or `catch (error)` without re-raising or specific handling. Catch specific exceptions; log and re-raise or handle explicitly.
- **Hardcoded credentials** — never put secrets, tokens, or passwords in source. Use environment variables or secret managers.
- **Unused imports/variables** — the linter should catch these first, but SonarCloud is the backstop.
- **Insecure deserialization** — use schema-validated parsing (Pydantic, Zod) instead of raw `json.loads` into untyped dicts at system boundaries.

### CI integration

SonarCloud analysis runs automatically on PRs via GitHub Actions. The quality gate must pass before merge. If the quality gate fails:

1. Check the SonarCloud PR summary for the specific failing conditions.
2. Fix the issues in the PR — do not open a follow-up issue for quality gate failures.
3. If a finding is a genuine false positive, resolve it in SonarCloud with a comment, then re-run the check.

Do not disable or skip the SonarCloud check in CI workflows.

---

## Living documentation

Maintain documentation alongside code. Every significant architectural decision, data flow, or integration pattern must be documented in `docs/` in the same PR that introduces it.

### What to document

| Change type | Document in |
| --- | --- |
| New bounded context or module | `docs/ARCHITECTURE.md` — add the context, its layer structure, and how it fits into the system |
| New integration (API, message queue, database) | `docs/ARCHITECTURE.md` or a dedicated `docs/{INTEGRATION}.md` — connection params, auth, data flow |
| Migration from legacy system | `docs/MIGRATION.md` — what changed, what was preserved, what was improved |
| Environment variable overrides or runtime config | `docs/OVERRIDES.md` or equivalent — which vars are base vs per-execution, where they come from |
| New domain concept | `docs/UBIQUITOUS_LANGUAGE.md` — canonical term, definition, terms to avoid |

### Rules

- Documentation lives in `docs/*.md` in the repo, not in external wikis or conversation history. The repo is the source of truth.
- Update existing docs when modifying the system they describe — stale docs are worse than no docs.
- Do not document implementation details that are obvious from reading the code. Focus on the **why**, the **how it fits together**, and the **what varies at runtime**.
- Keep each doc under 300 lines. Split into separate files by topic when a doc grows beyond that.
- Use tables, code blocks, and ASCII diagrams over prose walls. Developers scan, they don't read essays.
- Do not create README files or docs unless the PR introduces something worth documenting. Trivial changes (typo fixes, dependency bumps) do not need doc updates.

---

## No spec drift

When a canonical spec, wire format, or architecture document defines how something should work, build to that spec from day one.

- Do not ship a "simpler version for now" with intent to migrate later. Every off-spec caller doubles the eventual migration cost.
- If an existing pattern in the codebase has already drifted from spec, build new work on-spec and track the drift-migration as a separate issue.
- "Match what already shipped" is not a free pass when what shipped is itself off-spec.

---

## Canonical language

Every code identifier, commit message, PR title, issue title, doc page, and test description uses the canonical term from the project glossary.

- Keep a `docs/UBIQUITOUS_LANGUAGE.md` (or equivalent) as the single source of truth for domain terms.
- New domain concept? Add it to the glossary in the same PR that introduces it.
- Terms marked "avoid" must not appear in new code or prose. Migrate them on sight when touching the surrounding file.
- The glossary wins over conversation, branch names, and stale comments.

---

## Comments

Default: write no comments. Only add one when the **why** is non-obvious — a hidden constraint, a subtle invariant, a workaround for a specific bug, behaviour that would surprise a reader.

Never explain **what** the code does (well-named identifiers already do that). Never reference the current task, fix, or callers — those belong in the PR description and rot as the codebase evolves.

---

## Commit and PR hygiene

- Conventional Commits: `type(scope): subject`. Subject ≤ 50 chars. Body only when "why" isn't obvious from the diff.
- Reference issues in every commit. Close them in PR descriptions with `Closes #N`.
- Regression bug fixes must include the regression test in the same commit as the fix.
- Do not amend published commits. Create new commits.

---

## Anti-patterns — remove on sight

These are the most common sources of drift. Do not reproduce them; fix them when you touch adjacent code.

- **Duplicated logic** across modules when a shared utility exists or should exist.
- **Unvalidated data** read from disk, network, or environment without parsing.
- **Backwards-compatibility hacks** — unused `_var` renames, re-exported types, `// removed` comments. If something is unused, delete it.
- **Inline ad hoc error handling** for scenarios that cannot happen — trust framework and internal guarantees; validate only at true system boundaries.
- **Comment noise** — comments that restate the code, reference the PR/task, or explain what instead of why.
- **Skipped tests** without a tracked issue for re-enabling.
- **Suppressions without explanation** — disabled lint rules, `@ts-ignore`, `#[allow(...)]` must have a one-line comment explaining the exception.

---

## CI discipline

When primary CI signals (lint, format, type check, tests) pass and the PR is otherwise mergeable, stop. Do not dig into incidental or infrastructure-level check failures unless the user asks. Report status and move on. Yard work on CI config pulls focus off deliverables.

---

## General defaults

- Prefer editing existing files over creating new ones.
- No features, refactors, or abstractions beyond what the task requires. Three similar lines beats a premature abstraction.
- No error handling or validation for scenarios that cannot happen. Trust internal code and framework guarantees.
- No half-finished implementations. If a feature is not ready, do not merge it.
- No backwards-compat shims when you can just change the code.
- Security: validate all inputs at system boundaries. Never trust data from outside. Prefer allowlists. Sanitise anything rendered as HTML or executed.
