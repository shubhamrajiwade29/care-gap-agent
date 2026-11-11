/**
 * Invocable action: resolves a patient name (e.g. "Maria Alvarez", "Alvarez") to a Contact Id
 * so an Agentforce agent / Flow can pass it to Get Patient Care Gaps.
 * Bulk-safe: a single SOQL query regardless of the number of requests.
 */
public with sharing class FindPatientByName {

    public class Request {
        @InvocableVariable(label='Patient Name' description='Full or partial patient name, e.g. "Maria Alvarez" or "Alvarez".' required=true)
        public String patientName;
    }

    public class Response {
        @InvocableVariable(label='Patient Id' description='Contact Id. Only set when exactly one patient matched.')
        public Id patientId;
        @InvocableVariable(label='Match Count' description='Number of patients matching the name.')
        public Integer matchCount;
        @InvocableVariable(label='Message' description='Human-readable result; lists candidates when the name is ambiguous.')
        public String message;
    }

    @InvocableMethod(label='Find Patient By Name' description='Finds a patient (Contact) by first and/or last name and returns the Contact Id.')
    public static List<Response> findPatients(List<Request> requests) {
        Map<Integer, Set<String>> tokensByIndex = new Map<Integer, Set<String>>();
        Set<String> allTokens = new Set<String>();
        for (Integer i = 0; i < requests.size(); i++) {
            Set<String> tokens = tokenize(requests[i].patientName);
            tokensByIndex.put(i, tokens);
            allTokens.addAll(tokens);
        }

        List<Contact> candidates = new PatientSelector().selectByNameTokens(allTokens);

        List<Response> responses = new List<Response>();
        for (Integer i = 0; i < requests.size(); i++) {
            responses.add(buildResponse(tokensByIndex.get(i), candidates));
        }
        return responses;
    }

    private static Response buildResponse(Set<String> tokens, List<Contact> candidates) {
        Response res = new Response();
        List<Contact> matches = new List<Contact>();
        if (!tokens.isEmpty()) {
            for (Contact c : candidates) {
                if (matchesAll(c, tokens)) {
                    matches.add(c);
                }
            }
        }
        res.matchCount = matches.size();
        if (tokens.isEmpty()) {
            res.message = 'No patient name was provided.';
        } else if (matches.isEmpty()) {
            res.message = 'No patient found matching that name.';
        } else if (matches.size() == 1) {
            res.patientId = matches[0].Id;
            res.message = 'Found patient ' + matches[0].Name + '.';
        } else {
            List<String> labels = new List<String>();
            for (Contact c : matches) {
                labels.add(c.Name + (c.Birthdate != null ? ' (DOB ' + c.Birthdate.format() + ')' : ''));
            }
            res.message = matches.size() + ' patients match: ' + String.join(labels, '; ')
                + '. Ask the user which one they mean.';
        }
        return res;
    }

    /** Every search word must equal the contact's first or last name (case-insensitive). */
    private static Boolean matchesAll(Contact c, Set<String> tokens) {
        String first = c.FirstName == null ? '' : c.FirstName.toLowerCase();
        String last = c.LastName == null ? '' : c.LastName.toLowerCase();
        for (String t : tokens) {
            if (t != first && t != last) {
                return false;
            }
        }
        return true;
    }

    private static Set<String> tokenize(String name) {
        Set<String> tokens = new Set<String>();
        if (String.isBlank(name)) {
            return tokens;
        }
        for (String part : name.trim().toLowerCase().split('\\s+')) {
            if (String.isNotBlank(part)) {
                tokens.add(part);
            }
        }
        return tokens;
    }
}
