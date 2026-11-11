@isTest
public class TestDataFactory {
    public static Contact createPatient(String lastName) {
        Contact c = new Contact(LastName = lastName);
        insert c;
        return c;
    }
    public static Care_Gap__c buildGap(Id patientId, String type, String status, String priority, Date due) {
        return new Care_Gap__c(
            Patient__c = patientId, Gap_Type__c = type,
            Status__c = status, Priority__c = priority, Due_Date__c = due
        );
    }
}
