/**** 	Author: Vinesh Shampoor                                  
		Purpose: Update Related Accounts in Banking Org when record is inserted *****/
trigger AccountTrigger on Account (after insert) {
    
    Set<Id> allInsertedIds = trigger.newMap.keySet();
    Set<String> nameweb = new Set<String>();
    
    // Form Bulk Request Body
    String reqbody='{"inputlist":[';
    for(Account q : Trigger.new)
    {
        
        if(nameweb.contains(q.Name+q.Website) || String.isBlank(q.Website)){
            continue;
        }
        reqbody = reqbody + '{"Id":"'+q.NameWebsiteCombination__c+'",';
        reqbody = reqbody + '"Name":"'+q.Name+'",';
        reqbody = reqbody + '"Website":"'+q.Website+'"}';
        
        nameweb.add(q.Name+q.Website);
    } 
    
    reqbody = reqbody+']}';
    
    // Handler Purpose: Making bulk rest call(in future method)
    TriggerHandler.getAccountsList(reqbody, allInsertedIds);
}