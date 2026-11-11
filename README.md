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
- **Record-page LWC** (`patientCareSummary`) — shows a patient's open gaps with priority badges.
- **Agentforce action** (`GetPatientCareGaps`) — invocable Apex returning a natural-language summary + count, so an Agentforce agent can answer questions about a patient.
- **Agentforce action** (`FindPatientByName`) — invocable Apex that resolves a spoken name ("Maria Alvarez") to a Contact Id, or lists candidates when ambiguous, so the agent can chain it into `GetPatientCareGaps`.
- **Scheduled job** (`CareGapReminderScheduler`) — each morning, flags overdue open gaps as High priority and creates follow-up Tasks.
- **Apex architecture** — Selector / Service layers, `WITH SECURITY_ENFORCED`, bulk-safe, with test classes (incl. 200-record bulk tests).

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

## Agentforce (needs an Agentforce-enabled org)
1. Setup → Agentforce → enable.
2. New agent topic "Patient Care Gaps"; add two actions: **Find Patient By Name** (name → `patientId`) and
   **Get Patient Care Gaps** (takes `patientId`, returns `summary`).
3. Instructions: resolve the patient first; if several match, ask which one; never invent gaps; report the action's `summary`.
4. Give the agent's running user the **Care Gap Manager** permission set.
> If your org isn't Agentforce-enabled, everything else still runs — the invocable action
> also works as a **Flow** action, so you can demo it from a screen Flow in the meantime.

## Note on Health Cloud
Modeled on standard objects (Contact as patient + `Care_Gap__c`) so it deploys to **any**
Dev org. In a Health Cloud org, point `Patient__c` at the Health Cloud patient record and
the same logic applies.

## Tech
Apex (Selector/Service, Schedulable, Invocable) · LWC · SOQL · Agentforce · SFDX
