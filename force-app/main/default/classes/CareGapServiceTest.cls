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
}
