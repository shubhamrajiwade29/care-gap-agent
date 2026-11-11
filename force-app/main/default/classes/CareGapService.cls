/**
 * Service layer for care-gap business logic. Called by LWC, invocable action,
 * and scheduled jobs. Bulk-safe.
 */
public with sharing class CareGapService {

    @AuraEnabled(cacheable=true)
    public static List<Care_Gap__c> getOpenGaps(Id patientId) {
        if (patientId == null) {
            throw new AuraHandledException('A patient Id is required.');
        }
        return new CareGapSelector().selectOpenByPatient(patientId);
    }

    /**
     * Mark a single gap Scheduled or Closed from the record-page LWC.
     * Enforces object/field update access, validates the transition, stamps Closed_Date__c.
     */
    @AuraEnabled
    public static void updateGapStatus(Id gapId, String newStatus) {
        if (gapId == null || (newStatus != 'Scheduled' && newStatus != 'Closed')) {
            throw new AuraHandledException('A care gap and a status of Scheduled or Closed are required.');
        }
        if (!Schema.sObjectType.Care_Gap__c.isUpdateable()
            || !Schema.sObjectType.Care_Gap__c.fields.Status__c.isUpdateable()
            || !Schema.sObjectType.Care_Gap__c.fields.Closed_Date__c.isUpdateable()) {
            throw new AuraHandledException('You do not have permission to update care gaps.');
        }
        List<Care_Gap__c> found;
        try {
            found = new CareGapSelector().selectById(gapId);
        } catch (System.QueryException e) {
            throw new AuraHandledException('You do not have permission to view care gaps.');
        }
        if (found.isEmpty()) {
            throw new AuraHandledException('Care gap not found.');
        }
        Care_Gap__c gap = found[0];
        if (gap.Status__c == 'Closed') {
            throw new AuraHandledException('This care gap is already closed.');
        }
        gap.Status__c = newStatus;
        gap.Closed_Date__c = newStatus == 'Closed' ? Date.today() : null;
        update gap;
    }

    /** Close a set of gaps (bulk-safe). Caller must have update access. */
    public static void closeGaps(List<Care_Gap__c> gaps) {
        if (gaps == null || gaps.isEmpty()) {
            return;
        }
        for (Care_Gap__c g : gaps) {
            g.Status__c = 'Closed';
            g.Closed_Date__c = Date.today();
        }
        update gaps;
    }

    /** True when a gap still needs booking and its due date has passed (same rule as the reminder job). */
    public static Boolean isOverdue(Care_Gap__c g) {
        return g.Status__c == 'Open' && g.Due_Date__c != null && g.Due_Date__c < Date.today();
    }

    /** Plain-English summary of a patient's open gaps (used by Agentforce). Flags overdue gaps explicitly. */
    public static String summarize(List<Care_Gap__c> gaps) {
        if (gaps == null || gaps.isEmpty()) {
            return 'No open care gaps for this patient.';
        }
        List<String> parts = new List<String>();
        Integer overdueCount = 0;
        for (Care_Gap__c g : gaps) {
            String due = g.Due_Date__c != null ? 'due ' + g.Due_Date__c.format() : 'no due date';
            String flag = '';
            if (isOverdue(g)) {
                overdueCount++;
                flag = ', OVERDUE by ' + g.Due_Date__c.daysBetween(Date.today()) + ' days';
            } else if (g.Status__c == 'Scheduled') {
                flag = ', appointment scheduled';
            }
            parts.add(g.Gap_Type__c + ' (' + g.Priority__c + ' priority, ' + due + flag + ')');
        }
        String overdueNote = overdueCount > 0 ? ' (' + overdueCount + ' overdue)' : '';
        return 'This patient has ' + gaps.size() + ' open care gap(s)' + overdueNote + ': '
            + String.join(parts, '; ') + '.';
    }
}
