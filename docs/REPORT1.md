# REPORT1: Self-Led Support SXO Opportunities

## Executive summary

This report reviews Lifeline Australia's self-led support cohort using warehouse data from **December 14, 2025 to March 12, 2026**, with data freshness checks showing `searchconsole.seo_page_daily` current through **March 14, 2026** and `curated_search_query_page_daily` through **March 13, 2026**. I also reviewed live page content and Australian SERPs on **March 16, 2026**, with `pytrends` used only as a directional signal.

The biggest traditional SEO opportunities in the cohort are concentrated in `support-toolkit` technique-and-guide articles rather than national service directory pages. The strongest opportunities are not pages where Lifeline has no visibility at all; they are pages where Lifeline already has meaningful visibility, but the result and page experience are not converting that visibility into clicks or a clearly stronger user journey.

The clearest pattern is a large gap between impressions and clicks on broad self-help queries such as self-care, choosing a therapist, intrusive thoughts, anger, and grounding techniques. In most of those cases, the right play is not "chase more rankings at any cost". It is to make the result more obviously useful from the SERP, then make the page faster to use, more specific to the intent, and better connected to next-step support.

I have **not** prioritized the highest-impression national-service pages as the main editorial opportunities, even though some of them are large search surfaces. They are less attractive SXO bets because many of those searches are better satisfied by the primary service itself, and aggressive optimization risks crowding out better-fit providers. The recommended list therefore focuses on article-style self-led support pages where Lifeline can improve user value without creating the same mission tradeoff.

## Method and scope

- In scope: `/get-help/support-toolkit*`, `/get-help/national-services*`, `/get-help/hear-from-others*`
- Out of scope for the final ranked list: crisis-service pages, volunteering, fundraising, and general about pages
- Data sources:
  - BigQuery page-level performance from `searchconsole.seo_page_daily`
  - Query/page drivers from `searchconsole.curated_search_query_page_daily`
  - Live content review from `lifeline.org.au`
  - Australian SERP checks via SerpAPI
  - Directional topic validation via `pytrends`
- Ranking rubric:
  - `35%` SEO upside
  - `35%` mission and user-value fit
  - `20%` implementation practicality
  - `10%` measurement quality

## Current state of LLA SXO for self-led support

Across the scoped cohort, Lifeline generated **14.2 million impressions**, **87.5k clicks**, and **123.1k organic sessions** over the 90-day window. The cohort CTR was **0.62%**. That is a large discovery surface, but it is unevenly distributed and much of it is under-converted.

![Current search surface across the self-led support cohort](assets/report1/current-state-by-segment.png)

Three high-level patterns stand out:

1. **Traditional SEO upside is concentrated in techniques-and-guides pages.**  
   The `techniques-and-guides` subfolder produced **4.8 million impressions** and **18.2k clicks**, with many articles sitting in the position 4-10 band where title, snippet, and intent fit can still move performance materially.

2. **National service pages drive scale, but they are not the best use of editorial effort.**  
   `national-services` pages produced **4.24 million impressions** and **42.1k clicks**, but many of those results point to other organizations' primary services. From a mission perspective, that makes them more suitable for careful maintenance than for aggressive growth work.

3. **Several article pages are seeing strong demand shifts that content has not fully kept up with.**  
   Self-care, grounding, and journaling show rising or newly-emerging trend signals. Intrusive thoughts, self-harm, and mental health care plan searches show consistently high need. These are better fits for SXO work because the content can directly improve clarity, reassurance, and next-step navigation.

### Traditional SEO watchlist before mission weighting

If I rank pages mostly on classic SEO signals alone, the strongest opportunities are:

| Page | Why it stands out |
| --- | --- |
| [Self-care for mental health and wellbeing](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/self-care-for-mental-health-and-wellbeing/) | 748.6k impressions, 0.15% CTR, avg position 6.5; query demand has surged faster than click capture |
| [Finding the right therapist](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-the-right-therapist/) | 492.6k impressions, 0.07% CTR, avg position 4.7; very large query surface with thin click capture |
| [Managing intrusive thoughts](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/managing-intrusive-thoughts/) | 449.2k impressions, 0.45% CTR, avg position 6.6; strong mission fit and durable demand |
| [Understanding and managing anger](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/understanding-and-managing-anger/) | 363.3k impressions, 0.23% CTR, avg position 9.6; wide intent spread and weak SERP conversion |
| [Eye Movement Desensitization and Reprocessing (EMDR)](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/eye-movement-desensitization-and-reprocessing-edmr/) | 313.2k impressions, 0.26% CTR, avg position 12.1; clear naming/snippet issue and solid topic demand |

