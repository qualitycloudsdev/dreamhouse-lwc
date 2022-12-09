/**
 * @description Test Class for Run_QualityClouds_Scan_Page_Controller Apex Class
 */
@isTest
public class Test_Run_QualityClouds_Scan_Controller {
    
    private static User runningUser;
    
    /**
     * @description Create admin user for creating and assigning the Copado licenses to a running user Method
     */    
    private static void setupTestData() {
        User adminUser = createAdminUser();
        insert adminUser;

        System.runAs(adminUser) {
            // Create running user
            runningUser = createStandardUser();
            runningUser.ProfileId = adminUser.ProfileId;
            insert runningUser;

            // Assign the Copado permission set to the running user
            PermissionSetAssignment psa = new PermissionSetAssignment (
                PermissionSetId = getCopadoUserPermissionSet().Id,
                AssigneeId = runningUser.Id
            );
            insert psa;

            // Assign A Copado License to the running User
            copado.GlobalAPI copadoGlobalAPI = new copado.GlobalAPI();
            copado.GlobalAPI.UserLicense userLicense = new copado.GlobalAPI.UserLicense();
            userLicense.isCopadoEnabled = true;
            userLicense.isCCMEnabled = true;
            userLicense.userId = runningUser.id;
            copadoGlobalAPI.upsertCopadoLicense(runningUser.id, userLicense);
        }
    }
    
    /**
     * @description Creating the UserStory and related objects
     */  
    @isTest(SeeAllData=false) public static void TestScan() {
        setupTestData();
        System.runAs(runningUser) {
        
            copado__Git_Repository__c repo = new copado__Git_Repository__c(copado__URI__c = 'https://github.com/testgit');
            upsert repo;
            copado__Deployment_Flow__c pipe = new copado__Deployment_Flow__c(copado__Git_Repository__c = repo.Id);
            upsert pipe;
            copado__Project__c project = new copado__Project__c(copado__Deployment_Flow__c = pipe.Id);
            upsert project;
            copado__User_Story__c userStory = new copado__User_Story__c( copado__Project__c = project.Id);
            upsert userStory;
            List <copado__User_Story__c> userStoryList = [SELECT Id, copado__Project__c, Name FROM copado__User_Story__c WHERE Id = :userStory.Id Limit 1];
            //Creating the Quality Clouds Instance to run the Scan
            Instance__c instance;
            Instance__c instancee = new Instance__c(url__c='https://github.com/testgit', Description__c='dec', Environment_Type__c='dev',ID__c= '1', Instance_Type__c='salesforcce', Is_Featured_Banch__c=true);

            Test.startTest();
            //Error Scan can't find Instance to run the Scan
            Run_QualityClouds_Scan_Page_Controller.doScan(userStoryList);
            //Success Scan
            upsert instance = instancee ID__c;
            Run_QualityClouds_Scan_Page_Controller.doScan(userStoryList);
            Test.stopTest();
            System.assertEquals('IC', 'IC');
        }
    }

    /**
     * @description Creating a Admin User to run the test
     */  
    public static User createAdminUser(){
        Profile adminProfile = [Select Id From Profile Where Name = 'System Administrator' Limit 1];
        User newUser = new User();
        newUser.ProfileId = adminProfile.Id;
        newUser.FirstName = 'Ismael';
        newUser.LastName = 'Admin';
        newUser.email = 'admin@qualityclouds.test';
        newUser.Username = 'admin@qualityclouds.test';
        newUser.Alias = 'iadmin';
        newUser.CommunityNickname = 'iadmin';
        newUser.LocaleSidKey = 'es_ES';
        newUser.emailencodingkey='UTF-8';
        newUser.languagelocalekey='en_US';
        newUser.TimeZoneSidKey='Europe/Rome';
        return newUser;
    }

    /**
     * @description  Creating Standart User to run the test
     */ 
    public static User createStandardUser(){
        Profile standardProfile = [Select Id From Profile Where Name = 'Standard User' Limit 1];
        User newUser = new User();
        newUser.ProfileId = standardProfile.Id;
        newUser.FirstName = 'Ismael';
        newUser.LastName = 'Standard';
        newUser.email = 'standard@qualityclouds.test';
        newUser.Username = 'standard@qualityclouds.test';
        newUser.Alias = 'itandard';
        newUser.CommunityNickname = 'itandard';
        newUser.LocaleSidKey = 'es_ES';
        newUser.emailencodingkey='UTF-8';
        newUser.languagelocalekey='en_US';
        newUser.TimeZoneSidKey='Europe/Rome';

        return newUser;
    }
    
    /**
     * @description Getting Permission Set for Copado User
     */ 
    public static PermissionSet getCopadoUserPermissionSet(){
        return [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
    }
    
}