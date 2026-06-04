# JD–Resume Fit Analyzer — Agentic n8n Workflow

An n8n workflow that takes a **job description** and a **candidate resume**, uses AI to
analyze the match, applies **deterministic rules** to decide a recommendation, and
**routes** the candidate into one of three actions (interview, human review, or rejection).

> Built for the *Agentic Workflow Design and n8n Demo* assignment.

> Verified end-to-end on n8n v2.23.3 with a live Google Gemini 2.5 Flash run (all four
> branches route correctly).

---

## 1. Problem Statement

**Who is the user?** Recruiters and hiring teams (and overloaded startup founders) who
receive far more applications than they can read carefully.

**The pain point.** Manually reading every resume against a job description is slow,
inconsistent, and biased by fatigue. Two recruiters often score the same resume
differently, and good candidates get missed while weak ones get interviews.

**Why it matters.** Faster, more consistent screening saves hours per role and improves
the quality of the shortlist — directly affecting hiring speed and cost.

**What the workflow produces.** For each application, a **structured decision**:
- a fit score (0–100),
- matched vs. missing skills,
- a short summary with strengths and concerns,
- a category (**Strong / Maybe / Weak Fit**), and
- a ready-to-send draft email **or** a flag for human review.

---

## 2. Problem → Workflow Breakdown

| Stage | What happens | Type |
|---|---|---|
| **Input** | Recruiter uploads a JD **PDF** + a Resume **PDF** (+ optional email) via an n8n Form | Tool / integration |
| **Parse** | Extract the text out of each PDF (document parser) | Deterministic tool |
| **Validate** | Check both extracted texts contain real content (≥ 30 chars) | Deterministic |
| **Branch: valid?** | If invalid → stop with a clear error | Deterministic (fallback) |
| **Analyze** | AI extracts skills, scores fit, summarizes | **AI reasoning** |
| **Structure** | Force the AI answer into a fixed JSON schema | Structured output |
| **Decide** | Convert score → category using fixed thresholds | Deterministic |
| **Route** | Send to one of 3 branches based on category | Deterministic routing |
| **Output** | Draft interview invite / human-review note / rejection draft | Tool output |

---

## 3. The n8n Workflow (node by node)

```
Form Trigger (PDF uploads) → Extract JD Text → Extract Resume Text → Validate Input (Code)
                                                                            │
                                          ┌─────────────────────────────────┘
                                          ▼
                                       IF (valid?) ─true─→ AI: Analyze Fit (Gemini + Output Parser)
                                          │                          │
                                          └false→ Fallback           ▼
                                                            Compute Decision (Code, thresholds)
                                                                       │
                                                                 Switch (route)
                                                       ┌───────────────┼────────────────┐
                                                  Strong Fit       Maybe Fit         Weak Fit
                                               (interview draft) (human review)   (rejection draft)
```

1. **Form: Submit JD + Resume** — `Form Trigger`. The input/integration. Gives a shareable
   web form with two **PDF upload** fields (Job Description, Resume) + an optional email.
2. **Extract JD Text** & **Extract Resume Text** — `Extract from File` (deterministic
   **document parser**). Pull the plain text out of each uploaded PDF so the AI can read it.
3. **Validate Input** — `Code` (deterministic). Reads the extracted text and sets
   `isValid = true` only if both JD and Resume have real content. This is our **fallback guard**.
4. **Input Valid?** — `IF` (deterministic branch). Valid → continue to AI. Invalid →
   **Fallback: Invalid Input** node returns a clear error (no wasted AI call).
5. **AI: Analyze Fit** — `Basic LLM Chain` (the **AI reasoning** step). Acts as a
   *recruiter agent*: extracts required skills, matches them against the resume, estimates
   experience, and assigns a 0–100 fit score with a summary.
   - **Google Gemini Chat Model** — the LLM powering the analysis.
   - **Structured Output Parser** — forces the answer into a fixed JSON schema so the rest
     of the workflow can rely on it (structured output, not free text).
6. **Compute Decision (Thresholds)** — `Code` (deterministic). The **AI does not decide the
   outcome** — this node does, using fixed rules:
   - `score ≥ 75` → **Strong Fit**
   - `50 ≤ score < 75` → **Maybe Fit**
   - `score < 50` → **Weak Fit**
7. **Route by Category** — `Switch` (deterministic routing). Sends the item down exactly
   one of three paths.
