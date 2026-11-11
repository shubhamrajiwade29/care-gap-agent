/**
 * Invocable action exposed to Agentforce / Flow. Given a patient Id, returns a
 * natural-language summary and count of that patient's open care gaps so an
 * Agentforce agent can answer "what's open for this patient?".
 */
public with sharing class GetPatientCareGaps {

    public class Request {
        @InvocableVariable(required=true label='Patient Id')
        public Id patientId;
    }

    public class Response {
        @InvocableVariable(label='Summary') public String summary;
        @InvocableVariable(label='Open Gap Count') public Integer openGapCount;
    }

    @InvocableMethod(label='Get Patient Care Gaps' description='Returns a summary and count of open care gaps for a patient.')
    public static List<Response> getGaps(List<Request> requests) {
        List<Response> responses = new List<Response>();
        Set<Id> patientIds = new Set<Id>();
        for (Request req : requests) {
            if (req.patientId != null) {
                patientIds.add(req.patientId);
            }
        }
        Map<Id, List<Care_Gap__c>> gapsByPatient = new CareGapSelector().selectOpenByPatients(patientIds);
        for (Request req : requests) {
            List<Care_Gap__c> gaps = gapsByPatient.containsKey(req.patientId)
                ? gapsByPatient.get(req.patientId) : new List<Care_Gap__c>();
            Response res = new Response();
            res.openGapCount = gaps.size();
            res.summary = CareGapService.summarize(gaps);
            responses.add(res);
        }
        return responses;
    }
}
