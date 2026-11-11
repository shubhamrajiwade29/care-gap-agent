import { LightningElement, api, wire } from 'lwc';
import getOpenGaps from '@salesforce/apex/CareGapService.getOpenGaps';

const PRIORITY_VARIANT = { High: 'error', Medium: 'warning', Low: 'inverse' };

export default class PatientCareSummary extends LightningElement {
    @api recordId; // Contact (patient) record Id
    gaps = [];
    error;

    @wire(getOpenGaps, { patientId: '$recordId' })
    wiredGaps({ data, error }) {
        if (data) {
            this.gaps = data.map((g) => ({
                id: g.Id,
                type: g.Gap_Type__c,
                priority: g.Priority__c,
                due: g.Due_Date__c,
                variant: PRIORITY_VARIANT[g.Priority__c] || 'inverse'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error?.body?.message || 'Could not load care gaps.';
            this.gaps = [];
        }
    }

    get hasGaps() { return this.gaps.length > 0; }
    get count() { return this.gaps.length; }
}
