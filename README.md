# Care Gap Agent — Salesforce

An AI-assisted **Health Cloud–style care-gap tracker** for care teams. It flags a
patient's overdue screenings and labs, surfaces them on the record page, and lets
an **Agentforce** assistant answer *"what's open for this patient?"* in plain English —
backed by a clean, bulk-safe **Apex** service layer.

Built by Shubham Rajiwade to demonstrate Agentforce + Health Cloud domain + Apex/LWC
developer skill in one coherent app.

## The problem
Care coordinators waste time hunting across records to see which patients are overdue
for screenings (A1C, mammogram, colonoscopy, etc.). Gaps get missed; follow-ups slip.

## What it does
- **Care Gap data model** (`Care_Gap__c`) — type, status, priority, due date, linked to the patient (Contact).
- **Record-page LWC** (`patientCareSummary`) — shows a patient's open gaps with priority badges, and a per-row menu to **Mark scheduled** or **Close** a gap (`CareGapService.updateGapStatus`, with object/field update checks; closed gaps can't be reopened).
- **Care Management app** — dedicated Lightning app (Home, Contacts, Care Gaps, Reports, Dashboards) with a **Care Gaps** tab and list views *All Open Gaps*, *Overdue*, *High Priority*.
- **Reports + dashboard** — *Open Gaps by Type*, *Open Gaps by Priority* and a *Care Gap Overview* dashboard.
- **Agentforce action** (`GetPatientCareGaps`) — invocable Apex returning a natural-language summary + count, so an Agentforce agent can answer questions about a patient.
- **Agentforce action** (`FindPatientByName`) — invocable Apex that resolves a spoken name ("Maria Alvarez") to a Contact Id, or lists candidates when ambiguous, so the agent can chain it into `GetPatientCareGaps`.
- **Scheduled job** (`CareGapReminderScheduler`) — each morning, flags overdue open gaps as High priority and creates follow-up Tasks.
- **Apex architecture** — Selector / Service layers, `WITH SECURITY_ENFORCED`, bulk-safe, with test classes (incl. 200-record bulk tests).

## Overdue follow-up: Apex scheduler **or** Flow
Two interchangeable implementations of the same rule (Status = Open and due on/before today → High priority +
follow-up Task on the patient). **Run one, not both**, or each overdue gap gets duplicate Tasks.
- **Apex:** `System.schedule('Care Gap Reminders','0 0 7 * * ?', new CareGapReminderScheduler());` — tested.
- **Flow:** `Overdue Care Gap Follow-up` (scheduled-triggered, daily 07:00 UTC). Deployed as **Draft**; open it in
  Flow Builder, debug it against a seeded overdue gap, then activate. *Not run-tested here: scheduled flows only
  fire at their start time, so it was validated by deploy only.*

## Architecture
```
LWC (patientCareSummary) ─┐
Agentforce action ────────┼─► CareGapService ─► CareGapSelector ─► Care_Gap__c
Scheduled job ────────────┘
```

## Setup (any Salesforce Developer org)
```bash
sf org login web -a caregap
sf project deploy start -o caregap
sf org assign permset -n Care_Gap_Manager -o caregap      # required: grants object/field/class access
sf apex run test -o caregap -l RunLocalTests -w 10
sf apex run -o caregap -f scripts/data/seed.apex          # demo patients + gaps (dates relative to today; re-runnable)
```
> **Don't skip the permission set.** Queries use `WITH SECURITY_ENFORCED`, so any user (including
> admins) without **Care Gap Manager** gets "secure query included inaccessible field" errors.
> Assign it to every user, and to the Agentforce agent's running user.

Then add the **Patient Care Summary** LWC to the Contact record page (Lightning App Builder) if your
org's page doesn't already include it, and open a seeded patient such as *Maria Alvarez*.

## Agentforce agent: "Care Gap Assistant"
Built in Agentforce Builder (Agent Script) on an Agentforce-enabled Developer Edition org and tested in the
Builder's Live Test on the activated version. The agent definition is version-controlled in
`force-app/main/default/aiAuthoringBundles/Care_Gap_Assistant/` (retrieved from the org; requires `sourceApiVersion` 65.0+).

**Topic: Patient Care Gaps**, with two Apex actions that are deployed by this repo:
1. **Find Patient By Name** (`FindPatientByName`): `patientName` → `patientId`, `matchCount`, `message`.
2. **Get Patient Care Gaps** (`GetPatientCareGaps`): `patientId` → `summary`, `openGapCount`. The summary flags
   overdue gaps explicitly ("OVERDUE by 26 days") using the same rule as the reminder job.

Topic instructions (summary): identify the patient first; if several match, ask which one; never invent gaps;
reply in one or two natural sentences with each gap's type, priority and due date; say "overdue" only when the
tool marks a gap OVERDUE.

Example (seeded data): *"What care gaps does Maria Alvarez have?"* → *"Maria Alvarez has two open care gaps: an A1C
Test (high priority, overdue since 10/15/2026) and a Mammogram (medium priority, upcoming, due 12/1/2026)."*

**Verified in Live Test:** name → gaps chain (full name, last name only, first name only), no false "overdue" for
an upcoming gap, unknown patient (no invented gaps), off-topic redirect, and ambiguity: with two patients named Maria
the agent lists both and asks which one instead of guessing.

Setup notes
- The agent's running user needs the **Care Gap Manager** permission set (queries use `WITH SECURITY_ENFORCED`).
- Set the action outputs (`message`, `summary`, `openGapCount`) to `is_displayable: False`; otherwise the platform
  prints the raw tool output under the agent's reply.

**Deploying the agent to another org:** `sf project deploy start` includes the bundle. Afterwards open it in
Agentforce Builder, check the actions resolve, then activate it. The agent's running user needs **Care Gap Manager**.
> No Agentforce org? Everything else still runs; the invocable actions also work from a screen Flow.

## Note on Health Cloud
Modeled on standard objects (Contact as patient + `Care_Gap__c`) so it deploys to **any**
Dev org. In a Health Cloud org, point `Patient__c` at the Health Cloud patient record and
the same logic applies.

## Tech
Apex (Selector/Service, Schedulable, Invocable) · LWC · SOQL · Agentforce · SFDX
