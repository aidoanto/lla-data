# Lifeline SXO Experiment Pitch

## A low-risk SXO experiment on three high-opportunity self-led support pages

Lifeline already has meaningful search visibility across self-led support content. This experiment is about converting more of that existing visibility into a clearer, safer, more useful support experience on three pages where the gap between impressions and clicks is especially large.

This is a time-boxed content and UX experiment, not a request for a major product commitment. The ask from Amy, Mel, Ben and Varun is approval to test a contained set of changes on three pages, measure the result over 90 days, and use the findings to decide whether SXO should become a repeatable practice.

---

## Why now

The research in [REPORT1](./REPORT1.md) shows that Lifeline's self-led support cohort generated, over the `90-day` analysis window from `14 December 2025` to `12 March 2026`:

- `14.2 million` impressions
- `87.5k` clicks
- `123.1k` organic sessions
- `0.62%` cohort CTR

That is a very large discovery surface, but much of it is under-converted. The strongest classic SEO upside is concentrated in `support-toolkit` techniques-and-guides pages, especially where we already rank on page one but are not turning visibility into enough clicks or a stronger onward journey.

The meeting discussion in [SEO-weekly-1](../meetings/SEO-weekly-1.md) sharpened the same conclusion: we should focus on article-style pages where Lifeline can genuinely improve the user experience, rather than pushing harder on national service pages where another provider may be the better destination.

![Self-led support search surface by segment](./assets/report1_experiment/cohort-context-by-segment.png)

---

## Strategy in brief

This proposal follows the mission-led SXO approach outlined in [sxo-strategy-proposal.md](../sxo-strategy-proposal.md).

At Lifeline, search optimisation should not be treated as a traffic growth exercise in isolation. The purpose is to improve the search-to-support experience for people seeking practical, low-barrier help, while staying clinically sound and aligned with Lifeline's role in the broader support ecosystem.

For this experiment, that means:

- choosing pages where the user intent is a strong fit for Lifeline's self-led support role
- improving how useful the result looks in the SERP and how quickly the page becomes helpful once someone lands
- measuring success using CTR, engagement and onward support behaviour, not just rankings

---

## What the research shows

Pages 1 to 3 from [REPORT1_next_steps](./REPORT1_next_steps.md) are the clearest candidates for a first sprint because they combine strong demand, mission fit and relatively practical edits.

| Page | Impressions | Clicks | CTR | Avg position | What it suggests |
| --- | ---: | ---: | ---: | ---: | --- |
| Self-care for mental health and wellbeing | 748.6k | 1.1k | 0.15% | 6.5 | We are visible, but the result and page are not promising practical value quickly enough |
| Finding the right therapist | 492.6k | 368 | 0.07% | 4.7 | We rank strongly, but the page reads more like general advice than a decision guide |
| Finding relief through grounding techniques | 209.4k | 1.4k | 0.66% | 7.3 | Demand is rising and the topic fits Lifeline well, but the page could get users to relief faster |

The broader report also shows why these topics matter now:

- `self-care` demand is large and increasingly list-driven
- therapist-choice queries are high-intent and practical
- grounding queries are growing and are well suited to immediate, low-friction support content

![Focus-page baseline comparison](./assets/report1_experiment/focus-pages-comparison.png)

---

## Experiment scope

This experiment covers only the following three pages:

1. Self-care for mental health and wellbeing
2. Finding the right therapist
3. Finding relief through grounding techniques

Pages 4 and 5 from the original shortlist are intentionally out of scope for now:

- `Managing intrusive thoughts`
- `Understanding and managing anger`

Those remain strong opportunities, but the current plan is to keep them in a separate research and clinical-framing track rather than folding them into the first delivery sprint.

In-scope changes for this experiment:

- title and meta refinements
- content re-ordering
- jump links or scannability improvements
- clearer onward paths to related support content
- stronger but clinically appropriate support escalation cues

Out of scope:

- any CMS or design-system work
- changes that materially alter risk framing without clinical review

---

## How we landed on these changes

These recommendations come from a combined SXO review process rather than from rankings alone.

- warehouse analysis from BigQuery using `searchconsole.seo_page_daily` and `searchconsole.curated_search_query_page_daily`
- page-level review of impressions, clicks, CTR and average position across the self-led support cohort
- query-level review to identify the dominant head-term or intent cluster for each shortlisted page
- live review of the current Lifeline pages to assess how quickly they answer the likely user need
- live Australian SERP review to understand which page formats are winning the click
- mission and practicality weighting from [REPORT1](./REPORT1.md), so the shortlist favours pages where Lifeline can add value safely and with manageable effort