![Traditional SEO opportunity zone for support-toolkit pages](assets/report1/traditional-opportunity-zone.png)

That classic view is useful, but incomplete. The final ranking below balances those signals against mission fit, crowd-out risk, practicality, and how clearly success could be measured.

## Final ranked opportunities

| Rank | Page | Weighted score / 5 | Why this is the right level of effort now |
| --- | --- | ---: | --- |
| 1 | [Self-care for mental health and wellbeing](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/self-care-for-mental-health-and-wellbeing/) | 4.58 | Huge impression base, rising demand, clear intent mismatch, and straightforward content improvements |
| 2 | [Finding the right therapist](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-the-right-therapist/) | 4.50 | Enormous query surface, strong mission fit, and clear opportunity to be more practical and Australia-specific |
| 3 | [Finding relief through grounding techniques](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-relief-through-grounding-techniques/) | 4.49 | Rising demand, good mission fit, and easy-to-ship UX changes for a high-stress use case |
| 4 | [Managing intrusive thoughts](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/managing-intrusive-thoughts/) | 4.47 | High-need topic where better structure and reassurance could improve both CTR and user outcomes |
| 5 | [Understanding and managing anger](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/understanding-and-managing-anger/) | 4.14 | Strong visibility with weak click conversion; good candidate for better intent segmentation and self-assessment UX |
| 6 | [Eye Movement Desensitization and Reprocessing (EMDR)](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/eye-movement-desensitization-and-reprocessing-edmr/) | 3.85 | High search demand plus a concrete copy issue (`EDMR` vs `EMDR`) make this a practical fix with upside |
| 7 | [What is a Mental Health Treatment Plan?](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/what-is-a-mental-health-treatment-plan/) | 3.85 | Valuable service-navigation content, but should support official sources rather than try to outrank them |
| 8 | [Self-harm](https://www.lifeline.org.au/get-help/support-toolkit/topics/self-harm/) | 3.69 | Mission-critical page where the priority is safer, clearer support pathways rather than raw traffic growth |
| 9 | [Journaling your thoughts and feelings](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/journaling-your-thoughts-and-feelings/) | 3.56 | Rising topic interest and easy content refresh path, though mission impact is less direct than the pages above |
| 10 | [Acceptance and commitment therapy (ACT)](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/acceptance-and-commitment-therapy-act/) | 3.32 | Good authority fit and existing visibility, but lower upside because Lifeline already ranks strongly |

![Final weighted SXO opportunity ranking](assets/report1/final-priority-ranking.png)

## Opportunity briefs

### 1. [Self-care for mental health and wellbeing](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/self-care-for-mental-health-and-wellbeing/)

**Current picture**  
`748.6k` impressions, `1.1k` clicks, `0.15%` CTR, average position `6.5`. The top query is `self care ideas`, which drove `474.1k` impressions over the most recent 56-day query window, while Australian pytrends interest lifted meaningfully in the second half of the last year. SerpAPI shows Lifeline ranking `#2`, but the SERP is crowded by list-style article publishers.

**Likely issue / opportunity**  
The page is conceptually right, but the SERP intent is more list-driven and immediately practical than the current result suggests. The live page explains self-care well, yet the result is not advertising enough immediate utility.

**Recommended changes**
- Rewrite the title and meta to foreground practical value, not just definition. Example direction: "Self-care ideas for bad mental health days".
- Move a scannable ideas block much higher on the page and add an on-page jump menu.
- Add clearer segmentation such as "quick wins in 5 minutes", "when you feel flat", and "when you're overwhelmed".
- Add stronger onward paths to [Finding relief through grounding techniques](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-relief-through-grounding-techniques/), [Journaling your thoughts and feelings](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/journaling-your-thoughts-and-feelings/), digital detox, and therapist-support content.
- Add a clearer support escalation cue for people whose "self-care" search is masking acute distress.

**How to measure success**
- Primary: CTR uplift on `self care ideas` and related variants.
- Secondary: increase in organic sessions from non-brand self-care queries.
- Experience: clicks into related support-toolkit pages and improved page-level engaged session volume.

**Mission alignment note**  
High. This is a low-risk way to help users find safe, practical, low-barrier wellbeing actions earlier.

### 2. [Finding the right therapist](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-the-right-therapist/)

**Current picture**  
`492.6k` impressions, `368` clicks, `0.07%` CTR, average position `4.7`. The dominant query is `how to choose a therapist`, with `397.3k` impressions in the most recent 56-day query window. Lifeline ranks `#1` in the live AU SERP, but the click-through rate remains extremely weak.

**Likely issue / opportunity**  
This looks like a SERP-to-page promise problem rather than a pure ranking problem. The query asks for practical decision help, but the page currently reads more like general advice than a decisive selection guide.

**Recommended changes**
- Reframe the top section into a clear therapist-choice checklist.
- Add Australia-specific guidance: directories, referral pathways, cost signals, and what to ask in a first session.
- Add side-by-side prompts such as "psychologist vs counsellor vs therapist" and "questions to ask before booking".
- Strengthen internal links to [What is a Mental Health Treatment Plan?](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/what-is-a-mental-health-treatment-plan/) and first-therapy-session content.

**How to measure success**
- Primary: CTR improvement on `how to choose a therapist` and related "find a therapist" queries.
- Secondary: organic entrances and clicks through to official practitioner directories.
- Experience: onward navigation into therapy-adjacent pages.

**Mission alignment note**  
High. Lifeline is helping users make a safer, more informed transition toward longer-term support rather than replacing clinical providers.

### 3. [Finding relief through grounding techniques](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-relief-through-grounding-techniques/)

**Current picture**  
`209.4k` impressions, `1.4k` clicks, `0.66%` CTR, average position `7.3`. The page's top query is `grounding techniques`, and related demand in pytrends rose sharply in the second half of the past year. Lifeline ranks `#3` in the live SERP behind general health and worksheet-style resources.

**Likely issue / opportunity**  
The topic is growing and the page is relevant, but the page should get users to relief faster. For this kind of distress-state query, speed to usefulness matters as much as depth.

**Recommended changes**
- Put one or two grounding exercises above the fold before the longer explanatory sections.
- Add a "try this now" block with 5-4-3-2-1 and one-minute grounding options.
- Break out versions by use case: panic, racing thoughts, overwhelm, dissociation.
- Add a calm, explicit pathway to immediate support if grounding is not enough.

**How to measure success**
- Primary: clicks and CTR on `grounding techniques` and `grounding exercises`.
- Secondary: growth in organic sessions and improved click-through to related calming or crisis-adjacent content.
- Experience: higher interaction with internal links and sustained visibility gains on panic-related variants.

**Mission alignment note**  
Very high. This is exactly the kind of practical, low-friction self-help content Lifeline can provide well.

### 4. [Managing intrusive thoughts](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/managing-intrusive-thoughts/)

**Current picture**  
`449.2k` impressions, `2.0k` clicks, `0.45%` CTR, average position `6.6`. The top query is simply `intrusive thoughts`, with `102.0k` impressions in the most recent 56-day query window. Lifeline ranks `#3` in the live AU SERP behind Harvard Health and ADAA.

**Likely issue / opportunity**  
The topic has strong mission fit and stable demand, but the page could do more to reassure users quickly, normalize the experience, and distinguish between common intrusive thoughts and cases where further help is needed.

**Recommended changes**
- Add a short, high-visibility reassurance summary near the top.
- Pull "what to do right now" strategies above more descriptive material.
- Add clearer distinction between intrusive thoughts, OCD-related patterns, trauma responses, and immediate safety risk.
- Add a small support ladder: self-help first, then when to talk to a GP, therapist, or Lifeline.

**How to measure success**
- Primary: CTR and clicks on `intrusive thoughts` and "how to stop intrusive thoughts" variants.
- Secondary: more traffic to [Finding relief through grounding techniques](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-relief-through-grounding-techniques/) and therapy-navigation pages.
- Experience: stronger engaged-session volume from organic landings.

**Mission alignment note**  
Very high. This is a common, frightening experience where calmer framing and clearer next steps create real user value.

### 5. [Understanding and managing anger](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/understanding-and-managing-anger/)

**Current picture**  
`363.3k` impressions, `840` clicks, `0.23%` CTR, average position `9.6`. The page appears for very broad terms such as `anger`, `anger issues`, and `anger management`. Lifeline ranks `#1` for `anger issues` in the live SERP.

**Likely issue / opportunity**  
The current article is thoughtful, but broad anger queries likely include several intents: self-recognition, help for a partner or family member, immediate de-escalation, and longer-term management. The page could match those entry points more explicitly.

**Recommended changes**
- Add an above-the-fold route chooser: "for me", "for someone I care about", "I need to calm down now".
- Introduce a short self-check or symptom checklist for unhealthy anger patterns.
- Add a clearer action section with immediate de-escalation steps before longer educational copy.
- Increase visibility of support pathways when anger links to risk, abuse, or self-harm.

**How to measure success**
- Primary: CTR uplift on `anger issues` and related variants.
- Secondary: stronger query coverage on longer-tail anger-management queries.
- Experience: clicks into downstream support pages and better retention from organic landings.

**Mission alignment note**  
High. This topic sits close to relationship strain, distress, and escalation risk, so user-value gains here are meaningful.

### 6. [Eye Movement Desensitization and Reprocessing (EMDR)](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/eye-movement-desensitization-and-reprocessing-edmr/)

**Current picture**  
`313.2k` impressions, `813` clicks, `0.26%` CTR, average position `12.1`. The main query is `emdr therapy`. Lifeline ranks `#4` in the live AU SERP. The page title and H1 currently use **`EDMR`** instead of **`EMDR`**, even though the body copy uses the correct term.

**Likely issue / opportunity**  
This is both a demand opportunity and a content hygiene issue. The typo weakens credibility and likely reduces click confidence on a therapy acronym query where users expect precision.

**Recommended changes**
- Correct `EDMR` to `EMDR` in the title, H1, and any visible headings or metadata.
- Tighten the opening definition and add a plain-language "who this is for" summary.
- Add a clearer section on what EMDR can and cannot help with.
- Link to [Finding the right therapist](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-the-right-therapist/) and [What is a Mental Health Treatment Plan?](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/what-is-a-mental-health-treatment-plan/) so the article helps users act on intent.

**How to measure success**
- Primary: CTR uplift on `emdr therapy`, `emdr`, and `what is emdr`.
- Secondary: improved average position and stronger click growth from trauma-treatment queries.
- Experience: outbound or internal clicks toward therapy-navigation resources.

**Mission alignment note**  
Moderate to high. Lifeline can credibly explain the therapy and guide people toward next steps without pretending to be the therapy provider.

### 7. [What is a Mental Health Treatment Plan?](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/what-is-a-mental-health-treatment-plan/)

**Current picture**  
`100.4k` impressions, `1.1k` clicks, `1.06%` CTR, average position `6.7`. The main query is `mental health care plan`. In the live AU SERP, Lifeline is not in the top five; the query is dominated by Healthdirect, Services Australia, and other official providers.

**Likely issue / opportunity**  
This is useful content, but it sits in an ecosystem where official sources should often win the transactional click. The opportunity here is to be the best explanatory bridge, not to compete head-on with government service pages.

**Recommended changes**
- Make the page explicitly "explainer plus preparation guide" rather than "official source substitute".
- Add a prominent "check the current official rules" box with links to Healthdirect and Services Australia.
- Refresh the copy with visible currency markers and any important policy caveats.
- Add stronger preparation help: questions for your GP, what paperwork to bring, and what happens after the first six sessions.

**How to measure success**
- Primary: clicks from educational rather than purely transactional treatment-plan queries.
- Secondary: better performance on long-tail queries like "how to get a mental health care plan".
- Experience: outbound clicks to official resources and onward clicks to [Finding the right therapist](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-the-right-therapist/) or first-therapy-session content.

**Mission alignment note**  
High, but bounded. This should support users through a confusing process without crowding out authoritative government guidance.

### 8. [Self-harm](https://www.lifeline.org.au/get-help/support-toolkit/topics/self-harm/)

**Current picture**  
`233.3k` impressions, `5.5k` clicks, `2.36%` CTR, average position `8.4`. Lifeline ranks `#1` for `self harm` in the live AU SERP. The page already performs relatively well, and long-tail query mix is broad and safety-sensitive.

**Likely issue / opportunity**  
This is not a conventional "traffic growth" page. The right opportunity is to improve safety, clarity, and support pathways while preserving what is already working.

**Recommended changes**
- Audit the top section for speed to reassurance and support options.
- Make immediate-help pathways more visible without overwhelming the page.
- Add clearer routeing for people who self-harm, people supporting someone else, and people searching out of fear or curiosity.
- Review query coverage for harmful or ambiguous intents and make sure the copy does not create accidental harm.

**How to measure success**
- Primary: maintain or improve CTR on core supportive queries while monitoring for harmful-query exposure.
- Secondary: stronger movement into crisis-support or related self-help pathways.
- Experience: page interaction with support CTAs rather than raw traffic growth.

**Mission alignment note**  
Extremely high, but experimentation risk is also high. This work should be careful, clinician-informed, and measured more by user safety than by volume.

### 9. [Journaling your thoughts and feelings](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/journaling-your-thoughts-and-feelings/)

**Current picture**  
`128.3k` impressions, `998` clicks, `0.78%` CTR, average position `5.8`. The dominant query is `journaling`, and Australian pytrends direction improved across the second half of the year. Lifeline ranks `#2` in the live SERP.

**Likely issue / opportunity**  
The page is good, but broad journaling SERPs are crowded by highly practical "prompts and templates" content. Lifeline can better signal immediate usefulness while retaining its mental-health framing.

**Recommended changes**
- Add a larger "prompts to start today" section close to the top.
- Break prompts by emotional state: anxious, flat, overwhelmed, grieving, stuck.
- Add printable or copyable prompt sets.
- Link more strongly to related articles where journaling is one step in a larger coping plan.

**How to measure success**
- Primary: CTR movement on `journaling` and `journaling for mental health`.
- Secondary: broader query coverage for prompt-oriented terms.
- Experience: deeper onward navigation into related support-toolkit content.

**Mission alignment note**  
Moderate. Helpful and low-risk, but less central to Lifeline's core service mission than the pages above.

### 10. [Acceptance and commitment therapy (ACT)](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/acceptance-and-commitment-therapy-act/)

**Current picture**  
`206.4k` impressions, `2.2k` clicks, `1.04%` CTR, average position `7.2`. Lifeline ranks `#1` in the live AU SERP for the head term `acceptance and commitment therapy`, and the topic is still sizable even though pytrends softened somewhat in the second half of the year.

**Likely issue / opportunity**  
This page has authority and visibility already, so the upside is more incremental than transformative. The best SXO gains would come from making the article easier to apply and easier to compare with adjacent therapies.

**Recommended changes**
- Clarify who ACT is most useful for and when another therapy might be a better fit.
- Add a short "ACT vs CBT" comparison.
- Pull the strategy examples further up the page so users get practical value faster.
- Add stronger onward links to [Finding the right therapist](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-the-right-therapist/) and [What is a Mental Health Treatment Plan?](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/what-is-a-mental-health-treatment-plan/).

**How to measure success**
- Primary: improve CTR on the core ACT head terms.
- Secondary: increase long-tail visibility for "what is ACT" and adjacent explanatory queries.
- Experience: more onward movement into therapy-navigation content.

**Mission alignment note**  
Moderate. It is valuable, but the opportunity cost is higher because Lifeline is already performing reasonably well here.

## Recommendations and sequencing

### Start now

- [Self-care for mental health and wellbeing](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/self-care-for-mental-health-and-wellbeing/)
- [Finding the right therapist](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-the-right-therapist/)
- [Finding relief through grounding techniques](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-relief-through-grounding-techniques/)
- [Managing intrusive thoughts](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/managing-intrusive-thoughts/)

These four combine strong search upside with strong mission fit and relatively low implementation risk. They should be the first editorial sprint.

### Next wave

- [Understanding and managing anger](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/understanding-and-managing-anger/)
- [Eye Movement Desensitization and Reprocessing (EMDR)](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/eye-movement-desensitization-and-reprocessing-edmr/)
- [What is a Mental Health Treatment Plan?](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/what-is-a-mental-health-treatment-plan/)

These are still good bets, but each has a caveat: broad mixed intent, naming/accuracy cleanup, or the need to explicitly support official service sources.

### Protect-and-improve work

- [Self-harm](https://www.lifeline.org.au/get-help/support-toolkit/topics/self-harm/)
- [Journaling your thoughts and feelings](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/journaling-your-thoughts-and-feelings/)
- [Acceptance and commitment therapy (ACT)](https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/acceptance-and-commitment-therapy-act/)

These pages should not be ignored, but the goal is different. For self-harm, optimize for safety and pathway clarity. For journaling and ACT, prioritize practical UX refreshes over large rewrites.

## Final take

The strongest SXO opportunities for Lifeline are not simply the biggest pages. They are the pages where:

- search demand is already proving real
- users are looking for immediate, practical help
- Lifeline can meet that need credibly
- the content can be improved without crowding out a better-fit provider

That points most clearly toward the self-help guide layer of the support toolkit. If Lifeline improves that layer well, the likely outcome is not just more clicks. It is a better first experience for people who are trying to understand what they are feeling and what to do next.

## Suggested SEO OKRs

These OKRs are designed to balance search growth with mission-safe user outcomes.

### Short-term OKRs (next 90 days)

**Objective 1: Improve SERP-to-page conversion on the first editorial sprint pages.**

- KR1: Increase average CTR by **at least 30%** across the four "Start now" pages (self-care, therapist selection, grounding, intrusive thoughts), measured against the 90-day baseline in this report.
- KR2: Increase total organic clicks by **at least 20%** across those same four pages.
- KR3: Lift query-level CTR on each page's primary head query by **at least 20%** (for example, `self care ideas`, `how to choose a therapist`, `grounding techniques`, `intrusive thoughts`).

**Objective 2: Ship practical UX and content upgrades quickly and consistently.**

- KR1: Publish the priority content updates on **4/4 first-sprint pages** (title/meta refresh, above-the-fold practical block, clearer next-step links, support escalation cue where relevant).
- KR2: Add or improve internal pathways so each first-sprint page links to at least **3 relevant next-step resources**.
- KR3: Reduce page-level bounce tendency by increasing engaged sessions per page by **at least 10%** from organic landings.

**Objective 3: Protect mission alignment while optimizing.**

- KR1: Complete safety/clinical-informed review sign-off for **100%** of updated high-sensitivity pages before publishing.
- KR2: Maintain or improve supportive-query performance on the self-harm page while avoiding optimization that targets harmful intent variants.
- KR3: Ensure high-intent service-navigation pages include prominent links to official providers where appropriate (for example, treatment plan content linking to Healthdirect/Services Australia).

### Long-term OKRs (6-12 months)

**Objective 1: Build Lifeline into a trusted first-stop for practical self-led support searches.**

- KR1: Increase total organic clicks to the scoped self-led support cohort by **at least 35%** year over year.
- KR2: Improve cohort CTR from **0.62%** to **at least 0.85%**.
- KR3: Grow the number of support-toolkit pages earning top-5 average positions for target non-brand queries by **at least 40%**.

**Objective 2: Increase the number of users who take a useful next step after landing.**

- KR1: Increase internal click-through to "next-step support" pages (for example, grounding, therapist guidance, treatment navigation) by **at least 25%** from organic entrances.
- KR2: Improve organic engaged session rate across the top 10 priority pages by **at least 15%**.
- KR3: Define and track a "support pathway completion" event set, and achieve **at least 20%** growth in completions from organic traffic.

**Objective 3: Operationalize a repeatable SXO program.**

- KR1: Run **quarterly** opportunity re-ranking using the same weighted rubric (SEO upside, mission fit, practicality, measurement quality).
- KR2: Deliver at least **2 optimization sprints per quarter**, with pre/post measurement readouts published internally.
- KR3: Keep metadata/content hygiene debt low by resolving high-impact issues (for example, acronym/title errors) within **one sprint** of detection.
