## Self-led support SXO: next steps


## 1. Focus pages for the first SXO sprint

Per `docs/REPORT1.md` and the meeting discussion, we agreed to **treat the top‑ranked pages differently**:

- Pages **1–3** below are **validated "yes" opportunities** for immediate optimisation work.
- Pages **4–5** are **strong candidates** but need more research and clinical thinking before we commit to specific changes.

### 1–3: ready for optimisation

1. **Self-care for mental health and wellbeing**  
   - URL: `https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/self-care-for-mental-health-and-wellbeing/`  
   - Status: **go** for first sprint.  
   - Primary opportunity: match "self care ideas" intent by surfacing practical ideas much earlier and tightening title/meta.

2. **Finding the right therapist**  
   - URL: `https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-the-right-therapist/`  
   - Status: **go** for first sprint.  
   - Primary opportunity: turn the intro into a clear, practical selection guide/checklist for "how to choose a therapist".

3. **Finding relief through grounding techniques**  
   - URL: `https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/finding-relief-through-grounding-techniques/`  
   - Status: **go** for first sprint.  
   - Primary opportunity: get users to relief faster with "try this now" blocks and a clearer pathway to immediate support.

### 4–5: research and validation first

4. **Managing intrusive thoughts**  
   - URL: `https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/managing-intrusive-thoughts/`  
   - Status: **needs further research + clinical framing**.  
   - Next step: review queries, current copy, and clinical risks; decide whether/where reassurance summaries, "what might help right now" content, and support ladders are appropriate.

5. **Understanding and managing anger**  
   - URL: `https://www.lifeline.org.au/get-help/support-toolkit/techniques-and-guides/understanding-and-managing-anger/`  
   - Status: **needs further research + intent analysis** (especially around DFV‑adjacent queries and "for someone else" searches).  
   - Next step: look more closely at query mix and risk profile before proposing concrete optimisation work.

Pages 1–3 align with the **"Start now"** list in `REPORT1.md`. Pages 4–5 stay on the radar but move into a dedicated discovery track instead of the first optimisation sprint.

---

## 2. Experiment proposal document

Create a short, shareable proposal that frames the first SXO sprint as a **time‑boxed experiment** rather than an ongoing obligation.

- **Owner**: Aidan (initial draft), Hannah (structure, polish).
- **Format**: Notion page, with a static export/check‑in path noted in the repo as `docs/REPORT1_experiment_outline.md` (to be created once the Notion draft stabilises).

The proposal should:

- **Summarise context**
  - Link to `docs/REPORT1.md` and call out the four "Start now" pages.
  - Include one or two key charts or metrics from the report (CTR + impressions) as screenshots from `docs/assets/report1/*`.
- **Describe the experiment**
  - Scope: the four focus pages and the types of changes allowed (title/meta, ordering, jump menus, onward links, support cues, UX layout).
  - Guardrails: clinical/knowledge sign‑off for any changes that affect advice, safety language, or risk framing.
  - Timebox: e.g. 1 content sprint to ship, 90 days of measurement.
- **Define success measures (simple version of OKRs)**
  - Primary: CTR uplift on each page’s main head term (see `REPORT1.md` OKRs).
  - Secondary: total organic clicks across the four pages; engaged sessions and onward clicks to key support pages.
- **Clarify edit workflow**
  - Where drafts live (Notion), who reviews them (Hannah → clinical → Aidan/Ben), and how they move into the CMS.

---

## 3. Stakeholder path and approvals

From the meeting, the preferred order is:

1. **Clinical / Knowledge and Quality**  
   - People: **Mel**, **Amy**.  
   - Goal: confirm that the proposed experiment and specific page changes are clinically safe and a good use of self‑led support content.
   - Framing: "short, test‑and‑learn experiment on four pages with clear measurement, not an ongoing extra workload".

