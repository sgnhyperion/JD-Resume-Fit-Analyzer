# Sample Inputs & Output

Keep the **same job description** (`sample_jd.pdf`) and just swap the **resume** PDF to
demonstrate each branch of the workflow.

| Resume to upload | Triggers | Why |
|---|---|---|
| `sample_resume.pdf` | **Strong Fit** (score ≥ 75) | Backend engineer matching the JD: Python, SQL, REST APIs, Git, Docker |
| `resume_maybe.pdf` | **Maybe Fit** (50–74) | Junior dev — has Python + some SQL, but no REST API design, Git, or Docker → flagged for human review |
| `resume_weak.pdf` | **Weak Fit** (< 50) | Graphic designer — unrelated skills, no overlap with the JD |
| `resume_fallback.pdf` | **Fallback: Invalid Input** | Almost no extractable text (< 30 chars) → caught before any AI call |

**Job description for all cases:** `sample_jd.pdf` (Backend Engineer – Python).

## How to run a case
1. Click **Execute Workflow** in n8n.
2. **Job Description:** upload `sample_jd.pdf`.
3. **Resume:** upload one of the resume PDFs from the table above.
4. Submit → watch it route to the matching branch.

> Scores are produced by the AI, so exact numbers vary slightly per run — but the
> resumes are designed to land clearly in each band. The **Fallback** case is fully
> deterministic (it depends only on text length, not the AI).

## Output
`sample_output.json` — a real captured result from the **Strong Fit** run
(fit score, matched/missing skills, summary, and the drafted interview email).
