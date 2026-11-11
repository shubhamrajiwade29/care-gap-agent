import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpenGaps from '@salesforce/apex/CareGapService.getOpenGaps';
import updateGapStatus from '@salesforce/apex/CareGapService.updateGapStatus';

const PRIORITY_VARIANT = { High: 'error', Medium: 'warning', Low: 'inverse' };

export default class PatientCareSummary extends LightningElement {
    @api recordId; // Contact (patient) record Id
    gaps = [];
    error;
    saving = false;
    wiredResult;

    @wire(getOpenGaps, { patientId: '$recordId' })
    wiredGaps(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.gaps = data.map((g) => ({
                id: g.Id,
                type: g.Gap_Type__c,
                status: g.Status__c,
                priority: g.Priority__c,
                due: g.Due_Date__c,
                isScheduled: g.Status__c === 'Scheduled',
                variant: PRIORITY_VARIANT[g.Priority__c] || 'inverse'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error?.body?.message || 'Could not load care gaps.';
            this.gaps = [];
        }
    }

    handleAction(event) {
        const gapId = event.currentTarget.dataset.id;
        const newStatus = event.detail.value; // 'Scheduled' | 'Closed'
        this.saving = true;
        updateGapStatus({ gapId, newStatus })
            .then(() => {
                this.toast('Care gap updated', `Marked ${newStatus.toLowerCase()}.`, 'success');
                return refreshApex(this.wiredResult);
            })
            .catch((e) => {
                this.toast('Could not update care gap', e?.body?.message || 'Unexpected error.', 'error');
            })
            .finally(() => {
                this.saving = false;
            });
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get hasGaps() { return this.gaps.length > 0; }
    get count() { return this.gaps.length; }
}
