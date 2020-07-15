/***** Vinesh Shampoor *****/
global class AcquireBankOrgToken {
    
    public static Bank_Credentials__c bankcreds = Bank_Credentials__c.getOrgDefaults();
    
    // Acquire Access Token(Used in making api calls) to Banking Org
    public static String getAccessToken(){
        
        Http http = new Http();
        HttpRequest httpreq = new HttpRequest();
        
        String tokentoreturn;
        
        // Use Custom Setting to make code dynamic
        
        System.debug('Bank_Cre '+bankcreds);
        
        String endpoint = bankcreds.End_Point__c+'/services/oauth2/token';
        String reqbody = 'grant_type=password'+
            '&client_id='+bankcreds.Client_Id__c+
            '&client_secret='+bankcreds.Client_Secret__c+
            '&username='+EncodingUtil.urlEncode(bankcreds.User_Name__c, 'UTF-8')+
            '&password='+EncodingUtil.urlEncode(bankcreds.Password__c+bankcreds.Security_Token__c, 'UTF-8');
        
        // Prepare Request
        httpreq.setEndpoint(endpoint);
        httpreq.setMethod('POST');
        httpreq.setBody(reqbody);
        
        // Send the Request
        HttpResponse httpresp = http.send(httpReq);
        
        System.debug('body '+reqbody);
        
        // Parse JSON response
        // 
        System.debug('test ' +(httpresp.getBody()));
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(httpresp.getBody());
        
        return (String)responseMap.get('access_token');
        
    }
    
    @AuraEnabled
    public static RelatedAccountList getAccountsAura(String name, String website){
        
        Http http = new Http();
        HttpRequest httpreq = new HttpRequest();
        
        String accesstoken;
        if(!Test.isRunningTest()){
            accesstoken = getAccessToken();
        }else{
            accesstoken = 'test_token';
        }
        
        
        System.debug('acc '+accesstoken);
        
        if(String.isEmpty(accesstoken)){
            return null;
        }
        
        httpreq.setMethod('POST');
        httpreq.setEndpoint(bankcreds.End_Point__c+'/services/apexrest/searchaccount/');
        
        httpreq.setHeader('Authorization', 'Bearer '+accesstoken);
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('Accept', 'application/json');
        //httpReq.setHeader('Content-Length', '0');
        
        
        String websitestring = website;
        websitestring = websitestring.replace('http://','').replace('https://','').replace('www.','').split('/[/?#]/')[0].split('\\.')[0];
        
        
        
        String body = '{"name": "'+name+'", "domain": "'+websitestring+'"}';
        httpreq.setBody(body);
        
        HttpResponse resp = Http.send(httpreq);
        
        System.debug('res '+resp.getBody());
        String jsonresponse = '{"lst":'+resp.getBody()+'}';
        
        RelatedAccountList lst = (RelatedAccountList)System.JSON.deserialize(jsonresponse, RelatedAccountList.class);
        System.debug('Respone- ' + lst);
        
        return lst;
        
    }
    
    global class RelatedAccount{
        @AuraEnabled
        global string Id{get; set;}
        @AuraEnabled
        global string Name{get; set;}
        @AuraEnabled
        global string Website{get; set;}
    } 
    
    global class RelatedAccountList{
        @AuraEnabled
        global List<RelatedAccount> lst;
    }
    
    @AuraEnabled
    public static List<Related_Account_from_Org1__c>  getRelatedAccounts(String accId){
        return [Select Id, Account_Id__c, Account_Name__c, Account_Website__c from Related_Account_from_Org1__c where Account__c=:accId];
    }
    
    @AuraEnabled
    public static void refreshRelatedAccounts(String name, String website, String nameWebsiteCombo){
        String reqbody='{"inputlist":[';
        
        Set<String> nameweb = new Set<String>();
        
        Set<Id> allInsertedIds = new Set<Id>();
        
        reqbody = reqbody + '{"Id":"'+nameWebsiteCombo.toLowerCase()+'",';
        reqbody = reqbody + '"Name":"'+name+'",';
        reqbody = reqbody + '"Website":"'+website+'"}';
        
        reqbody = reqbody+']}';
        
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
        
        // Prepare Request
        httpreq.setMethod('POST');
        httpreq.setEndpoint(bankcreds.End_Point__c+'/services/apexrest/searchbulkaccount/');
        httpreq.setHeader('Authorization', 'Bearer '+accesstoken);
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('Accept', 'application/json');
        
        System.debug('req '+reqbody);
        String freq='{"lst":'+reqbody+'}';
        System.debug('freq '+freq);
        httpreq.setBody(freq);
        HttpResponse resp = Http.send(httpreq);
        String jsonbulkresponse = '{"outputlist":'+resp.getBody()+'}';
        
        System.debug('resp '+jsonbulkresponse);
        
        // Parse Response
        listOutput lst = (listOutput)System.JSON.deserialize(jsonbulkresponse, listOutput.class);
        
        Map<String, List<Account>> mp = new Map<String, List<Account>>();
        List<Related_Account_from_Org1__c> lsttoinsert = new List<Related_Account_from_Org1__c>();
        
        
        for(Output ot:lst.outputlist){
            mp.put(ot.Id, ot.lst);
        }
        
        List<Account> accs = [Select Id, NameWebsiteCombination__c from Account where NameWebsiteCombination__c IN: mp.keySet()]; 
        
        Set<Id> idset = new Set<Id>();
        
        for(Account org1acc:accs){
            idset.add(org1acc.id);
        }
        
        delete [Select Id from Related_Account_from_Org1__c where Account__c in :idset];
        
        Related_Account_from_Org1__c temp;
        
        if(!String.isBlank(website)){
            for(Account acc:accs){
                String tempstr = acc.NameWebsiteCombination__c.toLowerCase();
                if(mp.containsKey(tempstr) && mp.get(tempstr)!=null ){
                    for(Account at: mp.get(tempstr)){
                        temp = new Related_Account_from_Org1__c();
                        temp.Account__c = acc.id;
                        
                        temp.Account_Id__c = at.Id;
                        temp.Account_Name__c = at.Name;
                        temp.Account_Website__c = at.Website;
                        lsttoinsert.add(temp);
                    }
                }
            }
        }
        
        insert lsttoinsert;
    }
    
    global class listOutput{
        global List<Output> outputlist;
    }
    
    global class Output{
        global String Id;
        global List<Account> lst;
    }
}