global without sharing class TriggerHandler {
    
    // Use Credentials from Custom Setting
    public static Bank_Credentials__c bankcreds = Bank_Credentials__c.getOrgDefaults();
    
    @future(callout=true)
    public static void getAccountsList(String reqbody, Set<Id> allInsertedIds) { 
        
        // List of Related Account Object Records to insert
        List<Related_Account_from_Org1__c> lsttoinsert = new List<Related_Account_from_Org1__c>();
        
        Http http = new Http();
        HttpRequest httpreq = new HttpRequest();
        String accesstoken;
        
        if(!Test.isRunningTest()){
            accesstoken = AcquireBankOrgToken.getAccessToken();
        }else{
            accesstoken = 'test_token';
        }
        System.debug('acc '+accesstoken);
        
        if(String.isEmpty(accesstoken)){
            return;
        }
        
        httpreq.setMethod('POST');
        httpreq.setEndpoint(bankcreds.End_Point__c+'/services/apexrest/searchbulkaccount/');
        
        httpreq.setHeader('Authorization', 'Bearer '+accesstoken);
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('Accept', 'application/json');
        
        System.debug('req '+reqbody);
        
        // form proper json request
        String freq='{"lst":'+reqbody+'}';
        System.debug('freq '+freq);        
        httpreq.setBody(freq);
        
        HttpResponse resp = Http.send(httpreq);
        String jsonbulkresponse = '{"outputlist":'+resp.getBody()+'}';
        
        System.debug('resp '+jsonbulkresponse);
        
        // Parse Response
        listOutput lst = (listOutput)System.JSON.deserialize(jsonbulkresponse, listOutput.class);
        
        // Map ( key = 'Name'+'Website', Value = "List of Accounts from Bank Org" )
        Map<String, List<Account>> mp = new Map<String, List<Account>>();
        
        // Populate map
        for(Output ot:lst.outputlist){
            mp.put(ot.Id, ot.lst);
            System.debug('Id '+ot.Id);
        }
        
        // Get Accounts in org 2 to update Related Accounts from Bank Org
		List<Account> accs = [Select Id, NameWebsiteCombination__c from Account where NameWebsiteCombination__c IN: mp.keySet()]; 
        
        Set<Id> idset = new Set<Id>();
        
        for(Account org1acc:accs){
            idset.add(org1acc.id);
        }
        
        delete [Select Id from Related_Account_from_Org1__c where Account__c in :idset];
            
        Related_Account_from_Org1__c temp;
        for(Account acc:accs){
            String tempstr = acc.NameWebsiteCombination__c.toLowerCase();
            if(mp.containsKey(tempstr) && mp.get(tempstr)!=null ){
                for(Account at: mp.get(acc.NameWebsiteCombination__c)){
                    temp = new Related_Account_from_Org1__c();
                    temp.Account__c = acc.id;
                    
                    temp.Account_Id__c = at.Id;
                    temp.Account_Name__c = at.Name;
                    temp.Account_Website__c = at.Website;
                    lsttoinsert.add(temp);
                }
            }
        }
        
        insert lsttoinsert;
        
    }  
    
    // API Reponse deserialized to below class instance
    global class listOutput{
        global List<Output> outputlist;
    }
    
    // API Response Indivdual Unit
    global class Output{
        global String Id;
        global List<Account> lst;
    }
    
}