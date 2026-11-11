/**
 * Selector layer for patient (Contact) lookups. Enforces CRUD/FLS.
 */
public with sharing class PatientSelector {

    /** One query for any number of search terms; callers filter in memory. */
    public List<Contact> selectByNameTokens(Set<String> tokens) {
        if (tokens == null || tokens.isEmpty()) {
            return new List<Contact>();
        }
        return [
            SELECT Id, FirstName, LastName, Name, Birthdate
            FROM Contact
            WHERE FirstName IN :tokens OR LastName IN :tokens
            WITH SECURITY_ENFORCED
            ORDER BY LastName, FirstName
            LIMIT 2000
        ];
    }
}
