// Seeds demo patients + care gaps with dates relative to today (so "overdue" stays overdue).
// Re-runnable: removes previously seeded demo records first (marked via Contact.Department).
//   sf apex run -o caregap -f scripts/data/seed.apex
String MARKER = 'Care Gap Demo';

List<Contact> old = [SELECT Id FROM Contact WHERE Department = :MARKER];
delete [SELECT Id FROM Care_Gap__c WHERE Patient__c IN :old];
delete old;

Contact maria = new Contact(FirstName = 'Maria', LastName = 'Alvarez', Department = MARKER);
Contact james = new Contact(FirstName = 'James', LastName = 'Okafor',  Department = MARKER);
Contact priya = new Contact(FirstName = 'Priya', LastName = 'Nair',    Department = MARKER);
insert new List<Contact>{ maria, james, priya };

Date today = Date.today();
insert new List<Care_Gap__c>{
    new Care_Gap__c(Patient__c = maria.Id, Gap_Type__c = 'A1C Test',             Status__c = 'Open',      Priority__c = 'High',   Due_Date__c = today.addDays(-26)),
    new Care_Gap__c(Patient__c = maria.Id, Gap_Type__c = 'Mammogram',            Status__c = 'Open',      Priority__c = 'Medium', Due_Date__c = today.addDays(21)),
    new Care_Gap__c(Patient__c = maria.Id, Gap_Type__c = 'Flu Vaccine',          Status__c = 'Closed',    Priority__c = 'Low',    Due_Date__c = today.addDays(-41), Closed_Date__c = today.addDays(-39)),
    new Care_Gap__c(Patient__c = james.Id, Gap_Type__c = 'Colonoscopy',          Status__c = 'Open',      Priority__c = 'High',   Due_Date__c = today.addDays(-70)),
    new Care_Gap__c(Patient__c = james.Id, Gap_Type__c = 'Blood Pressure Check', Status__c = 'Scheduled', Priority__c = 'Medium', Due_Date__c = today.addDays(10)),
    new Care_Gap__c(Patient__c = priya.Id, Gap_Type__c = 'Depression Screening', Status__c = 'Open',      Priority__c = 'Low',    Due_Date__c = today.addDays(66))
};
System.debug('Seeded 3 patients and 6 care gaps.');
