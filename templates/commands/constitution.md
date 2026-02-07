```markdown
---
description: Create or update the novel writing constitution, defining uncompromising creative principles
argument-hint: [Description of creative principles]
allowed-tools: Write(//memory/constitution.md), Write(memory/constitution.md), Read(//memory/**), Read(memory/**), Bash(find:*), Bash(*)
model: claude-sonnet-4-5-20250929
scripts:
  sh: .specify/scripts/bash/constitution.sh
  ps: .specify/scripts/powershell/constitution.ps1
---

User input: $ARGUMENTS

## Goal

Establish the core principles and values for novel writing, forming a "constitution" document. These principles will guide all subsequent creative decisions.

## Execution Steps

### 1. Check Existing Documents

**First, check if a style reference document exists** (from `/book-internalize`):
```bash
test -f .specify/memory/style-reference.md && echo "exists" || echo "not-found"
```

- If it exists, use the Read tool to read `.specify/memory/style-reference.md`
- Then inform the user: "Detected that you have completed the analysis of the benchmark work. I will use this style as a reference to draft the constitution for you."

**Next, check for an existing constitution**:
```bash
test -f .specify/memory/constitution.md && echo "exists" || echo "not-found"
```

- If it exists (outputs "exists"), use the Read tool to read `.specify/memory/constitution.md` and prepare for an update.
- If it does not exist (outputs "not-found"), skip the reading step and prepare to create a new constitution directly.

### 2. Collect Creative Principles

Based on user input, collect principles for the following dimensions (if not provided, ask or infer):

#### Core Values
- What core ideas should the work convey?
- What are the absolute bottom lines that cannot be violated?
- What is the fundamental purpose of creation?

#### Quality Standards
- Logic consistency requirements
- Text quality standards
- Update frequency commitment
- Completion guarantee

#### Creative Style Principles
- Narrative style (concise/ornate/plain/poetic)
- Pacing control (fast/slow/well-paced)
- Emotional tone (passionate/profound/lighthearted/serious)
- Language characteristics (ancient/modern/colloquial/formal)

#### Content Principles
- Character development principles
  - Every character must have a complete motivation
  - Character growth must be logical
  - Dialogue must be consistent with the character's identity
- Plot design principles
  - Conflict design principles
  - Plot twist rationality requirements
  - Foreshadowing resolution principles
- World-building principles
  - Setting consistency requirements
  - Detail authenticity standards
  - Cultural research requirements

#### Reader-Oriented Principles
- Target audience definition
- Reader experience guarantee
- Interaction and feedback principles

#### Creative Discipline
- Daily writing standards
- Revision and refinement process
- Version control principles

### 3. Draft the Constitution Document

Use the following template structure:

```markdown
# Novel Writing Constitution

## Metadata
- Version: [Version number, e.g., 1.0.0]
- Creation Date: [YYYY-MM-DD]
- Last Revised: [YYYY-MM-DD]
- Author: [Author's Name]
- Work: [Work Title or "General"]

## Preamble
[Explain why this constitution is needed and its binding force]

## Chapter 1: Core Values

### Principle 1: [Principle Name]
**Statement**: [Clear statement of the principle]
**Rationale**: [Why this principle is important]
**Execution**: [How to embody it in the creation process]

### Principle 2: [Principle Name]
[Same format as above]

## Chapter 2: Quality Standards

### Standard 1: Logical Consistency
**Requirement**: [Specific requirements]
**Verification Method**: [How to verify]
**Consequences of Violation**: [Must be corrected]

[More standards...]

## Chapter 3: Creative Style

### Style Principle 1: [Name]
**Definition**: [What this style is]
**Example**: [Specific examples]
**Taboo**: [What absolutely not to do]

[More style principles...]

## Chapter 4: Content Guidelines

### Character Development Guidelines
[Specific guideline content]

### Plot Design Guidelines
[Specific guideline content]

### World-Building Guidelines
[Specific guideline content]

## Chapter 5: Reader's Contract

### Promises to Readers
- [Promise 1]
- [Promise 2]
- [Promise 3]

### Bottom Line Guarantees
- [Guarantee 1]
- [Guarantee 2]

## Chapter 6: Revision Procedures

### Revision Trigger Conditions
- Major changes in creative direction
- Accumulation of reader feedback
- Personal growth and evolving understanding

### Revision Process
1. Propose revision motion
2. Assess impact
3. Update version
4. Record changes

## Appendix: Version History
- v1.0.0 (Date): Initial version
- [Subsequent version records]
```

### 4. Version Management

- **Major Version Number**: Significant principle changes or deletions
- **Minor Version Number**: Addition of principles or chapters
- **Revision Number**: Wording optimization, clarification of explanations

### 5. Consistency Propagation

Check and update related documents to maintain consistency:
- Reference constitution principles in subsequent commands
- Suggest updating the creative philosophy section in README

### 6. Generate Impact Report

Output the impact of constitution creation/update:
```markdown
## Constitution Impact Report
- Version: [Old Version] → [New Version]
- New Principles: [List]
- Modified Principles: [List]
- Scope of Impact:
  ✅ Specifications must adhere to the constitution
  ✅ Planning must comply with principles
  ✅ Creative execution must follow guidelines
  ✅ Verification must check compliance
```

### 7. Output and Save

- Save the constitution to `.specify/memory/constitution.md`
- Output a success message for creation/update
- Prompt for the next step: `/specify` to define story specifications

## Execution Principles

### Must Adhere To
- Principles must be verifiable, not too abstract
- Use clear terms like "must," "prohibit," etc.
- Each principle must have a clear rationale

### Should Include
- At least 3-5 core values
- Clear quality bottom lines
- Actionable creative guidelines

### Avoid
- Vague slogans (e.g., "pursue excellence")
- Unverifiable requirements
- Overly restrictive clauses that stifle creativity

## Example Principles

**Good Principles**:
- "The actions of main characters must have a clear chain of motivation; actions occurring 'because the plot requires it' are forbidden."
- "Every foreshadowing element must be resolved or explained within a reasonable timeframe (maximum 10 chapters)."
- "Never use modern internet slang that breaks the immersion of an ancient setting."

**Bad Principles**:
- "Write well" (Too vague)
- "Pursue artistry" (Unverifiable)
- "Satisfy the readers" (Unclear standard)

## Subsequent Process

After the constitution is established, all subsequent creative steps must adhere to it:
1. `/specify` - Specifications must align with constitutional values
2. `/plan` - Plans must follow constitutional principles
3. `/write` - Creation must comply with constitutional guidelines
4. `/analyze` - Verification must check constitutional compliance

Remember: **The constitution is the supreme guideline, but it can also be revised progressively.**
```