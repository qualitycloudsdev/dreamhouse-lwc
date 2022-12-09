trigger updateUserstoryCount on  QCIssue__c (after update) {
     QCIssue__c issue = Trigger.new[0];
        if (issue.User_Story__c != null){
            copado__User_Story__c userStory = [SELECT Id, QC_Issue_Count__c FROM copado__User_Story__c WHERE Id = :issue.User_Story__c];
            userStory.QC_Issue_Count__c = [SELECT Count() FROM  QCIssue__c WHERE User_Story__c = :issue.User_Story__c AND  Write_off__c = false];
            update userStory;
        }
}