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

    /** Plain-English summary of a patient's open gaps (used by Agentforce). */
    public static String summarize(List<Care_Gap__c> gaps) {
        if (gaps == null || gaps.isEmpty()) {
            return 'No open care gaps for this patient.';
        }
        List<String> parts = new List<String>();
        for (Care_Gap__c g : gaps) {
            String due = g.Due_Date__c != null ? g.Due_Date__c.format() : 'no due date';
            parts.add(g.Gap_Type__c + ' (' + g.Priority__c + ' priority, due ' + due + ')');
        }
        return 'This patient has ' + gaps.size() + ' open care gap(s): '
            + String.join(parts, '; ') + '.';
    }
}
