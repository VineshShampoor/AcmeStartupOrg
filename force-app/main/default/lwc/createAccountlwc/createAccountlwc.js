import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import SITE_FIELD from '@salesforce/schema/Account.Website';
import PHONE_FIELD from '@salesforce/schema/Account.Phone';
import FAX_FIELD from '@salesforce/schema/Account.Fax';

import getAccountsAura from '@salesforce/apex/AcquireBankOrgToken.getAccountsAura';

const columns = [
    {
        label: 'Banking Id', fieldName: 'Id', type: 'text', sortable: "true", initialWidth: 300,
        cellAttributes: { class: { fieldName: 'cssClass' } }
    },
    {
        label: 'Name', fieldName: 'Name', type: 'text', sortable: "true", initialWidth: 300,
        cellAttributes: { class: { fieldName: 'cssClass' } }
    },
    {
        label: 'Website', fieldName: 'Website', type: 'url', sortable: "true", initialWidth: 400,
        cellAttributes: { class: { fieldName: 'cssClass' } }
    },

];

export default class CreateRecord extends NavigationMixin(LightningElement) {


    @track accountId;
    @track name = '';
    site = '';
    phone = '';
    fax = '';

    @track labelcreate = 'Search Banking Org';

    setlabelsearch() {
        this.labelcreate = 'Search Banking Org';
    }

    handleNameChange(event) {
        this.accountId = undefined;
        this.name = event.target.value.trim();
        this.setlabelsearch();

    }
    handleSiteChange(event) {
        this.site = event.target.value.trim();
        this.setlabelsearch();
    }

    handlePhoneChane(event) {
        this.phone = event.target.value.trim();
        this.setlabelsearch();
    }

    handleFaxChange(event) {
        this.fax = event.target.value.trim();
        this.setlabelsearch();
    }

    get showsearchsection() {
        if (this.tableSearchedData.length <= 0) {
            return false;
        }
        return true;
    }

    get shownosec() {
        if (this.tableSearchedData.length <= 0 && this.searchedonce === true) {
            return true;
        }
        return false;
    }



    @track showspinner = false;
    @track searchedonce = false;
    @track navigateid;

    searchrecords() {
        this.showspinner = true;

        const allValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (allValid === false) {
            this.showspinner = false;
            this.navigateid = undefined;
            this.accountId = undefined;
            
            return;
        }

        if (this.labelcreate === 'Create Account' || this.labelcreate === 'Create Account Anyway') {
            this.createAccount();
            return;
        }

        if(this.site.trim() === ''){
            this.searchedonce = true;
            this.labelcreate = 'Create Account';
            this.tableSearchedData = [];
            this.showspinner = false;
            return;
        }

        getAccountsAura({
            name: this.name,
            website: this.site
        })
            .then(result => {

                this.searchedonce = true;

                console.log('res ' + result);

                this.showspinner = false;
                let temp = JSON.parse(JSON.stringify(result));
                this.tableSearchedData = temp.lst;
                this.navigateid = undefined;

                if (this.tableSearchedData.length > 0) {
                    this.labelcreate = 'Create Account Anyway';
                } else {
                    this.labelcreate = 'Create Account';
                }

                this.changePage(1);

                console.log('this.tableSearchedData ' + JSON.stringify(this.tableSearchedData));


            }).catch(error => {
                const tevent = new ShowToastEvent({
                    title: 'Error',
                    variant: 'error',
                    message: 'Error Occured while fetching Articles',
                });
                this.dispatchEvent(tevent);
                this.showspinner = false;
            });

    }



    createAccount() {
        const fields = {};
        fields[NAME_FIELD.fieldApiName] = this.name;
        fields[SITE_FIELD.fieldApiName] = this.site;
        fields[PHONE_FIELD.fieldApiName] = this.phone;
        fields[FAX_FIELD.fieldApiName] = this.fax;
        const recordInput = { apiName: ACCOUNT_OBJECT.objectApiName, fields };

        createRecord(recordInput)
            .then(account => {
                this.accountId = account.id;
                this.navigateid = this.accountId;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Account created',
                        variant: 'success'
                    })
                );