8. **Output branches** (`Set` nodes):
   - **Strong Fit → Interview Draft** — drafts an interview-invitation email.
   - **Maybe Fit → Human Review** — produces a **human-in-the-loop** note for a hiring
     manager (borderline cases are never auto-decided).
   - **Weak Fit → Rejection Draft** — drafts a polite rejection listing the key gaps.

---

## 4. AI vs. Deterministic — and Why

| Step | AI or Deterministic? | Why |
|---|---|---|
| PDF text extraction | Deterministic (tool) | Mechanical parsing — no judgment needed |
| Skill extraction, scoring, summary | **AI** | Needs language understanding & judgment |
| Input validation | Deterministic | Simple, must be 100% reliable |
| Score → category | Deterministic | Thresholds must be consistent & auditable |
| Routing to a branch | Deterministic | Control flow should never be "creative" |
| Email drafting | Templated (Set) | Predictable, on-brand wording |

**Key design decision:** AI is used only for *reasoning* (reading and judging). All
*control* (validation, thresholds, routing) is deterministic, so the system is predictable,
debuggable, and fair. The AI suggests; the rules decide.

---

## 5. Agentic Practices Demonstrated

- **Agent role definition** — the AI node has a single, clear job: "expert recruiter analyst."
- **Structured outputs** — JSON schema via the Output Parser.
- **Tool/integration use** — n8n Form for input + **Extract from File** as a document parser
  that reads the uploaded PDFs.
- **Branching & routing** — IF + Switch direct the flow on workflow state.
- **Deterministic checks** — validation and score thresholds.
- **Human-in-the-loop** — borderline "Maybe Fit" candidates are flagged, not auto-actioned.
- **Fallback handling** — invalid input is caught before any AI call.

---

## 6. How to Run

**Prerequisite:** Node.js 18+ (n8n does not run on older versions). Check with `node -v`.

**Install & start n8n** (free, runs locally — no account needed):
```bash
npm install -g n8n      # one-time install
n8n start               # starts the server
```
Wait for `Editor is now accessible`, then open **http://localhost:5678**.

> On this machine, Node was upgraded with **nvm**, so the bundled **`start_n8n.sh`** is the
> easy launcher — it loads the right Node version and starts n8n in one step:
> ```bash
> bash start_n8n.sh
> ```
> (Alternatives if you prefer not to install: `npx n8n`, or Docker:
> `docker run -it --rm -p 5678:5678 n8nio/n8n`.)

**Then:**

1. Open **http://localhost:5678** in your browser.
2. In the editor: menu **☰ → Import from File** → select **`workflow.json`**.
3. Open the **Google Gemini Chat Model** node → add a credential with a free
   [Google AI Studio](https://aistudio.google.com/apikey) API key (model: `gemini-2.5-flash`).
4. Click **Execute Workflow**, then upload
   [samples/sample_jd.pdf](samples/sample_jd.pdf) + [samples/sample_resume.pdf](samples/sample_resume.pdf)
   into the form and submit.
5. The final node shows the structured decision + drafted email.
   Example output: [samples/sample_output.json](samples/sample_output.json).

---

## 7. Limitations & Future Improvements

- Only text-based PDFs are supported; scanned/image-only PDFs would need an OCR step.
- Scores depend on the AI; adding a second "verifier" AI agent would increase reliability.
- Email drafts are generated but not sent; a Gmail node could send after approval.
- A Google Sheets node could log every decision for analytics and auditing.

---

## 8. Repository Contents

| File | Purpose |
|---|---|
| `workflow.json` | The exported n8n workflow JSON (import this) |
| `README.md` | This document — problem statement + workflow explanation |
| `samples/sample_jd.pdf` | Job-description PDF (used for all cases) |
| `samples/sample_resume.pdf` | Resume → **Strong Fit** |
| `samples/resume_maybe.pdf` | Resume → **Maybe Fit** (human review) |
| `samples/resume_weak.pdf` | Resume → **Weak Fit** (rejection) |
| `samples/resume_fallback.pdf` | Resume → **Fallback** (invalid input) |
| `samples/sample_output.json` | Real output from a live run |
| `samples/README.md` | Which sample triggers which branch |
| `screenshots/` | Workflow + run screenshots |
| `start_n8n.sh` | Optional helper to launch n8n locally |

> **Submission type:** Individual. (No contribution note required — this was not a group project.)
