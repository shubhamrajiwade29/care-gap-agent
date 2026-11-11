/**
 * Scheduled job: finds open gaps due on/before today, bumps them to High
 * priority, and creates a follow-up Task on each patient. Bulk-safe.
 * Schedule:  System.schedule('Care Gap Reminders','0 0 7 * * ?', new CareGapReminderScheduler());
 */
public with sharing class CareGapReminderScheduler implements Schedulable {

    public void execute(SchedulableContext ctx) {
        List<Care_Gap__c> overdue = new CareGapSelector().selectOpenDueOnOrBefore(Date.today());
        if (overdue.isEmpty()) {
            return;
        }
        List<Task> tasks = new List<Task>();
        for (Care_Gap__c g : overdue) {
            g.Priority__c = 'High';
            tasks.add(new Task(
                WhoId = g.Patient__c,
                Subject = 'Overdue care gap: ' + g.Gap_Type__c,
                Priority = 'High',
                ActivityDate = Date.today(),
                Status = 'Not Started'
            ));
        }
        update overdue;
        insert tasks;
    }
}
