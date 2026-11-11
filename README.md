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
sf apex run test -o caregap -l RunLocalTests -w 10
```
Then: add the **Patient Care Summary** LWC to the Contact record page (Lightning App Builder),
create a few `Care_Gap__c` records, and you're live.

## Agentforce (needs an Agentforce-enabled org)
1. Setup → Agentforce → enable.
2. New agent topic "Patient Care Gaps"; add an action pointing to the **Get Patient Care Gaps** invocable.
3. Grounding prompt: pass the patient's Id; return the action's `summary`.
> If your org isn't Agentforce-enabled, everything else still runs — the invocable action
> also works as a **Flow** action, so you can demo it from a screen Flow in the meantime.

## Note on Health Cloud
Modeled on standard objects (Contact as patient + `Care_Gap__c`) so it deploys to **any**
Dev org. In a Health Cloud org, point `Patient__c` at the Health Cloud patient record and
the same logic applies.

## Tech
Apex (Selector/Service, Schedulable, Invocable) · LWC · SOQL · Agentforce · SFDX
