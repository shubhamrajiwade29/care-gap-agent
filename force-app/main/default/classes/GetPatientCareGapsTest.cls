@isTest
private class GetPatientCareGapsTest {

    @isTest
    static void returnsSummaryForPatient() {
        Contact p = TestDataFactory.createPatient('Smith');
        insert new List<Care_Gap__c>{
            TestDataFactory.buildGap(p.Id, 'A1C Test', 'Open', 'High', Date.today()),
            TestDataFactory.buildGap(p.Id, 'Colonoscopy', 'Open', 'Low', Date.today().addDays(30))
        };
        GetPatientCareGaps.Request req = new GetPatientCareGaps.Request();
        req.patientId = p.Id;

        Test.startTest();
        List<GetPatientCareGaps.Response> res = GetPatientCareGaps.getGaps(new List<GetPatientCareGaps.Request>{ req });
        Test.stopTest();

        System.assertEquals(1, res.size());
        System.assertEquals(2, res[0].openGapCount);
        System.assert(res[0].summary.contains('2 open care gap'), 'Summary should count gaps');
    }

    @isTest
    static void bulkRequestsHandled() {
        List<Contact> patients = new List<Contact>();
        for (Integer i = 0; i < 200; i++) { patients.add(new Contact(LastName = 'P' + i)); }
        insert patients;
        List<GetPatientCareGaps.Request> reqs = new List<GetPatientCareGaps.Request>();
        for (Contact c : patients) {
            GetPatientCareGaps.Request r = new GetPatientCareGaps.Request();
            r.patientId = c.Id; reqs.add(r);
        }
        Test.startTest();
        List<GetPatientCareGaps.Response> res = GetPatientCareGaps.getGaps(reqs);
        Test.stopTest();
        System.assertEquals(200, res.size(), 'Should handle 200 requests');
    }
}
