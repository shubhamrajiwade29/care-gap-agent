# CLAUDE.md — Care Gap Agent

## ▶ START HERE
This is a ready-to-build SFDX starter. Finish and verify it against a real org.

1. Read this file + `README.md`.
2. Create/authorize an org:
   - Scratch: `sf org create scratch -f config/project-scratch-def.json -a caregap -d -y 7`
   - or Dev Edition: `sf org login web -a caregap`
3. Deploy: `sf project deploy start -o caregap`
4. Run tests: `sf apex run test -o caregap -l RunLocalTests -c -w 10` — fix anything failing; target >90% coverage.
5. Add the `patientCareSummary` LWC to the Contact record page (App Builder) and create sample `Care_Gap__c` rows.
6. (If org supports it) wire the **Get Patient Care Gaps** invocable into an Agentforce topic/action; otherwise expose it via a screen Flow.
7. Commit + push to a new GitHub repo `care-gap-agent`.


## 🔌 Org setup (this project's target org)
Target org: **Agentforce-enabled Developer Edition** — alias `caregap`
Domain: `<your-org>.develop.my.salesforce.com` (Agentforce, Einstein, Data Cloud, Default model provider all confirmed ON).

```bash
# 1. Authorize the org (opens browser; log into your Developer Edition org)
sf org login web -a caregap

# 2. Deploy the project
sf project deploy start -o caregap

# 3. Run tests (expect all passing, >90% coverage)
sf apex run test -o caregap -l RunLocalTests -c -w 10

# 4. Open the org
sf org open -o caregap
```
Then in the org: add the **Patient Care Summary** LWC to the Contact record page (App Builder),
create a few `Care_Gap__c` records, and wire the **Get Patient Care Gaps** invocable into an
Agentforce topic/action (Agentforce is already enabled on this org — no extra enablement needed).

## What's already scaffolded
- `Care_Gap__c` object + fields (Patient lookup, Gap Type, Status, Priority, Due/Closed dates).
- Apex: `CareGapSelector`, `CareGapService` (+ `@AuraEnabled getOpenGaps`), `GetPatientCareGaps` (invocable), `CareGapReminderScheduler` (Schedulable), `TestDataFactory`.
- Tests: `CareGapServiceTest`, `GetPatientCareGapsTest` (incl. 200-record bulk), `CareGapReminderSchedulerTest`.
- LWC `patientCareSummary` (record page, Contact).

## Things to finish / extend (good next steps)
- Add a **Flow** (record-triggered or scheduled) as a declarative alternative to the scheduler, to showcase config skill.
- Add a "Mark Scheduled / Close" quick action on the LWC (calls an `@AuraEnabled` method; enforce CRUD/FLS).
- Add a report + dashboard: open gaps by type / by priority.
- Health Cloud variant: map `Patient__c` to the HC patient object.
- Seed data: a `scripts/data/` plan.json with sample patients + gaps for demos.

## Guardrails
- Keep Apex bulk-safe and `WITH SECURITY_ENFORCED`; no SOQL/DML in loops.
- Every new class needs a test; keep org-wide coverage >90%.
- Don't claim Agentforce in the README demo video unless the agent is actually wired — otherwise show the Flow path.
