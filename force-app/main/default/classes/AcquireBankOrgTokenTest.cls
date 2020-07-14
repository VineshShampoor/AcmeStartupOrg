@isTest
public class AcquireBankOrgTokenTest {
    
     @testSetup static void setup() {
        Bank_Credentials__c setting = new Bank_Credentials__c();
        setting.User_Name__c = 'testuname';
        setting.Password__c = 'testpwd';
        Setting.Security_Token__c = 'testToken';
        insert setting;  
        
        Profile pr=[SELECT id FROM Profile WHERE name='System Administrator'];
        User usr = new User(alias = 'usr',
                            email='us.name@vmail.com',
                            emailencodingkey='UTF-8',
                            firstname='firstname',
                            lastname='lstname',
                            timezonesidkey='America/Los_Angeles',
                            languagelocalekey='en_US',
                            localesidkey='en_US',
                            ProfileId = pr.Id,
                            //UserRoleId=Urole.Id,
                            username='nikeel@testorg.com',
                            Department='CS-testuser');
        
        insert usr;      
    }
    
    @isTest static void testFetchToken() {
        
        User usr = [SELECT Id FROM User WHERE firstname='firstname' LIMIT 1];
        
        system.runAs(usr){
            
            // Perform test
            Test.startTest();
            
            String response='{ "@odata.context": "https://graph.microsoft.com/beta/$metadata#teams(\'123456-1234-1234-1234-123456789123\')/channels(\'19%123456789012345678901236%40thread.skype\')/messages/$entity", "id": "id-value", "replyToId": null, "etag": "id-value", "messageType": "message", "createdDateTime": "2019-02-04T19:58:15.511Z", "lastModifiedDateTime": null, "deleted": false, "subject": null, "summary": null, "importance": "normal", "locale": "en-us", "policyViolation": null, "from": { "application": null, "device": null, "conversation": null, "user": { "id": "id-value", "displayName": "Joh Doe", "userIdentityType": "aadUser" } }, "body": { "contentType": "html", "content": "Hello World" }, "attachments": [], "mentions": [], "reactions": [] }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(string.valueOf(response)));
            AcquireBankOrgToken.getAccessToken();
            
            Test.stopTest();
        }
    }
    
    
    @isTest static void testFetchAccounts() {
        
        User usr = [SELECT Id FROM User WHERE firstname='firstname' LIMIT 1];
        
        system.runAs(usr){
            
            // Perform test
            Test.startTest(); 
            
            String response='[{"attributes":{"type":"Account","url":"/services/data/v48.0/sobjects/Account/0012w00000FbDi0AAF"},"Id":"0012w00000FbDi0AAF","Name":"ind","Website":"ind.com"}]';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(string.valueOf(response)));
            AcquireBankOrgToken.getAccountsAura('testname','testwebsite');
            
            Test.stopTest();
        }
    }
    
    @isTest static void testFetchRelatedAccounts() {
        
        User usr = [SELECT Id FROM User WHERE firstname='firstname' LIMIT 1];
        
        system.runAs(usr){
            
            // Perform test
            Test.startTest(); 
            
            AcquireBankOrgToken.getRelatedAccounts('invalid_id');
            String response='[{"lst":[{"attributes":{"type":"Account","url":"/services/data/v48.0/sobjects/Account/0012w00000FbDi0AAF"},"Id":"0012w00000FbDi0AAF","Name":"ind","Website":"ind.com"}],"Id":"indind"}]';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(string.valueOf(response)));
            
            AcquireBankOrgToken.refreshRelatedAccounts('testname', 'testwebsite');
            
            Test.stopTest();
        }
    }
}