In practice, the changes below sit at the overlap between:

- strong existing visibility
- weak click-through or intent fit
- strong mission alignment for self-led support
- realistic, low-risk content and UX changes

---

## Proposed changes by page

### 1. Self-care for mental health and wellbeing

Data and rationale:

- the page generated `748.6k` impressions with only `1.1k` clicks, for a `0.15%` CTR, despite an average position of `6.5`
- the dominant query signal is `self care ideas`, which drove `474.1k` impressions in the report's most recent 56-day query window
- the current page is relevant, but practical ideas are not surfaced quickly enough for a SERP shaped by list-style, immediately useful results

Proposed changes:

- move practical ideas much higher on the page
- tighten title and meta to better reflect `self care ideas` intent
- create clearer onward paths to grounding, journaling and other related support content

### 2. Finding the right therapist

Data and rationale:

- the page generated `492.6k` impressions and only `368` clicks, for a `0.07%` CTR, while already holding a strong average position of `4.7`
- the main query theme is `how to choose a therapist`, with `397.3k` impressions in the most recent 56-day query window
- this suggests a promise gap rather than a ranking gap: the user intent is highly practical, but the current page reads more like general advice than a clear decision guide

Proposed changes:

- reframe the opening into a practical therapist-choice checklist
- add stronger Australia-specific guidance such as pathways, cost cues and what to ask
- improve onward links into treatment-plan and therapy-navigation content

### 3. Finding relief through grounding techniques

Data and rationale:

- the page generated `209.4k` impressions, `1.4k` clicks and a `0.66%` CTR at an average position of `7.3`
- grounding demand is rising, and the topic is a strong fit for Lifeline because users are often looking for something immediate, practical and low-friction
- the current page has relevant content, but this is a distress-state use case where speed to usefulness matters as much as depth

Proposed changes:

- put one or two grounding exercises above the fold
- add a calm `try this now` block for immediate use
- strengthen the pathway to support if self-help is not enough

These are intentionally pragmatic SXO edits. The point is to make already-visible pages more obviously useful and easier to act on, not to rewrite the whole section.

---

## Measurement framework

Success should be measured after a `90-day` post-launch window against a matched pre-change baseline drawn from the same BigQuery sources used in [REPORT1](./REPORT1.md).

### Primary KPI

CTR uplift at both page level and dominant head-term cluster level.

### Secondary KPIs

- organic clicks
- engaged sessions
- onward navigation to relevant support pages

### Guardrail KPI

No weakening of safety language, support escalation cues or clinically important framing.

### Page-level targets

| Page | Baseline CTR | Target CTR | What else should improve |
| --- | ---: | ---: | --- |
| Self-care for mental health and wellbeing | 0.15% | 0.22%+ | Clicks from self-care terms, organic entrances, onward clicks to related support-toolkit pages |
| Finding the right therapist | 0.07% | 0.12%+ | Clicks from therapist-choice queries, onward navigation to treatment-plan and directory-support content |
| Finding relief through grounding techniques | 0.66% | 0.85%+ | Clicks from grounding queries, onward engagement with calming and support pathways |

![Baseline vs target CTR](./assets/report1_experiment/ctr-targets.png)

---

## Stakeholder ask

### Practice team

The ask is to confirm that the proposed experiment is clinically sound and a good fit for Lifeline's self-led support role, especially where changes affect advice hierarchy, reassurance language or support escalation.

### Product team

The ask is to endorse a contained, low-risk content and UX experiment on three pages where we already have visibility but weak click-through performance.

---

## Delivery approach and guardrails

Suggested delivery model:

1. Draft proposed edits for the three pages
2. Review with clinical / knowledge and quality
3. Make the approved content and UX updates
4. Measure performance for 90 days
5. Publish a short follow-up note with findings

Guardrails:

- clinical review for any change affecting advice, safety or risk framing
- use existing content and UX patterns where possible
- keep implementation effort intentionally light
- treat this as a test-and-learn sprint, not a standing commitment

---

## Appendix and links

- Full research report: [REPORT1.md](./REPORT1.md)
- Agreed next steps: [REPORT1_next_steps.md](./REPORT1_next_steps.md)
- Broader SXO strategy: [sxo-strategy-proposal.md](../sxo-strategy-proposal.md)
- Meeting context: [SEO-weekly-1.md](../meetings/SEO-weekly-1.md)

Optional later additions:

- SERP screenshot placeholder: `self-care ideas` results page
- SERP screenshot placeholder: `how to choose a therapist` or `grounding techniques` results page

Those screenshots are deliberately deferred from v1 so the first pass stays focused on the core pitch and measurable experiment design.
