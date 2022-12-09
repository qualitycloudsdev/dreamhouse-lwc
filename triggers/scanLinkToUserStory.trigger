trigger scanLinkToUserStory on  Scann__c (before update) {   
    for ( Scann__c scan : Trigger.new) {
        if (scan.Scan_Type__c == 'feature-branch-scan' && [SELECT Count() FROM  Scann__c WHERE  Instance__c = :scan.Instance__c AND  Branch_Name__c = :scan.Branch_Name__c AND  Date__c > :scan.Date__c ] == 0 ){
            String idUserStory = null;
            copado__User_Story__c userStoryToUpdate;
            Map<String, copado__User_Story__c> repoURLToUserStoryMap = new Map<String, copado__User_Story__c>();
            String branch = scan.Branch_Name__c.substringAfter('/');
            for (copado__User_Story__c userStory : [SELECT Id, copado__Project__r.copado__Deployment_Flow__r.copado__Git_Repository__r.copado__URI__c , QC_Issue_Count__c FROM copado__User_Story__c WHERE Name = :branch]) { 

                String repoURL = userStory.copado__Project__r.copado__Deployment_Flow__r.copado__Git_Repository__r.copado__URI__c;

                repoURLToUserStoryMap.put(repoURL.substringAfterLast('/'), userStory);
            }

             Instance__c inst = [SELECT Id,  url__c FROM  Instance__c WHERE Id =: scan.Instance__c LIMIT 1];
            for (String repoURL: repoURLToUserStoryMap.keySet()){
                if (inst.url__c.containsIgnoreCase(repoURL)){
                    userStoryToUpdate = repoURLToUserStoryMap.get(repoURL);
                    idUserStory = repoURLToUserStoryMap.get(repoURL).Id;
                }
            }

            if ( ! String.isBlank(idUserStory)){
                List< Scann__c> scanlist = [SELECT Id, User_Story__c FROM  Scann__c WHERE User_Story__c = :idUserStory AND Id != :scan.Id];
                for( Scann__c scanl : scanlist ) {
                    scanl.User_Story__c = null;
                }
                if(scanlist.size() > 0) {
                    update scanlist;
                }
                if (scan.State__c != 'SUCCESS' || Test.isRunningTest() ){                
                    List< QCIssue__c> isuelist = [SELECT Id, User_Story__c FROM  QCIssue__c WHERE User_Story__c = :idUserStory];
                    for( QCIssue__c isue : isuelist ) {
                        isue.User_Story__c = null;
                    }
                    if(isuelist.size() > 0) {
                        update isuelist;
                    }
                
                }
            }
            scan.User_Story__c = idUserStory;
            
            if (scan.State__c == 'SUCCESS' && userStoryToUpdate != null  ) {
                userStoryToUpdate.QC_Issue_Count__c = scan.Total_Issues__c;

                if (scan.Quality_Gate_Result__c != null){
                    userStoryToUpdate.Quality_Gates_Result__c = scan.Quality_Gate_Result__c;
                    inst.Quality_Gates__c = true;
                } else {
                    userStoryToUpdate.Quality_Gates_Result__c = 'N/A';
                    inst.Quality_Gates__c = false;
                }
                update userStoryToUpdate;
                update inst;
            }

        }
    }

}