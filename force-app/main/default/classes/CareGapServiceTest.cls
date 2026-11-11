@isTest
private class CareGapServiceTest {

    @testSetup
    static void setup() {
        Contact p = TestDataFactory.createPatient('Doe');
        List<Care_Gap__c> gaps = new List<Care_Gap__c>{
            TestDataFactory.buildGap(p.Id, 'A1C Test', 'Open', 'High', Date.today().addDays(-5)),
            TestDataFactory.buildGap(p.Id, 'Mammogram', 'Open', 'Medium', Date.today().addDays(10)),
            TestDataFactory.buildGap(p.Id, 'Flu Vaccine', 'Closed', 'Low', Date.today().addDays(-30))
        };
        insert gaps;
    }

    @isTest
    static void getOpenGaps_returnsOnlyOpen() {
        Contact p = [SELECT Id FROM Contact WHERE LastName = 'Doe' LIMIT 1];
        Test.startTest();
        List<Care_Gap__c> open = CareGapService.getOpenGaps(p.Id);
        Test.stopTest();
        System.assertEquals(2, open.size(), 'Closed gaps should be excluded');
    }

    @isTest
    static void getOpenGaps_nullThrows() {
        try {
            CareGapService.getOpenGaps(null);
            System.assert(false, 'Expected exception');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }

    @isTest
    static void closeGaps_setsStatusAndDate() {
        Contact p = [SELECT Id FROM Contact WHERE LastName = 'Doe' LIMIT 1];
        List<Care_Gap__c> open = CareGapService.getOpenGaps(p.Id);
        Test.startTest();
        CareGapService.closeGaps(open);
        Test.stopTest();
        Integer stillOpen = [SELECT COUNT() FROM Care_Gap__c WHERE Patient__c = :p.Id AND Status__c != 'Closed'];
        System.assertEquals(0, stillOpen, 'All gaps should be closed');
    }

    @isTest
    static void summarize_emptyAndPopulated() {
        System.assertEquals('No open care gaps for this patient.', CareGapService.summarize(new List<Care_Gap__c>()));
        Contact p = [SELECT Id FROM Contact WHERE LastName = 'Doe' LIMIT 1];
        String s = CareGapService.summarize(CareGapService.getOpenGaps(p.Id));
        System.assert(s.contains('open care gap'), 'Summary should mention gaps');
    }

    @isTest
    static void summarize_flagsOverdueButNotUpcomingOrScheduled() {
        Id fakePatient = '003000000000001AAA';
        List<Care_Gap__c> gaps = new List<Care_Gap__c>{
            TestDataFactory.buildGap(fakePatient, 'A1C Test', 'Open', 'High', Date.today().addDays(-30)),
            TestDataFactory.buildGap(fakePatient, 'Mammogram', 'Open', 'Medium', Date.today().addDays(15)),
            TestDataFactory.buildGap(fakePatient, 'Colonoscopy', 'Scheduled', 'Low', Date.today().addDays(-5)),
            TestDataFactory.buildGap(fakePatient, 'Flu Vaccine', 'Open', 'Low', null)
        };
        String s = CareGapService.summarize(gaps);
        System.assert(s.contains('4 open care gap(s) (1 overdue)'), s);
        System.assert(s.contains('A1C Test (High priority, due ' + Date.today().addDays(-30).format() + ', OVERDUE by 30 days)'), s);
        System.assert(s.contains('Mammogram (Medium priority, due ' + Date.today().addDays(15).format() + ')'), s);
        System.assert(!s.contains('Mammogram (Medium priority, due ' + Date.today().addDays(15).format() + ', OVERDUE'), s);
        System.assert(s.contains('Colonoscopy') && s.contains('appointment scheduled'), s);
        System.assert(s.contains('Flu Vaccine (Low priority, no due date)'), s);
    }

    @isTest
    static void summarize_noOverdueOmitsOverdueNote() {
        Id fakePatient = '003000000000001AAA';
        String s = CareGapService.summarize(new List<Care_Gap__c>{
            TestDataFactory.buildGap(fakePatient, 'Mammogram', 'Open', 'Medium', Date.today().addDays(15))
        });
        System.assert(!s.contains('overdue') && !s.contains('OVERDUE'), s);
    }

    private static Care_Gap__c firstOpenGap() {
        return [SELECT Id FROM Care_Gap__c WHERE Gap_Type__c = 'A1C Test' LIMIT 1];
    }

    @isTest
    static void updateGapStatus_marksScheduled() {
        Care_Gap__c g = firstOpenGap();
        Test.startTest();
        CareGapService.updateGapStatus(g.Id, 'Scheduled');
        Test.stopTest();
        Care_Gap__c after = [SELECT Status__c, Closed_Date__c FROM Care_Gap__c WHERE Id = :g.Id];
        System.assertEquals('Scheduled', after.Status__c);
        System.assertEquals(null, after.Closed_Date__c);
    }

    @isTest
    static void updateGapStatus_closesAndStampsDate() {
        Care_Gap__c g = firstOpenGap();
        CareGapService.updateGapStatus(g.Id, 'Closed');
        Care_Gap__c after = [SELECT Status__c, Closed_Date__c FROM Care_Gap__c WHERE Id = :g.Id];
        System.assertEquals('Closed', after.Status__c);
        System.assertEquals(Date.today(), after.Closed_Date__c);
    }

    @isTest
    static void updateGapStatus_rejectsBadInputAndClosedGaps() {
        Care_Gap__c g = firstOpenGap();
        for (List<Object> args : new List<List<Object>>{
            new List<Object>{ null, 'Closed' },
            new List<Object>{ g.Id, 'Open' },
            new List<Object>{ g.Id, null }
        }) {
            try {
                CareGapService.updateGapStatus((Id) args[0], (String) args[1]);
                System.assert(false, 'Expected AuraHandledException');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
        }
        CareGapService.updateGapStatus(g.Id, 'Closed');
        try {
            CareGapService.updateGapStatus(g.Id, 'Scheduled');
            System.assert(false, 'Closed gaps must not be reopened');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }

    @isTest
    static void updateGapStatus_notFoundThrows() {
        Care_Gap__c g = firstOpenGap();
        Id gone = g.Id;
        delete g;
        try {
            CareGapService.updateGapStatus(gone, 'Closed');
            System.assert(false, 'Expected not found');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }

    @isTest
    static void updateGapStatus_deniedWithoutAccess() {
        Care_Gap__c g = firstOpenGap();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'nogap', Email = 'nogap@example.com', Username = 'nogap' + System.currentTimeMillis() + '@example.com',
            LastName = 'NoAccess', ProfileId = p.Id, TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
        insert u;
        System.runAs(u) {
            try {
                CareGapService.updateGapStatus(g.Id, 'Closed');
                System.assert(false, 'User without the permission set must be denied');
            } catch (AuraHandledException e) {
                System.assert(true);
            }
        }
        System.assertEquals('Open', [SELECT Status__c FROM Care_Gap__c WHERE Id = :g.Id].Status__c);
    }
}
