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
         
         String response='[{"lst":[{"attributes":{"type":"Account","url":"/services/data/v48.0/sobjects/Account/0012w00000FbDi0AAF"},"Id":"0012w00000FbDi0AAF","Name":"ind","Website":"ind.com"}],"Id":"ind@@@ind"}]';
         Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(string.valueOf(response)));
         
         Account testacc1 = new Account(Name = 'ind', Website = 'www.ind.ind');
         insert testacc1;
         
    }
    
    @isTest static void testFetchToken() {
        
        User usr = [SELECT Id FROM User WHERE firstname='firstname' LIMIT 1];
        
        system.runAs(usr){
            
            // Perform test
            Test.startTest();
            
            String response='{ "access_token": "test_token" }';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(string.valueOf(response)));
            String token = AcquireBankOrgToken.getAccessToken();
            
            //Assert: check if above token is parsed successfully
            System.assert(token == 'test_token');
            
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
            AcquireBankOrgToken.RelatedAccountList rellist = AcquireBankOrgToken.getAccountsAura('testname','testwebsite');
            
            // check if number of results = 1, as per above mock response
            System.assert(rellist.lst.size() == 1);
            
            Test.stopTest();
        }
    }
    
    @isTest static void testFetchRelatedAccounts() {
        
        User usr = [SELECT Id FROM User WHERE firstname='firstname' LIMIT 1];
        
        system.runAs(usr){
            
            // Perform test
            Test.startTest(); 
            
            AcquireBankOrgToken.getRelatedAccounts('invalid_id');
            String response='[{"lst":[{"attributes":{"type":"Account","url":"/services/data/v48.0/sobjects/Account/0012w00000FbDi0AAF"},"Id":"0012w00000FbDi0AAF","Name":"ind","Website":"ind.com"}],"Id":"ind@@@ind"}]';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(string.valueOf(response)));
            
            AcquireBankOrgToken.refreshRelatedAccounts('testname', 'testwebsite', 'testcombo');
            
            Integer count = [Select count() from Related_Account_from_Org1__c where Account_Website__c = 'ind.com'];
            System.debug('count '+count);
            System.assert( count == 1);
            
            Test.stopTest();
            
            
        }
    }
}