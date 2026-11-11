# Care Gap Agent — Case Study

**Role:** Solo build (design, development, testing, deployment)
**Type:** Personal project · Salesforce + Agentforce
**Stack:** Apex · LWC · Agentforce · SOQL · SFDX
**Repo:** https://github.com/shubhamrajiwade29/care-gap-agent

---

## Overview

Care Gap Agent is a Salesforce application that helps healthcare care teams catch
patients who are overdue for screenings and labs — and lets them ask an **Agentforce AI
assistant** about a patient in plain English instead of digging through records. It's
built on standard Salesforce objects with a clean, enterprise-style Apex architecture,
and ships with a working, tested Agentforce agent.

I built it end to end to demonstrate three things in one coherent app: **Agentforce**
capability, **healthcare-domain** fluency, and **Apex/LWC developer** skill.

---

## The problem

In care coordination, patients fall through the cracks when screenings go untracked —
an overdue A1C test, a missed mammogram, a colonoscopy that was never followed up.
Coordinators spend time manually checking records to answer a simple question: *which
of my patients are overdue, and for what?* The information exists but isn't surfaced,
so gaps get missed and follow-ups slip.

## The goal

- Make a patient's open care gaps **visible at a glance** on their record.
- Let a coordinator **ask** about any patient conversationally and get an accurate,
  grounded answer — no hallucinated gaps.
- **Automate** the follow-up so overdue gaps escalate themselves.
- Keep it on a **clean, secure, bulk-safe** codebase that would pass enterprise review.

---

## What I built

### Data model
A custom `Care_Gap__c` object (type, status, priority, due date, closed date) linked to
the patient via a lookup to the standard **Contact** object. Built on standard objects
deliberately, so it deploys to any Developer org — it maps directly onto Health Cloud's
patient record if deployed there, but requires no Health Cloud license.

### Apex architecture (Selector / Service pattern)
- **`CareGapSelector`** — all SOQL, centralized, with `WITH SECURITY_ENFORCED`.
- **`CareGapService`** — business logic: fetch open gaps, update status (with CRUD/FLS
  checks; closed gaps can't be reopened), and generate a plain-English summary.
- Everything **bulk-safe** — no SOQL/DML in loops, verified by 200-record bulk tests.

### Record-page UI (LWC)
A `patientCareSummary` Lightning Web Component on the Contact page shows the patient's
open gaps with color-coded priority badges and an inline menu to **Mark scheduled** or
**Close** a gap.

### A dedicated app
A custom **Care Management** Lightning app (Home, Contacts, Care Gaps, Reports,
Dashboards) with a Care Gaps tab and list views — **All Open Gaps**, **Overdue**,
**High Priority** — plus reports (Open Gaps by Type / by Priority) and a Care Gap
Overview dashboard. So it presents as a purpose-built product, not a bolt-on.

### Agentforce agent — "Care Gap Assistant"
The centerpiece. An Agentforce agent with a **Patient Care Gaps** topic backed by two
invocable Apex actions that chain together:
- **`FindPatientByName`** — resolves a spoken name ("Maria Alvarez") to a Contact Id,
  or lists candidates when the name is ambiguous.
- **`GetPatientCareGaps`** — takes the Id and returns a natural-language summary + count,
  flagging overdue gaps explicitly.

The topic is instructed to identify the patient first, ask which one if several match,
never invent gaps, and only say "overdue" when the tool marks a gap overdue.

> **Example:** *"What care gaps does Maria Alvarez have?"* →
> *"Maria Alvarez has two open care gaps: an A1C Test (high priority, overdue since
> 10/15/2026) and a Mammogram (medium priority, upcoming, due 12/1/2026)."*

### Automated follow-up
A scheduled Apex job (`CareGapReminderScheduler`) runs each morning, flags overdue open
gaps as High priority, and creates follow-up Tasks on the patient. (A declarative Flow
version of the same rule is included as a draft alternative.)

---

## Technical highlights

- **Enterprise Apex patterns** — Selector/Service separation, `WITH SECURITY_ENFORCED`
  on every query, a dedicated `Care_Gap_Manager` permission set for object/field/class
  access rather than relying on admin defaults.
- **A real bulk bug, caught by tests.** The first version of the Agentforce action ran
  one SOQL query per request — fine for one patient, but it blew the 101-query governor
  limit under a 200-record bulk test. I refactored the selector to resolve all patients
  in a single query. This is exactly the kind of issue that only surfaces with proper
  bulk testing.
- **Chained AI actions** — the agent composes two Apex tools (name → Id → gaps), with
  ambiguity handling when multiple patients share a name.
- **Grounded, not hallucinated** — the agent only reports gaps the Apex tool returns,
  and only labels "overdue" when the data says so. Verified against unknown patients
  (returns nothing invented) and upcoming-but-not-overdue gaps (no false "overdue").

---

## Results

- **97% org-wide Apex test coverage** across 23 passing tests, including 200-record bulk tests.
- **Working, verified Agentforce agent.** Tested in Agentforce Builder's Live Test:
  full-name / last-name / first-name lookups, the name→gaps chain, ambiguous-name
  handling (lists both and asks), unknown-patient (no invented data), and off-topic
  redirect.
- **Deployable from scratch** — documented setup (deploy → assign permission set →
  run tests → seed data), with seed data generated relative to today so the
  overdue/upcoming demo stays accurate over time.

---

## Challenges & what I learned

- **Security-first queries have a cost.** `WITH SECURITY_ENFORCED` meant nothing worked
  until a proper permission set granted field access — even for the admin. The right fix
  was a dedicated permission set assigned to every user (and the agent's running user),
  not loosening the queries.
- **Bulk-safety isn't optional.** The per-request SOQL bug was invisible in single-record
  testing and only the bulk test exposed it — a good reminder of why governor-limit
  discipline and bulk tests matter.
- **Grounding an AI agent is a design problem, not just a prompt.** Getting the agent to
  never invent gaps and to handle ambiguous names took deliberate topic instructions plus
  tool outputs shaped for the model to reason over.

---

## Honest scope notes

- Built on **standard Salesforce objects**, not Health Cloud (portable to it, doesn't
  require it).
- The **Agentforce agent is live and tested**; the alternative **Flow** implementation is
  deployed as a draft and validated by deploy only (scheduled flows fire at their start
  time), so it isn't presented as run-tested.

---

## Tech stack

Apex (Selector/Service, Schedulable, Invocable actions) · Lightning Web Components ·
SOQL · Agentforce (Agent Script, topics, actions) · Salesforce DX · GitHub
