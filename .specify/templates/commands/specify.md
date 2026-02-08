---
description: Определение спецификации истории, уточнение какое произведение создавать
argument-hint: [описание истории]
allowed-tools: Read(//stories/**/specification.md), Read(stories/**/specification.md), Write(//stories/**/specification.md), Write(stories/**/specification.md), Read(//memory/constitution.md), Read(memory/constitution.md), Bash(find:*), Bash(*)
model: claude-sonnet-4-5-20250929
scripts:
  sh: .specify/scripts/bash/specify-story.sh --json
  ps: .specify/scripts/powershell/specify-story.ps1 -Json
---

The user input describes the story they want to create. Based on this description, create a complete story specification document.

User input:
$ARGUMENTS

## Goal

Define the story like a Product Requirements Document (PRD), clarifying "what to create" rather than "how to create." Output specifications marked with `[Needs Clarification]` to allow space for subsequent clarification steps.

## Execution Steps

### 1. Initialize Story Specification

Run `{SCRIPT}` to get path information:
- Parse JSON to get `STORY_NAME` and `SPEC_PATH`
- If it's a new story, create the specification file
- If it already exists, prepare for an update

### 2. Check Constitutional Compliance

If `memory/novel-constitution.md` exists:
- Load constitutional principles
- Ensure the specification aligns with constitutional values
- Reference relevant principles in the specification

### 3. Create Story Specification Document

Create the specification using the following structure:

```markdown
# Story Specification Document

## Metadata
- Story Name: [Name]
- Version: 1.0.0
- Creation Date: [YYYY-MM-DD]
- Status: Draft
- Author: [Author Name]

## I. Story Synopsis

### One-Sentence Story (Elevator Pitch)
[Describe the core of the story in under 30 words]

### Story Introduction (100-200 words)
[Expand on the description, including the main conflict and hints of the ending]

### Core Themes
- Theme: [e.g., "Growth," "Redemption," "Revenge"]
- Deeper Meaning: [What do you want to convey?]
- Emotional Core: [What do you want the reader to feel?]

## II. Target Audience & Positioning

### Target Reader Persona
- Age Group: [Needs Clarification: Specific age range]
- Gender Tendency: [Needs Clarification: Male-oriented/Female-oriented/General]
- Reading Level: [Needs Clarification: Beginner/Intermediate/Advanced]
- Genre Preference: [Fantasy/Urban/Historical, etc.]
- Reading Scenario: [Fragmented time/Deep reading]

### Market Positioning
- Genre Tags: [Primary Tag] + [Secondary Tag]
- Competitor Analysis: Similar to [Work 1]'s [Feature] + [Work 2]'s [Feature]
- Differentiation: [Needs Clarification: What is the core selling point?]

## III. Success Criteria

### Quantitative Metrics
- Target Word Count: [Needs Clarification: 30k/100k/500k]
- Update Frequency: [Needs Clarification: Daily/Weekly/Monthly]
- Completion Time: [Estimated Duration]
- Business Goals: [If applicable]

### Quality Standards
- Logical Consistency: [Must/Should] be free of obvious plot holes
- Character Depth: Protagonist has [X] layers, supporting characters have [Y] layers
- Plot Pacing: [Needs Clarification: Conflict in every chapter/Allow for transition chapters]
- Writing Quality: [Needs Clarification: Easy to understand/Literary/Professional]

### Reader Feedback Metrics
- Target Rating: [If applicable]
- Engagement Rate: [Ratio of comments/favorites]
- Completion Rate: [Desired reader completion percentage]

## IV. Core Requirements

### Must-Haves (P0)
1. [Core Plot Element 1]
2. [Core Character Relationship]
3. [Core Conflict Setup]
4. [Essential World-Building Element]

### Should-Haves (P1)
1. [Elements that enhance the experience]
2. [Content that deepens the theme]
3. [Subplots that enrich characters]

### Could-Haves (P2)
1. [Nice-to-have elements]
2. [Optional subplots]
3. [Bonus Easter eggs]

## V. Constraints

### Content Red Lines
- Absolutely Prohibited: [e.g., Illegal content]
- Avoid: [e.g., Sensitive topics]
- Handle with Care: [Needs Clarification: How to handle romantic relationships]

### Creative Constraints
- Knowledge Limitations: [Needs Clarification: Is specialized knowledge required?]
- Time Limitations: [Deadline for completion]
- Resource Limitations: [e.g., Required reference materials]

### Technical Constraints
- Publishing Platform: [Needs Clarification: Web novel platform/Publication/Self-media]
- Formatting Requirements: [Chapter length, etc.]
- Update Requirements: [Fixed times, etc.]

## VI. Risk Assessment

### Creative Risks
- Writing Difficulty: [Needs Clarification: Where are the challenges?]
- Inspiration Burnout: [How to cope]
- Plot Holes: [Complexity assessment]

### Market Risks
- Homogenization: [How to differentiate]
- Reader Acceptance: [Needs Clarification: Is the innovation excessive?]
- Timeliness: [Will the theme become outdated?]

## VII. Core Decision Points [Needs Clarification]

The following key decisions need to be clarified during the `/clarify` phase:
1. [Decision 1: e.g., Is the protagonist hot-blooded or calm?]
2. [Decision 2: e.g., Is the ending open or complete?]
3. [Decision 3: e.g., Is the narrative single-threaded or multi-threaded?]
4. [Decision 4: e.g., Is the pacing fast or slow?]
5. [Decision 5: e.g., Is the style lighthearted or serious?]

## VIII. Verification Checklist

- [ ] Story synopsis is clear and concise
- [ ] Target audience is accurately defined
- [ ] Success criteria are measurable
- [ ] Core requirements are listed
- [ ] Constraints are identified
- [ ] Risks are assessed
- [ ] Key decision points are marked

## Appendix: References

### Inspiration Sources
- [Source 1]
- [Source 2]

### Reference Works
- [Work 1]: Refer to its [Feature]
- [Work 2]: Refer to its [Feature]

### Additional Notes
[Any other necessary explanations]
```

### 4. Mark Points Needing Clarification

Mark all decision points that require further clarification in the specification:
- Use the format `[Needs Clarification: Specific question]`
- Ensure 5-10 key decision points are marked
- These will be addressed in the `/clarify` step

### 5. Version Management

- Initial Version: 1.0.0 (Draft)
- After Clarification: 1.1.0 (Clarified)
- After Planning: 1.2.0 (Confirmed)
- In Progress: 2.0.0 (Execution)

### 6. Output and Save

- Save the specification to `stories/[story-name]/specification.md`
- Output a success message for creation
- Prompt for the next step: Run `/clarify` to clarify key decisions

## Notes

### Focus on WHAT, Not HOW
- ✅ Correct: "Need a villain that readers will hate"
- ❌ Incorrect: "The villain appears in Chapter 3 and uses a flashback"

### Maintain Specification Flexibility
- Leave room for clarification
- Do not finalize details too early
- Mark all uncertain points

### Relationship with Subsequent Steps
- `/clarify` will handle all `[Needs Clarification]` marks
- `/plan` will create a technical solution based on the clarified specification
- `/analyze` will verify if the implementation meets the specification

Remember: **Specifications define the destination, not the path.**