2. **Digital / Content leadership**  
   - People: **Ben**, **Varun**.  
   - Goal: agree that the work is practical, sized appropriately, and aligned with broader digital priorities.
   - Framing: "low‑risk content/UX refresh on pages where we already have visibility but weak CTR".

3. **Cross‑functional awareness (later)**  
   - People: e.g. Rosie, Corinne, others in digital/marketing.  
   - Goal: share results and explore future SXO sprints once the first experiment has shipped and been measured.

Suggested next steps:

- Aidan drafts the Notion experiment proposal (see §2) and shares it with Hannah.
- Hannah reviews, restructures, and adds any copy/positioning tweaks for clinical and leadership audiences.
- Once both are happy, send to **Mel** and **Amy** for feedback and sign‑off, then to **Ben** and **Varun** with a clear ask and timeline.

---

## 4. Content and UX changes (first sprint)

Once approvals are in place, the **first sprint** should aim to **ship pragmatic changes** on the three validated pages rather than deep rewrites:

- **Self-care page**
  - Stronger, more practical title/meta for "self care ideas".
  - High‑up "ideas" block with a scannable list and optional segments like "quick wins in 5 minutes", "when you feel flat".
  - Improved onward paths to related pages (grounding, journaling, digital detox, therapy navigation).

- **Therapist selection page**
  - Front‑loaded "how to choose a therapist" decision section (criteria list rather than long scene‑setting).
  - Clearer Australia‑specific guidance (directories, Medicare/cost cues, what to ask before and after booking).
  - Better internal links to `What is a Mental Health Treatment Plan?` and related content.

- **Grounding techniques page**
  - One or two grounding exercises above the fold with a "try this now" box.
  - A simple, calm route to immediate support for readers whose distress does not ease with self‑help.

Discovery work for **intrusive thoughts** and **anger** should run in parallel but be treated as a **separate validation stream**, not part of the initial optimisation delivery.

Implementation detail (for Aidan / analytics):

- Before shipping, capture baselines from `searchconsole.seo_page_daily` and `searchconsole.curated_search_query_page_daily` for:
  - Page‑level impressions, clicks, CTR and average position.
  - Query‑level metrics on key head terms (`self care ideas`, `how to choose a therapist`, `grounding techniques`, `intrusive thoughts`).
- After ~90 days, re‑run the same queries and add a short comparison section back into `docs/REPORT1.md` or a new follow‑up note (e.g. `docs/REPORT1_results_sprint1.md`).

---

## 5. Low‑risk hygiene and future waves

While the first sprint is running (or in a separate mini‑sprint), consider:

- **Low‑risk hygiene fixes with standing pre‑clearance**
  - Example: fixing the `EDMR` → `EMDR` typo on the EMDR page title/H1 and other non‑clinical copy errors that affect credibility.
  - Simple metadata/jump‑menu improvements where they do not change advice or risk language.

- **Next‑wave candidates (from `REPORT1.md`)**
  - `Understanding and managing anger`
  - `Eye Movement Desensitization and Reprocessing (EMDR)`
  - `What is a Mental Health Treatment Plan?`

These should be revisited once the first sprint has results and the experiment process has been tested with stakeholders.

---

## 6. Who does what (short version)

- **Aidan**
  - Draft Notion experiment proposal and keep `docs/REPORT1_next_steps.md` in sync as the in‑repo source of truth.
  - Pull and track the relevant GSC metrics via BigQuery.
  - Coordinate with Ben/Varun and ensure worklines up with broader digital priorities.

- **Hannah**
  - Co‑author and restructure the proposal in Notion.
  - Lead on page‑level copy and UX changes for the four focus pages, in collaboration with clinical reviewers.

- **Clinical / Knowledge and Quality (Mel, Amy)**
  - Review and sign off on any changes that affect advice, safety language, or risk framing.
  - Help decide whether "what to do right now"–style sections are appropriate on high‑sensitivity topics such as intrusive thoughts.

This file can be updated as the experiment design firms up and as new SXO sprints are agreed.

