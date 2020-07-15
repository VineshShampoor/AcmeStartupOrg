@isTest
public class TriggerHandlerTest {
    
    @isTest static void testTriggerHandler() {
        
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
        
        system.runAs(usr){
            
            // Perform test
            Test.startTest();
            
            String response='[{"lst":[{"attributes":{"type":"Account","url":"/services/data/v48.0/sobjects/Account/0012w00000FbDi0AAF"},"Id":"0012w00000FbDi0AAF","Name":"ind","Website":"ind.com"}],"Id":"ind@@@ind"}]';
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(string.valueOf(response)));
            
            Account testacc1 = new Account(Name = 'ind', Website = 'www.ind.ind');
            insert testacc1;
            
            Account testacc2 = new Account(Name = 'ind', Website = 'www.ind.com');
            insert testacc2;
            
            Account testacc3 = new Account(Name = 'testName', Website = 'testWebsite');
            insert testacc3;
            
            //System.assert( count > 0);
            
            Test.stopTest();
            
            // Assering Here because below is execute after asynchronous future callouts;
            // Assert Related Records are inserted for account1
            Integer count = [Select count() from Related_Account_from_Org1__c where Account__c = :testacc1.Id];
            System.debug('count '+count);
            System.assert( count == 1);
        }
    }
    
}