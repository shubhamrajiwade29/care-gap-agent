/**
 * Selector layer for Care_Gap__c. Centralizes SOQL and enforces FLS/CRUD.
 */
public with sharing class CareGapSelector {

    public List<Care_Gap__c> selectOpenByPatient(Id patientId) {
        return [
            SELECT Id, Name, Gap_Type__c, Status__c, Priority__c, Due_Date__c,
                   Patient__c, Patient__r.Name
            FROM Care_Gap__c
            WHERE Patient__c = :patientId AND Status__c != 'Closed'
            WITH SECURITY_ENFORCED
            ORDER BY Due_Date__c ASC NULLS LAST
        ];
    }

    public Map<Id, List<Care_Gap__c>> selectOpenByPatients(Set<Id> patientIds) {
        Map<Id, List<Care_Gap__c>> byPatient = new Map<Id, List<Care_Gap__c>>();
        for (Id pid : patientIds) {
            byPatient.put(pid, new List<Care_Gap__c>());
        }
        for (Care_Gap__c g : [
            SELECT Id, Name, Gap_Type__c, Status__c, Priority__c, Due_Date__c,
                   Patient__c, Patient__r.Name
            FROM Care_Gap__c
            WHERE Patient__c IN :patientIds AND Status__c != 'Closed'
            WITH SECURITY_ENFORCED
            ORDER BY Due_Date__c ASC NULLS LAST
        ]) {
            byPatient.get(g.Patient__c).add(g);
        }
        return byPatient;
    }

    public List<Care_Gap__c> selectOpenDueOnOrBefore(Date cutoff) {
        return [
            SELECT Id, Gap_Type__c, Status__c, Priority__c, Due_Date__c, Patient__c
            FROM Care_Gap__c
            WHERE Status__c = 'Open' AND Due_Date__c <= :cutoff
            WITH SECURITY_ENFORCED
        ];
    }
}
