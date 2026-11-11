@isTest
private class CareGapReminderSchedulerTest {

    @isTest
    static void overdueGapsFlaggedAndTasksCreated() {
        Contact p = TestDataFactory.createPatient('Overdue');
        insert new List<Care_Gap__c>{
            TestDataFactory.buildGap(p.Id, 'A1C Test', 'Open', 'Medium', Date.today().addDays(-1)),
            TestDataFactory.buildGap(p.Id, 'Mammogram', 'Open', 'Low', Date.today().addDays(5))
        };

        Test.startTest();
        new CareGapReminderScheduler().execute(null);
        Test.stopTest();

        Integer high = [SELECT COUNT() FROM Care_Gap__c WHERE Patient__c = :p.Id AND Priority__c = 'High'];
        System.assertEquals(1, high, 'Only the overdue gap should be High');
        Integer tasks = [SELECT COUNT() FROM Task WHERE WhoId = :p.Id];
        System.assertEquals(1, tasks, 'One follow-up task for the overdue gap');
    }
}
