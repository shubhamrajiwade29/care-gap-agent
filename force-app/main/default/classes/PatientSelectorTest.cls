@isTest
private class PatientSelectorTest {
    @isTest
    static void emptyOrNullTokensReturnNothingWithoutQuerying() {
        PatientSelector sel = new PatientSelector();
        Integer before = Limits.getQueries();
        System.assert(sel.selectByNameTokens(null).isEmpty());
        System.assert(sel.selectByNameTokens(new Set<String>()).isEmpty());
        System.assertEquals(before, Limits.getQueries(), 'No SOQL for empty input');
    }

    @isTest
    static void matchesFirstOrLastNameCaseInsensitively() {
        insert new Contact(FirstName = 'Priya', LastName = 'Nair');
        System.assertEquals(1, new PatientSelector().selectByNameTokens(new Set<String>{ 'priya' }).size());
        System.assertEquals(1, new PatientSelector().selectByNameTokens(new Set<String>{ 'nair' }).size());
    }
}