                this.showspinner = false;
            })
        /* .catch(error => {
            const tevent = new ShowToastEvent({
                title: 'Error',
                variant: 'error',
                message: 'Error Occured while fetching Articles',
            });
            this.dispatchEvent(tevent);
            this.showspinner = false;
        }); */
    }


    /**************************DATATABLE */

    @track columns = columns;

    @track tableSearchedData = [];
    @track tabledataui = [];

    @track current_page = 1;
    @track records_per_page = 10;

    @track rowOffset = 0;

    prevPage() {
        if (this.current_page > 1) {
            this.current_page--;
            this.changePage(this.current_page);
        }
    }

    nextPage() {
        if (this.current_page < this.numPages(this.tableSearchedData)) {
            this.current_page++;
            this.changePage(this.current_page);
        }
    }

    changePage(page) {
        // Validate page

        console.log('change page');

        if (page <= 1) {
            this.rowOffset = 0;
        } else {
            this.rowOffset = ((page - 1) * this.records_per_page);
        }

        if (page < 1) page = 1;
        if (page > this.numPages(this.tableSearchedData)) page = this.numPages(this.tableSearchedData);

        this.current_page = page;
        this.tabledataui = this.tableSearchedData.slice((page - 1) * this.records_per_page, page * this.records_per_page);


        console.log('tabledataui wdff');
        console.log('tabledataui ' + JSON.stringify(this.tabledataui));
    }

    numPages(objJson) {
        return Math.ceil(objJson.length / this.records_per_page);
    }


    get isFirstPage() {
        return this.current_page === 1;
    }

    get isLastPage() {
        let flg = false;
        if (this.tableSearchedData !== undefined) {
            console.log('in if of isl');
            let numpage = this.numPages(this.tableSearchedData);
            if (numpage !== 0) {
                flg = (this.current_page === numpage);
            } else {
                flg = true;
            }

        }
        return flg;
    }

    get stringPages() {
        let temp = this.numPages(this.tableSearchedData);
        let retstr = '';
        if (temp === 0) {
            retstr = 'Page 0 of 0'
        } else {
            retstr = 'Page ' + this.current_page + ' of ' + temp;
        }

        return retstr;
    }

    handlePageChange(event) {

        let val = event.target.label;

        if (val === 'First') {
            this.current_page = 1;
            this.changePage(1);
        } else if (val === 'Previous') {
            this.prevPage();
        } else if (val === 'Last') {
            this.current_page = this.numPages(this.tableSearchedData);
            this.changePage(this.numPages(this.tableSearchedData));
        } else if (val === 'Next') {
            this.nextPage();
        }
    }

    //SORT 

    @track sortBy;
    @track sortDirection;

    handleSortdata(event) {
        // field name
        this.sortBy = event.detail.fieldName;

        //console.log('this.s '+this.sortBy);
        let temp = this.sortBy;

        if (temp === 'internalurl') {
            temp = 'Title';
        }

        // sort direction
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.sortData(temp, event.detail.sortDirection);
    }

    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.tableSearchedData));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1 : -1;

        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // set the sorted data to data table data
        this.tableSearchedData = parseData;

        this.changePage(1);

    }

    /**********************************DATATABLE  */

    @track disableattach = true;

    getSelectedName(event) {
        const selectedRowsval = event.detail.selectedRows;
        // Display that fieldName of the selected rows
        /*for (let i = 0; i < selectedRowsval.length; i++){
            alert("You selected: " + selectedRowsval[i].opportunityName);
        }*/

        if (selectedRowsval !== null && selectedRowsval !== undefined) {
            if (selectedRowsval.length > 0) {
                this.disableattach = false;
            } else {
                this.disableattach = true;
            }

        } else {
            this.disableattach = true;
        }
    }

    get blockoptions() {
        return [
            { label: '10', value: '10' },
            { label: '20', value: '20' },
        ];
    }

    @track blockSize = '10';
    handleBlockChange(e) {

        this.blockSize = e.detail.value;

        if (this.blockSize === '10') {
            this.records_per_page = 10;
        } else if (this.blockSize === '20') {
            this.records_per_page = 20;
        }

        this.changePage(1);
    }

    handlePageChange(event) {

        let val = event.target.label;

        if (val === 'First') {
            this.current_page = 1;
            this.changePage(1);
        } else if (val === 'Previous') {
            this.prevPage();
        } else if (val === 'Last') {
            this.current_page = this.numPages(this.tableSearchedData);
            this.changePage(this.numPages(this.tableSearchedData));
        } else if (val === 'Next') {
            this.nextPage();
        }
    }

    handleAccountView(event) {
        // Navigate to contact record page
        /*this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.navigateid,
                objectApiName: 'Account',
                actionName: 'view',
            },
        });*/

        window.open('/lightning/r/Account/' + this.navigateid + '/view', "_blank");
    }

    handlenameclassvalidations(event) {

        let inputValue = event.target.value;
        let nameclass = this.template.querySelector(".nameclass");

        if ( inputValue === undefined || inputValue.trim() === '') {
            nameclass.setCustomValidity("Account Name invalid");
            nameclass.reportValidity();

        } else {
            //reset an error
            nameclass.setCustomValidity('');
            nameclass.reportValidity();

        }
    }
}