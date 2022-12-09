trigger issueLinkToUserStory on  QCIssue__c (before insert) {
     QCIssue__c issue = Trigger.new[0];
    String idUserStory = [SELECT User_Story__c FROM  Scann__c WHERE Id = :issue.Scan__c].User_Story__c;   
            
        if ( ! String.isBlank(idUserStory)){
            List< QCIssue__c> isuelist = [SELECT Id, User_Story__c FROM  QCIssue__c WHERE User_Story__c = :idUserStory AND  Scan__c != :issue.Scan__c ];
            for( QCIssue__c isue : isuelist )
            {
                isue.User_Story__c = null;
            }
            if(isuelist.size() > 0)
            {
                update isuelist;
            }
        }
        
    for ( QCIssue__c issue2 : Trigger.new) {
        issue2.User_Story__c = idUserStory;
    }

}