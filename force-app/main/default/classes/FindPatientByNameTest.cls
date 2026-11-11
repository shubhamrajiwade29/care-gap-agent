@isTest
private class FindPatientByNameTest {

    private static FindPatientByName.Request req(String name) {
        FindPatientByName.Request r = new FindPatientByName.Request();
        r.patientName = name;
        return r;
    }

    @TestSetup
    static void setup() {
        insert new List<Contact>{
            new Contact(FirstName = 'Maria', LastName = 'Alvarez'),
            new Contact(FirstName = 'Maria', LastName = 'Lopez', Birthdate = Date.newInstance(1980, 1, 2)),
            new Contact(FirstName = 'Maria', LastName = 'Chen', Birthdate = Date.newInstance(1975, 5, 6)),
            new Contact(LastName = 'Okafor')
        };
    }

    @isTest
    static void fullNameResolvesToSingleId() {
        Contact expected = [SELECT Id FROM Contact WHERE LastName = 'Alvarez'];
        List<FindPatientByName.Response> res =
            FindPatientByName.findPatients(new List<FindPatientByName.Request>{ req('maria ALVAREZ') });
        System.assertEquals(1, res[0].matchCount);
        System.assertEquals(expected.Id, res[0].patientId);
    }

    @isTest
    static void lastNameOnlyAndNullFirstName() {
        List<FindPatientByName.Response> res =
            FindPatientByName.findPatients(new List<FindPatientByName.Request>{ req('Okafor') });
        System.assertEquals(1, res[0].matchCount);
        System.assertNotEquals(null, res[0].patientId);
    }

    @isTest
    static void ambiguousNameReturnsCandidatesNotId() {
        List<FindPatientByName.Response> res =
            FindPatientByName.findPatients(new List<FindPatientByName.Request>{ req('Maria') });
        System.assertEquals(3, res[0].matchCount);
        System.assertEquals(null, res[0].patientId, 'No Id when ambiguous');
        System.assert(res[0].message.contains('Ask the user'), res[0].message);
        System.assert(res[0].message.contains('DOB'), 'Includes DOB to disambiguate');
    }

    @isTest
    static void noMatchAndBlankInput() {
        List<FindPatientByName.Response> res = FindPatientByName.findPatients(
            new List<FindPatientByName.Request>{ req('Nobody Here'), req('   '), req(null) });
        System.assertEquals(0, res[0].matchCount);
        System.assertEquals(null, res[0].patientId);
        System.assertEquals('No patient name was provided.', res[1].message);
        System.assertEquals('No patient name was provided.', res[2].message);
    }

    @isTest
    static void bulkUsesSingleQuery() {
        List<FindPatientByName.Request> reqs = new List<FindPatientByName.Request>();
        for (Integer i = 0; i < 200; i++) { reqs.add(req(Math.mod(i, 2) == 0 ? 'Alvarez' : 'Okafor')); }
        Test.startTest();
        List<FindPatientByName.Response> res = FindPatientByName.findPatients(reqs);
        Integer queries = Limits.getQueries();
        Test.stopTest();
        System.assertEquals(200, res.size());
        System.assertEquals(1, queries, '200 requests must use exactly one SOQL query');
        System.assertEquals(1, res[0].matchCount);
    }
}
