@isTest
class  globalCallsToQCTest {
       
    @isTest
    static void execute_scannOK() {

        upsert new Instance__c(url__c='url', Description__c='dec', Environment_Type__c='dev',ID__c= '1', Instance_Type__c='salesforcce', Is_Featured_Banch__c=true) ID__c;

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('scanok');
        mock.setStatusCode(202);
        mock.setHeader('Content-Type', 'application/json');

        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        globalCallsToQC globalCallsToQCObj = new globalCallsToQC();

        boolean testout = globalCallsToQCObj.execute_scann([SELECT url__c, Description__c, ID__c, Environment_Type__c, Instance_Type__c, Is_Featured_Banch__c, Id FROM Instance__c WHERE ID__c = '1' ORDER BY CreatedDate DESC LIMIT 1], 'develop');

        Test.stopTest();
        System.assertEquals(testout, true);
    }

}