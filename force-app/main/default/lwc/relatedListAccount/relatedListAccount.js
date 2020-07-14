import { LightningElement, api, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import getRelatedAccounts from '@salesforce/apex/AcquireBankOrgToken.getRelatedAccounts';
import refreshRelatedAccounts from '@salesforce/apex/AcquireBankOrgToken.refreshRelatedAccounts';
import { getRecord } from "lightning/uiRecordApi";

const FIELDS = ['Account.Id', 'Account.Name', 'Account.Website'];

const columns = [
   
    {
        label: 'Record Id',
        //initialWidth: 1000,
        fieldName: 'urlid',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Id' },
            target: '_blank'
        },
        sortable: "true",
        cellAttributes: { class: { fieldName: 'cssClass' } },
        wrapText: true
    },
    {
        label: "Bank Org Id",
        fieldName: "Account_Id__c",
        type: "text",
        //typeAttributes: { label: { fieldName: "Title" } }
    },
    {
        label: "Name",
        fieldName: "Account_Name__c",
        type: "text",
        cellAttributes: { alignment: "left", class: "slds-border_left" }
    },
    {
        label: "Website",
        fieldName: "Account_Website__c",
        type: "text",
        cellAttributes: { alignment: "left", class: "slds-border_left" }
    }
];


export default class RelatedListAccount extends NavigationMixin(
    LightningElement
) {
    @api recordId;
    @api Style;
    @track accounts;
    @track columns = columns;


    @track relatedcount = 0;

    @track accountRecord;

    @track showspinner = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (error) {

        } else if (data) {
            this.accountRecord = data;
            console.log('this.caserecthis.caserec ' + JSON.stringify(this.accountRecord));
        }
    }

    connectedCallback() {
        this.fetchRelatedAccounts();
    }

    refreshAction() {

        console.log('This.accountRecord.Name.value ' + this.accountRecord.fields.Name.value + '@@ ' + this.accountRecord.fields.Website.value);


        this.showspinner = true;
        refreshRelatedAccounts({ name: this.accountRecord.fields.Name.value, website: this.accountRecord.fields.Website.value })
            .then((result) => {

                //this.accounts = JSON.parse(JSON.stringify(result));
                this.fetchRelatedAccounts();
                this.showspinner = false;
                console.log("Result" + JSON.stringify(result) + '\nthis.showspinner ' + this.showspinner);
            })
        /* .catch((error) => {
            window.console.log("error " + JSON.stringify(error));
            // this.error = error.body.message;
            this.showspinner = false;
        });
*/
    }

    fetchRelatedAccounts() {
        this.showspinner = true;
        getRelatedAccounts({ accId: this.recordId })
            .then(result => {
                window.console.log("fetch " + JSON.stringify(result));
                this.accounts = JSON.parse(JSON.stringify(result));

                for(let i=0;i<this.accounts.length;i++){
                    this.accounts[i].urlid='/lightning/r/Account/'+this.accounts[i].Id+'/view';

                }
                this.relatedcount = this.accounts.length;

                this.showspinner = false;
            })
            .catch(error => {
                window.console.log("error " + JSON.stringify(error));
                // this.error = error.body.message;
                this.showspinner = false;
            });
    }
}